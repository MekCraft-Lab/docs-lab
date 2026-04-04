clear; clc; close all;
cd('D:/Program/MekCraft-Labs/docs-lab/ofdm');

%% ========== 全局参数 ==========
N_fft   = 64;
N_syms  = 50000;       % 增大以支持高 SNR
CP_len  = 16;          % N_fft 的 1/4，标准 CP 长度
SNR_dB  = 20;          % 均衡效果演示信噪比（与 BER 曲线使用同一参数体系）

mod_types = {'BPSK', 'QPSK', '16QAM'};
M_values  = [2, 4, 16];

% 多径信道冲激响应
h = [1, 0, 0, 0.5, 0, 0, 0.3, 0, 0.1];
L_ch = length(h);
H_k = fft(h, N_fft);

fprintf('h = [%s], L = %d, CP = %d (N_fft/4 = %d)\n', ...
    num2str(h), L_ch, CP_len, N_fft/4);

%% ========== 图1：信道频率响应 H(k) ==========
fprintf('\n===== 图1：信道 H(k) =====\n');
figure('Position', [100 100 800 400]);
subplot(1, 2, 1);
stem(0:N_fft-1, abs(H_k), 'b-', 'LineWidth', 1.2, 'MarkerSize', 3);
grid on; xlabel('子载波索引 k'); ylabel('|H(k)|');
title('信道幅度频率响应');
% 标注最小值
[min_Hk, min_idx] = min(abs(H_k));
hold on;
plot(min_idx-1, min_Hk, 'rv', 'MarkerSize', 10, 'LineWidth', 2);
text(min_idx-1, min_Hk+0.1, sprintf('min=%.2f', min_Hk), 'HorizontalAlignment', 'center');
subplot(1, 2, 2);
plot(0:N_fft-1, unwrap(angle(H_k)), 'r-o', 'LineWidth', 1.2, 'MarkerSize', 3);
grid on; xlabel('子载波索引 k'); ylabel('相位 (rad)');
title('信道相位频率响应');
saveas(gcf, 'figures/hw3_channel_Hk.png');
fprintf('  -> hw3_channel_Hk.png saved.\n');
fprintf('  |H(k)| 最小值 = %.4f, 在子载波 k=%d\n', min_Hk, min_idx-1);
fprintf('  噪声放大倍数 = 1/|H(k)|^2 = %.2f (%.1f dB)\n', ...
    1/min_Hk^2, 10*log10(1/min_Hk^2));

%% ========== 均衡前后对比（使用 SNR_dB）==========
fprintf('\n===== 均衡前后对比 (SNR=%ddB) =====\n', SNR_dB);
M_demo = 16;
numBits = N_fft * N_syms * log2(M_demo);
tx_bits = randi([0 1], numBits, 1);

% 1) 调制
X_k = qammod(tx_bits, M_demo, 'InputType', 'bit', 'UnitAveragePower', true);

% 2) 串并 + IFFT
X_k_matrix = reshape(X_k, N_fft, N_syms);
s_n = sqrt(N_fft) * ifft(X_k_matrix, N_fft);

% 3) Add CP
s_cp = [s_n(N_fft-CP_len+1:end, :); s_n];

% 4) 多径信道滤波（展平为一维连续数据流，保留符号间 ISI）
s_cp_vec = s_cp(:);                  % 矩阵展平为列向量
r_cp_vec = filter(h, 1, s_cp_vec);   % 对连续流做线性卷积
r_cp = reshape(r_cp_vec, size(s_cp));% 恢复矩阵形式

% 5) AWGN
r_cp = awgn(r_cp, SNR_dB, 'measured');

% 6) Remove CP
r_n = r_cp(CP_len+1:end, :);

% 7) FFT
Y_k_matrix = (1/sqrt(N_fft)) * fft(r_n, N_fft);
Y_k_before = Y_k_matrix(:);

% 8) ZF 均衡
Y_k_eq_matrix = Y_k_matrix ./ repmat(H_k(:), 1, N_syms);
Y_k_after = Y_k_eq_matrix(:);

% 9) 解调
rx_bits = qamdemod(Y_k_after, M_demo, 'OutputType', 'bit', ...
                   'UnitAveragePower', true);
BER = sum(tx_bits ~= rx_bits) / length(tx_bits);

fprintf('  16QAM @ SNR=%ddB, BER = %.4e\n', SNR_dB, BER);

% 绘制均衡前后对比图
figure('Position', [100 100 800 350]);
subplot(1, 2, 1);
plot(Y_k_before(1:2000), 'b.', 'MarkerSize', 1);
grid on; axis square;
xlabel('同相分量 I'); ylabel('正交分量 Q');
title(sprintf('均衡前 (FFT 直接输出)'));
subplot(1, 2, 2);
X_ref = qammod(0:M_demo-1, M_demo, 'UnitAveragePower', true);
plot(Y_k_after(1:2000), 'b.', 'MarkerSize', 1); hold on;
plot(real(X_ref), imag(X_ref), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
grid on; axis square;
xlabel('同相分量 I'); ylabel('正交分量 Q');
title(sprintf('ZF 均衡后 (BER=%.1e)', BER));
sgtitle(sprintf('16-QAM 多径信道均衡前后对比 (SNR = %d dB)', SNR_dB), 'FontSize', 13);
saveas(gcf, 'figures/hw3_equalization_compare.png');
fprintf('  -> hw3_equalization_compare.png saved.\n');

%% ========== BER vs SNR 蒙特卡洛仿真 ==========
fprintf('\n===== BER vs SNR 蒙特卡洛 =====\n');
SNR_range = 0:2:24;
ber_sim   = zeros(3, length(SNR_range));

for i = 1:3
    M = M_values(i);
    numBits = N_fft * N_syms * log2(M);
    tx_bits = randi([0 1], numBits, 1);

    % Mod + S/P + IFFT + Add CP (一次性)
    if M == 2
        X_k = pskmod(tx_bits, M);
    else
        X_k = qammod(tx_bits, M, 'InputType', 'bit', 'UnitAveragePower', true);
    end
    X_k_matrix = reshape(X_k, N_fft, N_syms);
    s_n = sqrt(N_fft) * ifft(X_k_matrix, N_fft);
    s_cp = [s_n(N_fft-CP_len+1:end, :); s_n];

    % 多径信道滤波（展平为连续流，保留符号间 ISI）
    s_cp_vec = s_cp(:);
    r_cp_vec = filter(h, 1, s_cp_vec);
    r_cp = reshape(r_cp_vec, size(s_cp));

    for j = 1:length(SNR_range)
        % 每次只重新叠加噪声
        r_noisy = awgn(r_cp, SNR_range(j), 'measured');
        r_n = r_noisy(CP_len+1:end, :);
        Y_k_matrix = (1/sqrt(N_fft)) * fft(r_n, N_fft);
        Y_k_eq = Y_k_matrix ./ repmat(H_k(:), 1, N_syms);
        Y_k_serial = Y_k_eq(:);

        if M == 2
            rx_sym = pskdemod(Y_k_serial, M);
            rx_bits = rx_sym;
        else
            rx_bits = qamdemod(Y_k_serial, M, 'OutputType', 'bit', ...
                               'UnitAveragePower', true);
        end

        errors = sum(tx_bits ~= rx_bits);
        if errors == 0
            ber_sim(i, j) = 1 / numBits;
        else
            ber_sim(i, j) = errors / numBits;
        end
    end
    fprintf('  %s done.\n', mod_types{i});
end

% 理论 BER（无多径、理想均衡下的 AWGN 理论值作为参考）
ber_awgn = zeros(3, length(SNR_range));
for i = 1:3
    M = M_values(i);
    k = log2(M);
    EbNo_range = SNR_range - 10*log10(k);
    if M == 2
        ber_awgn(i, :) = berawgn(EbNo_range, 'psk', M, 'nondiff');
    else
        ber_awgn(i, :) = berawgn(EbNo_range, 'qam', M);
    end
end

% 绘制仿真 + AWGN 理论参考
figure('Position', [100 100 700 500]);
colors = {'b', 'r', 'm'};
markers = {'o', 's', 'd'};
for i = 1:3
    semilogy(SNR_range, ber_sim(i,:), [colors{i}, markers{i}, '-'], ...
        'LineWidth', 1.5, 'MarkerSize', 6, ...
        'DisplayName', [mod_types{i}, ' 仿真(多径+ZF)']);
    hold on;
    semilogy(SNR_range, ber_awgn(i,:), [colors{i}, '--'], ...
        'LineWidth', 1.2, 'DisplayName', [mod_types{i}, ' AWGN理论']);
end
grid on;
xlabel('SNR (dB)'); ylabel('误码率 (BER)');
title('多径信道 + CP + ZF 均衡下 OFDM 误码率');
legend('Location', 'southwest');
ylim([1e-6, 1]);
saveas(gcf, 'figures/hw3_ber_curve.png');
fprintf('  -> hw3_ber_curve.png saved.\n');

% 输出关键数据表
fprintf('\n===== BER 数据表 =====\n');
fprintf('%-8s | %-12s %-12s | %-12s %-12s | %-12s %-12s\n', ...
    'SNR(dB)', 'BPSK_sim', 'BPSK_AWGN', 'QPSK_sim', 'QPSK_AWGN', '16QAM_sim', '16QAM_AWGN');
fprintf('%s\n', repmat('-', 1, 85));
for j = 1:length(SNR_range)
    fprintf('%-8d | %-12.2e %-12.2e | %-12.2e %-12.2e | %-12.2e %-12.2e\n', ...
        SNR_range(j), ber_sim(1,j), ber_awgn(1,j), ...
        ber_sim(2,j), ber_awgn(2,j), ber_sim(3,j), ber_awgn(3,j));
end

fprintf('\n===== 全部完成 =====\n');
