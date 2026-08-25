%% mobility_cdL_1x2_MIMO_v2.m
% 1x2 MIMO using 5G Toolbox CDL channel (carrier 3.5 GHz)
% Realistic CDL channel (CDL-D) + Doppler + Monte Carlo + HO/RLF
% Requires: 5G Toolbox

clear; close all; clc;

%% ---------------- Simulation params ----------------
c = physconst('LightSpeed');
fc = 3.5e9;                % carrier 3.5 GHz
lambda = c/fc;
BW = 10e6;                 % Hz
kB = 1.38064852e-23; T0 = 290;
NF_dB = 7;
noise_power_dBm = 10*log10(kB*T0*BW) + 30 + NF_dB;

% speeds
speeds_mph = [30,90,150];
mph2ms = 0.44704;
speeds = speeds_mph * mph2ms;

% time
t_end = 10;                % seconds (reduce if slow)
dt = 0.01;
t_vec = 0:dt:t_end;
N_t = numel(t_vec);
fs = 1/dt;

% RLF/HO
RLF_sinr_threshold_dB = 10;  % tune as needed
RLF_timeout = 0.2;           % sec
HO_delay = 0.05;             % sec (throughput zero window)
RLF_penalty = 0.5;           % fraction throughput lost on RLF

% Monte Carlo
N_mc = 6;  % reduce/increase as needed for accuracy vs runtime

% MIMO config
Nt = 1;   % Tx antennas per BS
Nr = 2;   % Rx antennas per UE (1x2 MIMO)

%% ---------------- Deployments (geometry & powers) ----------------
deployments = {'Macro-only','Macro+Small','Dense-Small'};
BS = struct();
% the BS deployments
% Macro-only: 3 macro BS
BS(1).pos = [-1000,0; 0,0; 1000,0];
BS(1).Pt_dBm = [46;46;46];
BS(1).type = repmat("macro",3,1);

% Macro+Small: 3 macros + 2 small
BS(2).pos = [-1000,0; 0,0; 1000,0; -500,0; 500,0];
BS(2).Pt_dBm = [46;46;46;30;30];
BS(2).type = ["macro";"macro";"macro";"small";"small"];

% Dense-Small: small every 200 m
xs = (-1000:200:1000)';
BS(3).pos = [xs, zeros(size(xs))];
BS(3).Pt_dBm = 30 * ones(size(xs));
BS(3).type = repmat("small", numel(xs), 1);

% shadow std (per type) used as log-normal dB (per MC per BS)
sigma_shadow_map = containers.Map({'macro','small'},{12,8});

% pathloss (3GPP-ish urban macro formula)
d_min = 1;
PL_func = @(d_m) (128.1 + 37.6*log10(max(d_m/1000, d_min/1000)));

%% ---------------- Storage ----------------
results = struct();

%% ---------------- Main simulation ----------------
for modeIdx = 1:numel(deployments)
    fprintf('=== Deployment: %s ===\n', deployments{modeIdx});
    pos_bs = BS(modeIdx).pos; % load some parameters
    Pt_bs = BS(modeIdx).Pt_dBm;
    bs_type = BS(modeIdx).type;
    N_bs = size(pos_bs,1);

    for sIdx = 1:numel(speeds)
        v = speeds(sIdx); % doppler effect
        fD = v / lambda;
        fprintf('  Speed = %.1f mph (%.2f m/s), fD = %.2f Hz\n', speeds_mph(sIdx), v, fD);

        % UE trajectory along x axis
        ue_x0 = -1200; ue_y = 0;
        ue_pos = [ue_x0 + v * t_vec', ue_y * ones(N_t,1)]; % the path of UE

        SINR_acc = zeros(N_t,1); %Initialize accumulators for Monte Carlo averaging
        thr_acc = zeros(N_t,1);
        ho_acc = zeros(N_mc,1);
        rlf_acc = zeros(N_mc,1);

        for mc = 1:N_mc
            % seed per MC for reproducibility
            rng(1000 + mc);

            % create one nrCDLChannel per BS
            chBS = cell(N_bs,1);
            for b = 1:N_bs
                ch = nrCDLChannel;
                ch.DelayProfile = 'CDL-D';            % create CDL-D channel
                ch.CarrierFrequency = fc;% some parameters
                ch.SampleRate = fs;
                ch.MaximumDopplerShift = fD;
                % set antenna arrays
                ch.TransmitAntennaArray.Size = [1 Nt 1 1 1]; 
                ch.ReceiveAntennaArray.Size = [1 Nr 1 1 1];
                % randomize internal seed for variety across MC
                ch.Seed = randi(intmax('uint32'));
                chBS{b} = ch;
            end

            % prepare pilot TX signal and run channels
            % simple pilot waveform (N_t samples, Nt streams)
            txSig = ones(N_t, Nt); % constant pilot per antenna (complex real)
            % A known reference signal sent through the channel so we can extract the multipath fading gains (H(t)) for SINR calculation.
            % Sends a deterministic pilot waveform through each BS channel.
            % run each BS channel to obtain path gains info
            PathGains_all = cell(N_bs,1); % each: Nr x Nt x Npaths x Nsamples
            for b = 1:N_bs
                [rxSig, pathGains] = ch(txSig);
                PathGains_all{b} = pathGains;
                
            end

            % ---------- generate shadowing per BS for this MC ----------
            shadow_dB = zeros(N_bs,1);
            for b = 1:N_bs
                stype = char(bs_type(b));
                sigma_s = sigma_shadow_map(stype);
                shadow_dB(b) = sigma_s * randn();  % time-constant shadow per MC
            end

            % compute instantaneous SINR/throughput
            SINR_vec = zeros(N_t,1);
            thr_vec = zeros(N_t,1);
            serving_idx = zeros(N_t,1);
            prevCell = -1;
            outageTimer = 0;
            ho_count = 0;
            rlf_count = 0;

            for tt = 1:N_t
                % compute received linear power from each BS at time tt
                Rx_lin = zeros(N_bs,1);
                for b = 1:N_bs
                    Pg = PathGains_all{b}; % Nr x Nt x Npaths
                    % sum over paths => instantaneous narrowband H (Nr x Nt)
                    H = sum(Pg,3);                   % Nr x Nt (complex)
                    % link raw power (before Tx power/pathloss/shadow): sum |H|^2
                    link_power = sum(abs(H(:)).^2);  % scalar
                    % pathloss & tx power & shadow:
                    d = sqrt((ue_pos(tt,1)-pos_bs(b,1))^2 + (ue_pos(tt,2)-pos_bs(b,2))^2);
                    d = max(d, d_min);
                    PLdB = PL_func(d);
                    % combine: linear Rx power = link_power * 10^{(Pt - PL - shadow)/10}
                    Rx_lin(b) = link_power * 10^((Pt_bs(b) - PLdB - shadow_dB(b))/10);
                end

                % select serving by max RSRP
                [Pserv, servIdx] = max(Rx_lin);
                serving_idx(tt) = servIdx;

                % compute SINR
                P_signal = Pserv;
                P_int = sum(Rx_lin) - P_signal;
                P_noise = 10^(noise_power_dBm/10);
                SINR_lin = P_signal / (P_int + P_noise);
                SINR_vec(tt) = 10*log10(SINR_lin);

                % throughput
                thr_vec(tt) = BW * log2(1 + SINR_lin) / 1e6; % Mbps

                % HO detection & penalty
                if tt > 1 && serving_idx(tt) ~= serving_idx(tt-1)
                    ho_count = ho_count + 1;
                    % zero throughput for HO_delay window (simple model)
                    endIdx = min(N_t, tt + round(HO_delay/dt));
                    thr_vec(tt:endIdx) = 0;
                end

                % RLF detection & penalty
                if SINR_vec(tt) < RLF_sinr_threshold_dB
                    outageTimer = outageTimer + dt;
                else
                    outageTimer = 0;
                end
                if outageTimer >= RLF_timeout
                    rlf_count = rlf_count + 1;
                    outageTimer = 0;
                    % apply RLF penalty: reduce future throughput (simple)
                    % here we zero a short window
                    endIdx = min(N_t, tt + round(0.5/dt)); % 0.5s penalty window
                    thr_vec(tt:endIdx) = 0;
                end
            end % tt

            % accumulate MC
            SINR_acc = SINR_acc + SINR_vec;
            thr_acc = thr_acc + thr_vec;
            ho_acc(mc) = ho_count;
            rlf_acc(mc) = rlf_count;
        end % mc

        % average results over Monte Carlo
        SINR_avg = SINR_acc / N_mc;
        thr_avg = thr_acc / N_mc;

        % save into results
        results(modeIdx).name = deployments{modeIdx};
        results(modeIdx).speed(sIdx).v_mps = v;
        results(modeIdx).speed(sIdx).v_mph = speeds_mph(sIdx);
        results(modeIdx).speed(sIdx).t = t_vec;
        results(modeIdx).speed(sIdx).ue_pos = ue_pos;
        results(modeIdx).speed(sIdx).SINR_dB = SINR_avg;
        results(modeIdx).speed(sIdx).throughput_Mbps = thr_avg;
        results(modeIdx).speed(sIdx).handover_count = mean(ho_acc);
        results(modeIdx).speed(sIdx).rlf_count = mean(rlf_acc);

        fprintf('    HOs: %.1f, RLFs: %.1f, avg SINR = %.2f dB, avg thr = %.2f Mbps\n', ...
            mean(ho_acc), mean(rlf_acc), mean(SINR_avg), mean(thr_avg));
    end
end

%% ---------------- Plotting ----------------
% (reuse your plotting style)
% 1) SINR over time for each deployment & speed
for modeIdx = 1:numel(deployments)
    figure('Name', ['MIMO SINR over time - ' deployments{modeIdx}]);
    for sIdx = 1:numel(speeds)
        subplot(numel(speeds),1,sIdx);
        plot(results(modeIdx).speed(sIdx).t, results(modeIdx).speed(sIdx).SINR_dB,'LineWidth',1.2);
        grid on; ylabel('SINR (dB)');
        title(sprintf('%s — %d mph', deployments{modeIdx}, speeds_mph(sIdx)));
        xlim([0 20]);
        if sIdx==numel(speeds), xlabel('Time (s)'); end
    end
end

% 2) Throughput CDF comparison across modes for each speed
for sIdx = 1:numel(speeds)
    figure('Name', sprintf('MIMO Throughput CDF - speed %d mph', speeds_mph(sIdx)));
    hold on;
    for modeIdx = 1:numel(deployments)
        data = results(modeIdx).speed(sIdx).throughput_Mbps;
        [f,x] = ecdf(data);
        plot(x,f,'LineWidth',1.2);
    end
    grid on; legend(deployments,'Location','best'); xlabel('Throughput (Mbps)'); ylabel('CDF');
    title(sprintf('Throughput CDF at %d mph', speeds_mph(sIdx)));
    hold off;
end

% 3) Bar charts
ho_matrix = zeros(numel(deployments), numel(speeds));
rlf_matrix = zeros(numel(deployments), numel(speeds));
avg_sinr = zeros(numel(deployments), numel(speeds));
avg_thr = zeros(numel(deployments), numel(speeds));
for modeIdx=1:numel(deployments)
    for sIdx=1:numel(speeds)
        ho_matrix(modeIdx,sIdx)=results(modeIdx).speed(sIdx).handover_count;
        rlf_matrix(modeIdx,sIdx)=results(modeIdx).speed(sIdx).rlf_count;
        avg_sinr(modeIdx,sIdx)=mean(results(modeIdx).speed(sIdx).SINR_dB);
        avg_thr(modeIdx,sIdx)=mean(results(modeIdx).speed(sIdx).throughput_Mbps);
    end
end

figure('Name','MIMO Handover count'); bar(ho_matrix'); set(gca,'XTickLabel',deployments);
legend(string(speeds_mph)+" mph",'Location','best'); ylabel('Handover count'); grid on; title('Handover count');

figure('Name','MIMO RLF count'); bar(rlf_matrix'); set(gca,'XTickLabel',deployments);
legend(string(speeds_mph)+" mph",'Location','best'); ylabel('RLF count'); grid on; title('RLF count');

figure('Name','MIMO Avg SINR'); bar(avg_sinr'); set(gca,'XTickLabel',deployments);
legend(string(speeds_mph)+" mph",'Location','best'); ylabel('Average SINR (dB)'); grid on; title('Average SINR');

figure('Name','MIMO Avg Throughput'); bar(avg_thr'); set(gca,'XTickLabel',deployments);
legend(string(speeds_mph)+" mph",'Location','best'); ylabel('Average Throughput (Mbps)'); grid on; title('Average Throughput');

fprintf('Simulation completed.\n');