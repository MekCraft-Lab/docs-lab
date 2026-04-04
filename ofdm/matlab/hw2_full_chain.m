clear; clc; close all;
cd('D:/Program/MekCraft-Labs/docs-lab/ofdm');

%% ========== 全局参数 ==========
N_fft   = 64;
N_syms  = 50000;       % 增大符号数以支持高 SNR 统计
SNR_dB  = 15;          % 单点演示信噪比

mod_types = {'BPSK', 'QPSK', '16QAM'};
M_values  = [2, 4, 16];

%% ========== 环节二：IFFT 变换 ==========
fprintf('===== 环节二：IFFT 变换 =====\n');
figure('Position', [100 100 900 350]);
for i = 1:3
    M = M_values(i);
    numBits = N_fft * 1 * log2(M);
    bits = randi([0 1], numBits, 1);

    if M == 2
        X_k = pskmod(bits, M);
    else
        X_k = qammod(bits, M, 'InputType', 'bit', 'UnitAveragePower', true);
    end

    X_k_matrix = reshape(X_k, N_fft, 1);
    s_n = sqrt(N_fft) * ifft(X_k_matrix, N_fft);

    subplot(1, 3, i);
    plot(real(s_n), 'b-', 'LineWidth', 0.8); hold on;
    plot(imag(s_n), 'r-', 'LineWidth', 0.8);
    grid on;
    xlabel('采样点 n'); ylabel('幅度');
    title([mod_types{i}, ' IFFT 输出时域波形']);
    legend('实部', '虚部', 'Location', 'best');
end
saveas(gcf, 'figures/hw2_step2_ifft.png');
fprintf('  -> hw2_step2_ifft.png saved.\n');

%% ========== 环节三：AWGN 信道 ==========
fprintf('===== 环节三：AWGN 信道 =====\n');
figure('Position', [100 100 900 350]);
for i = 1:3
    M = M_values(i);
    numBits = N_fft * N_syms * log2(M);
    bits = randi([0 1], numBits, 1);

    if M == 2
        X_k = pskmod(bits, M);
    else
        X_k = qammod(bits, M, 'InputType', 'bit', 'UnitAveragePower', true);
    end

    X_k_matrix = reshape(X_k, N_fft, N_syms);
    s_n = sqrt(N_fft) * ifft(X_k_matrix, N_fft);
    r_n = awgn(s_n, SNR_dB, 'measured');
    Y_k_matrix = (1/sqrt(N_fft)) * fft(r_n, N_fft);
    Y_k = Y_k_matrix(:);

    subplot(1, 3, i);
    plot(Y_k(1:500), 'b.', 'MarkerSize', 1);
    grid on; axis square;
    xlim([-2 2]); ylim([-2 2]);
    xlabel('同相分量 I'); ylabel('正交分量 Q');
    title([mod_types{i}, ' AWGN 后星座图 (SNR=', num2str(SNR_dB), 'dB)']);
end
saveas(gcf, 'figures/hw2_step3_awgn.png');
fprintf('  -> hw2_step3_awgn.png saved.\n');

%% ========== 环节四：FFT 变换 ==========
fprintf('===== 环节四：FFT 变换 =====\n');
figure('Position', [100 100 900 350]);
fft_data = struct();
for i = 1:3
    M = M_values(i);
    numBits = N_fft * N_syms * log2(M);
    bits = randi([0 1], numBits, 1);

    if M == 2
        X_k = pskmod(bits, M);
    else
        X_k = qammod(bits, M, 'InputType', 'bit', 'UnitAveragePower', true);
    end

    X_k_matrix = reshape(X_k, N_fft, N_syms);
    s_n = sqrt(N_fft) * ifft(X_k_matrix, N_fft);
    r_n = awgn(s_n, SNR_dB, 'measured');
    Y_k_matrix = (1/sqrt(N_fft)) * fft(r_n, N_fft);
    Y_k = Y_k_matrix(:);

    fft_data(i).Y_k = Y_k;
    fft_data(i).bits = bits;

    subplot(1, 3, i);
    plot(Y_k(1:1000), 'b.', 'MarkerSize', 1);
    grid on; axis square;
    xlim([-2 2]); ylim([-2 2]);
    xlabel('同相分量 I'); ylabel('正交分量 Q');
    title([mod_types{i}, ' FFT 输出星座图']);
end
saveas(gcf, 'figures/hw2_step4_fft.png');
fprintf('  -> hw2_step4_fft.png saved.\n');

%% ========== 环节五：信号解调 ==========
fprintf('===== 环节五：信号解调 =====\n');
figure('Position', [100 100 900 350]);
ber_results = zeros(1, 3);
for i = 1:3
    M = M_values(i);
    Y_k = fft_data(i).Y_k;
    bits = fft_data(i).bits;

    if M == 2
        rx_sym = pskdemod(Y_k, M);
        rx_bits = rx_sym;
    else
        rx_bits = qamdemod(Y_k, M, 'OutputType', 'bit', 'UnitAveragePower', true);
    end

    ber_results(i) = sum(bits ~= rx_bits) / length(bits);

    subplot(1, 3, i);
    if M == 2
        X_ref = pskmod([0; 1], M);
    else
        X_ref = qammod(0:M-1, M, 'UnitAveragePower', true);
    end
    plot(Y_k(1:1000), 'b.', 'MarkerSize', 1); hold on;
    plot(real(X_ref), imag(X_ref), 'rx', 'MarkerSize', 10, 'LineWidth', 2);
    grid on; axis square;
    xlim([-2 2]); ylim([-2 2]);
    xlabel('同相分量 I'); ylabel('正交分量 Q');
    title([mod_types{i}, ' 判决后 (BER=', num2str(ber_results(i), '%.1e'), ')']);
end
saveas(gcf, 'figures/hw2_step5_demod.png');
fprintf('  -> hw2_step5_demod.png saved.\n');

%% ========== BER vs SNR（蒙特卡洛仿真 + 理论曲线）==========
fprintf('===== BER vs SNR =====\n');
SNR_range = 0:2:20;
ber_sim   = zeros(3, length(SNR_range));
ber_theory = zeros(3, length(SNR_range));

for i = 1:3
    M = M_values(i);
    k = log2(M);  % bits per symbol
    numBits = N_fft * N_syms * k;
    tx_bits = randi([0 1], numBits, 1);

    % Mod + IFFT (一次生成)
    if M == 2
        X_k = pskmod(tx_bits, M);
    else
        X_k = qammod(tx_bits, M, 'InputType', 'bit', 'UnitAveragePower', true);
    end
    X_k_matrix = reshape(X_k, N_fft, N_syms);
    s_n = sqrt(N_fft) * ifft(X_k_matrix, N_fft);

    for j = 1:length(SNR_range)
        r_n = awgn(s_n, SNR_range(j), 'measured');
        Y_k_matrix = (1/sqrt(N_fft)) * fft(r_n, N_fft);
        Y_k = Y_k_matrix(:);

        if M == 2
            rx_sym = pskdemod(Y_k, M);
            rx_bits = rx_sym;
        else
            rx_bits = qamdemod(Y_k, M, 'OutputType', 'bit', 'UnitAveragePower', true);
        end

        errors = sum(tx_bits ~= rx_bits);
        if errors == 0
            ber_sim(i, j) = 1 / numBits;  % 至少记录 1/total
        else
            ber_sim(i, j) = errors / numBits;
        end
    end

    % 理论 BER 曲线（使用 berawgn，需将 Es/N0 转换为 Eb/N0）
    k = log2(M);
    EbNo_range = SNR_range - 10*log10(k);
    for j = 1:length(SNR_range)
        if M == 2
            ber_theory(i, j) = berawgn(EbNo_range(j), 'psk', M, 'nondiff');
        elseif M == 4
            ber_theory(i, j) = berawgn(EbNo_range(j), 'qam', M);
        else
            ber_theory(i, j) = berawgn(EbNo_range(j), 'qam', M);
        end
    end

    fprintf('  %s done.\n', mod_types{i});
end

% 绘制仿真 + 理论对比图
figure('Position', [100 100 700 500]);
colors = {'b', 'r', 'm'};
markers = {'o', 's', 'd'};
for i = 1:3
    semilogy(SNR_range, ber_sim(i,:), [colors{i}, markers{i}, '-'], ...
        'LineWidth', 1.5, 'MarkerSize', 6, ...
        'DisplayName', [mod_types{i}, ' 仿真']);
    hold on;
    semilogy(SNR_range, ber_theory(i,:), [colors{i}, '--'], ...
        'LineWidth', 1.2, 'DisplayName', [mod_types{i}, ' 理论']);
end
grid on;
xlabel('SNR (dB)'); ylabel('误码率 (BER)');
title('AWGN 信道下 OFDM 系统误码率：仿真 vs 理论');
legend('Location', 'southwest');
ylim([1e-6, 1]);
saveas(gcf, 'figures/ber_snr_curve.png');
fprintf('  -> ber_snr_curve.png saved.\n');

% 输出关键 SNR 数据表
fprintf('\n===== 关键数据表 =====\n');
fprintf('%-8s | %-12s %-12s | %-12s %-12s | %-12s %-12s\n', ...
    'SNR(dB)', 'BPSK_sim', 'BPSK_theory', 'QPSK_sim', 'QPSK_theory', '16QAM_sim', '16QAM_theory');
fprintf('%s\n', repmat('-', 1, 85));
for j = 1:length(SNR_range)
    fprintf('%-8d | %-12.2e %-12.2e | %-12.2e %-12.2e | %-12.2e %-12.2e\n', ...
        SNR_range(j), ber_sim(1,j), ber_theory(1,j), ...
        ber_sim(2,j), ber_theory(2,j), ber_sim(3,j), ber_theory(3,j));
end

fprintf('\n===== 全部完成 =====\n');
