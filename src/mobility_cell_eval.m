% mobility_cell_eval.m
% Evaluation of Cellular Connectivity Under Mobility (MATLAB)
% Carrier: 3.5 GHz, speeds: 30/90/150 mph
% Three deployment modes: Macro-only, Macro+Small, Dense-Small
% Simple pathloss+shadowing+fading, MIMO modeled as dB gain

clear; close all; clc;

%% ------------------ Simulation Parameters ------------------
c = 3e8;
fc = 3.5e9;             % carrier frequency 3.5 GHz
lambda = c/fc;
BW = 10e6;              % 10 MHz
kB = 1.38064852e-23;
T0 = 290;
NF_dB = 7;              % noise figure
noise_power_dBm = 10*log10(kB*T0*BW) + 30 + NF_dB;  % dBm

% speeds in mph -> convert to m/s
speeds_mph = [30, 90, 150];
mph2ms = 0.44704;
speeds = speeds_mph * mph2ms;

% time parameters
t_end = 20;             % seconds
dt = 0.01;              % time step in seconds
t_vec = 0:dt:t_end;
N_t = numel(t_vec);

% MIMO options: set true to enable MIMO gain (simplified)
MIMO_on = true;
MIMO_gain_dB = 3;       % assume 2x2 ~ 3 dB gain

% RLF detection thresholds
RLF_sinr_threshold_dB = 5;  % if SINR below this value considered bad
RLF_timeout = 0.2;           % seconds of consecutive bad SINR to count RLF

% Small numerical helper
d_min = 1;  % minimum distance in meter to avoid log10(0)

% seed for reproducibility
rng(0);

%% ------------------ Base Station Deployment Modes ------------------
% Coordinates (x,y) in meters. UE moves along x axis (y=0).
% You can tune positions/powers to match your desired scenarios.

deployments = {'Macro-only', 'Macro+Small', 'Dense-Small'};

BS = struct();

% Macro-only: three macro BS at -1000, 0, +1000 (along x-axis)
BS(1).pos = [-1000, 0; 0, 0; 1000, 0]; % meters
BS(1).Pt_dBm = [46; 46; 46];           % 46 dBm macro
BS(1).type = repmat("macro",3,1);

% Macro + Small: macros at -1000,0,1000 plus small cells near road
BS(2).pos = [-1000,0; 0,0; 1000,0; -500,0; 500,0];
BS(2).Pt_dBm = [46; 46; 46; 30; 30];   % small ~30 dBm
BS(2).type = ["macro";"macro";"macro";"small";"small"];

% Dense Small: small cells every 200m from -1000 to +1000
xs = (-1000:200:1000)';
BS(3).pos = [xs, zeros(size(xs))];
BS(3).Pt_dBm = 30 * ones(size(xs));   % 30 dBm for small
BS(3).type = repmat("small", numel(xs), 1);

% shadowing std per type
sigma_shadow = containers.Map({'macro','small'},{12,14}); % dB

%% ------------------ Pathloss model function ------------------
% Use 3GPP-like urban macro PL: PL(dB) = 128.1 + 37.6*log10(d_km)
PL_func = @(d_m) (128.1 + 37.6*log10(max(d_m/1000,d_min/1000)));

%% ------------------ Storage for results ------------------
results = struct();

for modeIdx = 1:numel(deployments)
    modeName = deployments{modeIdx};
    fprintf("Simulating deployment: %s\n", modeName);
    pos_bs = BS(modeIdx).pos;
    Pt_bs = BS(modeIdx).Pt_dBm;
    bs_type = BS(modeIdx).type;
    N_bs = size(pos_bs,1);
    
    % Prepare per speed
    for sIdx = 1:numel(speeds)
        v = speeds(sIdx);
        fprintf("  Speed = %.1f mph (%.2f m/s)\n", speeds_mph(sIdx), v);
        
        % UE initial pos: put it at x = -1200 so it passes through cells
        ue_x0 = -1200;
        ue_y = 0;
        ue_pos = [ue_x0 + v * t_vec', ue_y*ones(N_t,1)];
        
        % Preallocate
        RSRP_dBm = zeros(N_t, N_bs);
        SINR_dB = zeros(N_t,1);
        serving_idx = zeros(N_t,1);
        throughput_Mbps = zeros(N_t,1);
        
        % shadowing per BS sample (spatially correlated? we use per-sample random)
        % We'll use time-varying shadowing (independent each time) for simplicity
        for tt = 1:N_t
            % compute distances
            d = sqrt( (ue_pos(tt,1) - pos_bs(:,1)).^2 + (ue_pos(tt,2) - pos_bs(:,2)).^2 );
            d = max(d, d_min);
            PL = PL_func(d); % dB
            % shadowing
            shadow = zeros(N_bs,1);
            for b=1:N_bs
                stype = char(bs_type(b));
                sigma = sigma_shadow(stype);
                shadow(b) = sigma * randn();
            end
            % small-scale fading: Rayleigh magnitude in dB (uncorrelated per time/sample)
            fading_linear = sqrt( (randn(N_bs,1)/sqrt(2)).^2 + (randn(N_bs,1)/sqrt(2)).^2 );
            fading_dB = 20*log10(fading_linear + 1e-9);
            
            % received power per BS in dBm
            Rx_dBm = Pt_bs - PL + shadow + fading_dB;
            RSRP_dBm(tt,:) = Rx_dBm';
            
            % choose serving BS by max RSRP
            [servPow, servIdx] = max(Rx_dBm);
            serving_idx(tt) = servIdx;
            
            % compute interference: sum of linear powers of other BS
            P_signal_lin = 10^(servPow/10);
            P_int_lin = sum(10.^(Rx_dBm/10)) - P_signal_lin;
            P_noise_lin = 10^(noise_power_dBm/10);
            
            SINR_lin = P_signal_lin / (P_int_lin + P_noise_lin);
            SINRdB = 10*log10(SINR_lin + 1e-12);
            % MIMO gain
            if MIMO_on
                SINRdB = SINRdB + MIMO_gain_dB;
            end
            SINR_dB(tt) = SINRdB;
            
            % throughput via Shannon (conservative): C = BW * log2(1+SNR)
            C_bps = BW * log2(1 + max(SINR_lin * 10^(MIMO_on* (MIMO_gain_dB/10) ), 1e-12));
            throughput_Mbps(tt) = C_bps / 1e6;
        end % tt
        
        % Handover count: count changes in serving index (ignore first)
        ho_changes = sum(diff(serving_idx)~=0);
        
        % RLF detection: count epochs where SINR below threshold for >=RLF_timeout
        below = SINR_dB < RLF_sinr_threshold_dB;
        rlf_count = 0;
        consec = 0;
        for tt=1:N_t
            if below(tt)
                consec = consec + 1;
            else
                if consec * dt >= RLF_timeout
                    rlf_count = rlf_count + 1;
                end
                consec = 0;
            end
        end
        if consec * dt >= RLF_timeout
            rlf_count = rlf_count + 1;
        end
        
        % Save results
        results(modeIdx).name = modeName;
        results(modeIdx).bs_pos = pos_bs;
        results(modeIdx).Pt_dBm = Pt_bs;
        results(modeIdx).speed(sIdx).v_mps = v;
        results(modeIdx).speed(sIdx).v_mph = speeds_mph(sIdx);
        results(modeIdx).speed(sIdx).t = t_vec;
        results(modeIdx).speed(sIdx).ue_pos = ue_pos;
        results(modeIdx).speed(sIdx).RSRP_dBm = RSRP_dBm;
        results(modeIdx).speed(sIdx).SINR_dB = SINR_dB;
        results(modeIdx).speed(sIdx).throughput_Mbps = throughput_Mbps;
        results(modeIdx).speed(sIdx).serving_idx = serving_idx;
        results(modeIdx).speed(sIdx).handover_count = ho_changes;
        results(modeIdx).speed(sIdx).rlf_count = rlf_count;
        
        fprintf("    HOs: %d, RLFs: %d, avg SINR = %.2f dB, avg throughput = %.2f Mbps\n", ...
            ho_changes, rlf_count, mean(SINR_dB), mean(throughput_Mbps));
    end % speeds
end % modes

%% ------------------ Plotting ------------------
% 1) SINR over time for each deployment & speed (one figure per mode)
for modeIdx = 1:numel(deployments)
    figure('Name', ['SINR over time - ' deployments{modeIdx}]);
    for sIdx = 1:numel(speeds)
        subplot(numel(speeds),1,sIdx);
        plot(results(modeIdx).speed(sIdx).t, results(modeIdx).speed(sIdx).SINR_dB);
        grid on;
        ylabel('SINR (dB)');
        title(sprintf('%s — speed %d mph', deployments{modeIdx}, speeds_mph(sIdx)));
        if sIdx==numel(speeds)
            xlabel('Time (s)');
        end
    end
end

% 2) Throughput CDF comparison across modes for each speed
for sIdx = 1:numel(speeds)
    figure('Name', sprintf('Throughput CDF - speed %d mph', speeds_mph(sIdx)));
    hold on;
    for modeIdx = 1:numel(deployments)
        data = results(modeIdx).speed(sIdx).throughput_Mbps;
        % compute empirical CDF
        [f,x] = ecdf(data);
        plot(x, f, 'LineWidth', 1.5);
    end
    grid on; legend(deployments,'Location','best');
    xlabel('Throughput (Mbps)'); ylabel('CDF');
    title(sprintf('Throughput CDF at %d mph', speeds_mph(sIdx)));
    hold off;
end

% 3) Handover and RLF summary bar chart
ho_matrix = zeros(numel(deployments), numel(speeds));
rlf_matrix = zeros(numel(deployments), numel(speeds));
avg_sinr = zeros(numel(deployments), numel(speeds));
avg_thr = zeros(numel(deployments), numel(speeds));
for modeIdx=1:numel(deployments)
    for sIdx=1:numel(speeds)
        ho_matrix(modeIdx,sIdx) = results(modeIdx).speed(sIdx).handover_count;
        rlf_matrix(modeIdx,sIdx) = results(modeIdx).speed(sIdx).rlf_count;
        avg_sinr(modeIdx,sIdx) = mean(results(modeIdx).speed(sIdx).SINR_dB);
        avg_thr(modeIdx,sIdx) = mean(results(modeIdx).speed(sIdx).throughput_Mbps);
    end
end

figure('Name','Handover count');
bar(ho_matrix');
set(gca,'XTickLabel',deployments);
legend(string(speeds_mph)+" mph",'Location','best');
ylabel('Handover count'); grid on; title('Handover count comparison');

figure('Name','RLF count');
bar(rlf_matrix');
set(gca,'XTickLabel',deployments);
legend(string(speeds_mph)+" mph",'Location','best');
ylabel('RLF count'); grid on; title('RLF count comparison');

figure('Name','Avg SINR');
bar(avg_sinr');
set(gca,'XTickLabel',deployments);
legend(string(speeds_mph)+" mph",'Location','best');
ylabel('Average SINR (dB)'); grid on; title('Average SINR');

figure('Name','Avg Throughput');
bar(avg_thr');
set(gca,'XTickLabel',deployments);
legend(string(speeds_mph)+" mph",'Location','best');
ylabel('Average Throughput (Mbps)'); grid on; title('Average Throughput');

%% ------------------ Save results CSV (optional) ------------------
save_csv = true;
if save_csv
    outdir = fullfile(pwd,'sim_results');
    if ~exist(outdir,'dir'), mkdir(outdir); end
    for modeIdx = 1:numel(deployments)
        for sIdx = 1:numel(speeds)
            T = table(results(modeIdx).speed(sIdx).t', ...
                results(modeIdx).speed(sIdx).ue_pos(:,1), ...
                results(modeIdx).speed(sIdx).SINR_dB, ...
                results(modeIdx).speed(sIdx).throughput_Mbps, ...
                results(modeIdx).speed(sIdx).serving_idx, ...
                'VariableNames', {'time_s','ue_x_m','SINR_dB','throughput_Mbps','serving_idx'});
            fname = fullfile(outdir, sprintf('%s_speed%dmph.csv', deployments{modeIdx}, speeds_mph(sIdx)));
            % sanitize filename
            fname = strrep(fname,' ','_');
            writetable(T,fname);
        end
    end
    fprintf('Saved CSVs to %s\n', outdir);
end

%% ------------------ End ------------------
fprintf('Simulation finished.\n');