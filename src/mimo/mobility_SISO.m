%% mobility_SISO_R2024b.m
% SISO cellular connectivity under mobility with Doppler + HO/RLF penalties + Monte Carlo
clear; close all; clc;

%% Simulation parameters
c = 3e8; fc = 3.5e9; lambda = c/fc;
BW = 10e6; kB = 1.38e-23; T0 = 290; NF_dB = 7;
noise_power_dBm = 10*log10(kB*T0*BW) + 30 + NF_dB;

speeds_mph = [30,90,150]; mph2ms=0.44704; speeds=speeds_mph*mph2ms;
t_end = 20; dt = 0.01; t_vec = 0:dt:t_end; N_t = numel(t_vec);

RLF_sinr_threshold_dB = 20; RLF_timeout=0.2;
HO_delay = 0.05; % seconds of throughput loss per HO
RLF_penalty = 0.5; % fraction of throughput lost during RLF
d_min=1; rng(0);

%% Deployment modes
deployments = {'Macro-only','Macro+Small','Dense-Small'};
BS = struct();
BS(1).pos=[-1000 0;0 0;1000 0]; BS(1).Pt_dBm=[46;46;46]; BS(1).type=repmat("macro",3,1);
BS(2).pos=[-1000 0;0 0;1000 0;-500 0;500 0]; BS(2).Pt_dBm=[46;46;46;30;30]; BS(2).type=["macro";"macro";"macro";"small";"small"];
xs=(-1000:200:1000)'; BS(3).pos=[xs zeros(size(xs))]; BS(3).Pt_dBm=30*ones(size(xs)); BS(3).type=repmat("small",numel(xs),1);

sigma_shadow = containers.Map({'macro','small'},{12,8}); % shadow std
PL_func=@(d) (128.1 + 37.6*log10(max(d/1000,d_min/1000)));

%% Monte Carlo parameters
N_mc = 10;  % number of realizations

results = struct();

for modeIdx=1:numel(deployments)
    modeName=deployments{modeIdx};
    fprintf('Simulating deployment: %s\n',modeName);
    pos_bs=BS(modeIdx).pos; Pt_bs=BS(modeIdx).Pt_dBm; bs_type=BS(modeIdx).type;
    N_bs=size(pos_bs,1);

    for sIdx=1:numel(speeds)
        v = speeds(sIdx);
        fprintf('  Speed = %.1f mph (%.2f m/s)\n',speeds_mph(sIdx),v);

        % UE trajectory
        ue_x0=-1200; ue_y=0; ue_pos=[ue_x0 + v*t_vec', ue_y*ones(N_t,1)];

        % MC average storage
        SINR_avg = zeros(N_t,1); throughput_avg = zeros(N_t,1);
        ho_count_mc = zeros(N_mc,1); rlf_count_mc = zeros(N_mc,1);

        for mc=1:N_mc
            % --- Generate fading & shadowing ---
            fs = 1/dt; fD = v/lambda; fc_cut = 1.2*fD; L=101;
            fadingCorr=zeros(N_bs,N_t);
            shadowCorr=zeros(N_bs,N_t);
            for b=1:N_bs
                w=(randn(N_t,1)+1j*randn(N_t,1))/sqrt(2);
                if fc_cut/(fs/2)<0.99
                    h_lp=fir1(L-1,min(0.99,fc_cut/(fs/2)));
                    hf=filter(h_lp,1,w);
                else
                    hf=w;
                end
                hf=hf/std(hf); fadingCorr(b,:) = abs(hf(:)).';
                sigma_s = sigma_shadow(char(bs_type(b))); w2=randn(N_t,1);
                if fc_cut/(fs/2)<0.99, hs=filter(h_lp,1,w2); else hs=w2; end
                hs=hs/std(hs); shadowCorr(b,:) = sigma_s*hs(:).';
            end

            % --- Create SISO CDL channels ---
            ch = cell(N_bs,1);
            for b=1:N_bs
                ch{b} = nrCDLChannel('DelayProfile','CDL-A',...
                     'CarrierFrequency',fc,...
                     'SampleRate',fs);

% 配置 SISO 天线
                ch{b}.TransmitAntennaArray.Size = [1 1 1 1 1];   % Nt x 1 x 1 x 1 x 1
                ch{b}.TransmitAntennaArray.Element = 'isotropic';
                ch{b}.ReceiveAntennaArray.Size  = [1 1 1 1 1];   % Nr x 1 x 1 x 1 x 1
                ch{b}.ReceiveAntennaArray.Element  = 'isotropic';
            end

            % --- Simulation per time step ---
            RSRP_dBm=zeros(N_t,N_bs); SINR_dB=zeros(N_t,1); throughput_Mbps=zeros(N_t,1);
            serving_idx=zeros(N_t,1);
            outageTimer=0; rlf_count=0; ho_count=0; prevCell=1;

            for tt=1:N_t
                Rx_lin = zeros(N_bs,1);
                shadow_dB = shadowCorr(:,tt);
                for b=1:N_bs
                    % transmit unit power
                    x = 1;
                    y = ch{b}(x); % SISO output
                    Rx_lin(b) = sum(abs(y).^2); % received power
                    % add shadow, pathloss, Tx power
                    d = sqrt((ue_pos(tt,1)-pos_bs(b,1))^2 + (ue_pos(tt,2)-pos_bs(b,2))^2);
                    d = max(d, d_min);
                    PLdB = PL_func(d);
                    Rx_lin(b) = Rx_lin(b) * 10^((Pt_bs(b) - PLdB - shadow_dB(b))/10);
                end

                Rx_dBm = 10*log10(Rx_lin);
                RSRP_dBm(tt,:) = Rx_dBm';
                [servPow, servIdx] = max(Rx_dBm); serving_idx(tt)=servIdx;

                % Count HO
                if tt>1 && servIdx~=prevCell
                    ho_count = ho_count+1;
                    throughput_Mbps(tt) = throughput_Mbps(tt) * (1-HO_delay/dt);
                end
                prevCell = servIdx;

                % Compute SINR & throughput
                P_signal_lin = 10^(servPow/10);
                P_int_lin = sum(10.^(Rx_dBm/10)) - P_signal_lin;
                P_noise_lin = 10^(noise_power_dBm/10);
                SINR_lin = P_signal_lin / (P_int_lin + P_noise_lin);
                SINR_dB(tt) = 10*log10(SINR_lin + 1e-12);
                throughput_Mbps(tt) = BW*log2(1+SINR_lin)/1e6;

                % RLF penalty
                if SINR_dB(tt)<RLF_sinr_threshold_dB, outageTimer=outageTimer+dt; else outageTimer=0; end
                if outageTimer>RLF_timeout
                    rlf_count=rlf_count+1; outageTimer=0;
                    throughput_Mbps(tt)=throughput_Mbps(tt)*(1-RLF_penalty);
                end
            end

            % accumulate for MC
            SINR_avg = SINR_avg + SINR_dB;
            throughput_avg = throughput_avg + throughput_Mbps;
            ho_count_mc(mc) = ho_count; rlf_count_mc(mc) = rlf_count;
        end

        % Average over MC
        SINR_avg = SINR_avg / N_mc;
        throughput_avg = throughput_avg / N_mc;

        % Save results
        results(modeIdx).name=modeName; results(modeIdx).bs_pos=pos_bs; results(modeIdx).Pt_dBm=Pt_bs;
        results(modeIdx).speed(sIdx).v_mps=v; results(modeIdx).speed(sIdx).v_mph=speeds_mph(sIdx);
        results(modeIdx).speed(sIdx).t=t_vec; results(modeIdx).speed(sIdx).ue_pos=ue_pos;
        results(modeIdx).speed(sIdx).SINR_dB=SINR_avg; results(modeIdx).speed(sIdx).throughput_Mbps=throughput_avg;
        results(modeIdx).speed(sIdx).handover_count=mean(ho_count_mc);
        results(modeIdx).speed(sIdx).rlf_count=mean(rlf_count_mc);

        fprintf('    HOs: %.1f, RLFs: %.1f, avg SINR=%.2f dB, avg throughput=%.2f Mbps\n', ...
            mean(ho_count_mc), mean(rlf_count_mc), mean(SINR_avg), mean(throughput_avg));
    end
end

%% ------------------ Plotting ------------------
% 可以直接复用之前MIMO版本的绘图代码
% SINR over time, Throughput CDF, HO/RLF bar charts
% ... (复制前面绘图段落即可)
%% ------------------ Plotting ------------------

% 1) SINR over time for each deployment & speed
for modeIdx = 1:numel(deployments)
    figure('Name', ['SINR over time - ' deployments{modeIdx}]);
    for sIdx = 1:numel(speeds)
        subplot(numel(speeds),1,sIdx);
        plot(results(modeIdx).speed(sIdx).t, results(modeIdx).speed(sIdx).SINR_dB,'LineWidth',1.5);
        grid on;
        ylabel('SINR (dB)');
        title(sprintf('%s — speed %d mph', deployments{modeIdx}, speeds_mph(sIdx)));
        if sIdx==numel(speeds), xlabel('Time (s)'); end
    end
end

% 2) Throughput CDF comparison across modes for each speed
for sIdx = 1:numel(speeds)
    figure('Name', sprintf('Throughput CDF - speed %d mph', speeds_mph(sIdx)));
    hold on;
    for modeIdx = 1:numel(deployments)
        data = results(modeIdx).speed(sIdx).throughput_Mbps;
        [f,x] = ecdf(data);
        plot(x,f,'LineWidth',1.5);
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