clear; clc; close all;

% --- 系统全局参数配置 ---
N_fft = 64;
N_syms = 10000;
SNR_dB = 15;

mod_types = {'BPSK', 'QPSK', '16QAM'};
M_values = [2, 4, 16];

% 二进制信源生成
numBits_total = N_fft * N_syms * log2(M_values(end));
tx_bits = randi([0 1], numBits_total, 1);

sim_data = struct();

for i = 1:length(mod_types)
    M = M_values(i);
    numBits = N_fft * N_syms * log2(M);
    bits_i = tx_bits(1:numBits);

    if M == 2
        X_k_serial = pskmod(bits_i, M, 'InputType', 'bit');
    else
        X_k_serial = qammod(bits_i, M, 'InputType', 'bit', 'UnitAveragePower', true);
    end

    sim_data(i).X_k_serial = X_k_serial;
    sim_data(i).M = M;
end

% 提取前 1000 个符号绘制发射端星座图
figure('Position', [100, 100, 900, 350]);
for i = 1:3
    subplot(1, 3, i);
    plot(sim_data(i).X_k_serial(1:1000), 'bo', 'MarkerSize', 2);
    grid on; axis square;
    xlim([-2 2]); ylim([-2 2]);
    xlabel('同相分量 I'); ylabel('正交分量 Q');
    title([mod_types{i}, ' 发射端星座图']);
end

cd('D:/Program/MekCraft-Labs/docs-lab/ofdm');
saveas(gcf, 'figures/hw2_step1_mod.png');
fprintf('hw2_step1_mod.png saved.\n');
