clear; clc; close all;

N_fft = 1024;
f = linspace(0, 1, N_fft);
tau = 3;

h1 = zeros(1, tau + 1);
h1(1) = 1;
h1(tau + 1) = 0.5; % 相位差 0 度

h2 = zeros(1, tau + 1);
h2(1) = 1;
h2(tau + 1) = -0.5; % 相位差 180 度 (相当于乘以 -1)

H1_mag = abs(fft(h1, N_fft));
H2_mag = abs(fft(h2, N_fft));

figure('Position', [100, 100, 800, 400]);
hold on;
plot(f, H1_mag, 'Color', '#0072BD', 'LineWidth', 1.5, 'DisplayName', '\theta = 0^\circ');
plot(f, H2_mag, 'Color', '#D95319', 'LineStyle', '--', 'LineWidth', 1.5, 'DisplayName', '\theta = 180^\circ');

grid on; xlabel('归一化频率'); ylabel('幅度 |H(f)|');
title('改变第二径相位对信道幅度响应的影响');
legend('Location', 'northeast');

cd('D:/Program/MekCraft-Labs/docs-lab/ofdm');
saveas(gcf, 'figures/hw1_phase.png');
fprintf('hw1_phase.png saved.\n');
