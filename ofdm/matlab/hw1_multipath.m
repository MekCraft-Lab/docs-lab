clear; clc; close all;

N_fft = 1024;
f = linspace(0, 1, N_fft);

% 构建双径与五径信道模型
h_2path = [1, 0, 0, 0.5];
h_5path = [1, 0, 0.4, 0, -0.3, 0.2, 0, 0.1];

% 计算离散傅里叶变换
H2_mag = abs(fft(h_2path, N_fft));
H5_mag = abs(fft(h_5path, N_fft));

figure('Position', [100, 100, 700, 400]);
hold on;
plot(f, H2_mag, 'Color', '#0072BD', 'LineWidth', 1.5, 'DisplayName', '双径信道 (2径)');
plot(f, H5_mag, 'Color', '#D95319', 'LineStyle', '-', 'LineWidth', 1.5, 'DisplayName', '复杂信道 (5径)');

grid on; xlabel('归一化频率'); ylabel('幅度 |H(f)|');
title('复杂多径环境下的信道幅度响应对比');
legend('Location', 'northeast');

cd('D:/Program/MekCraft-Labs/docs-lab/ofdm');
saveas(gcf, 'figures/hw1_multipath.png');
fprintf('hw1_multipath.png saved.\n');
