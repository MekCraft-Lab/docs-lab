clear; clc; close all;

N_fft = 1024;
f = linspace(0, 1, N_fft);
delays = [3, 7, 15];
colors = {'#0072BD', '#D95319', '#EDB120'};

figure('Position', [100, 100, 800, 600]);

for i = 1:length(delays)
    tau = delays(i);
    h = zeros(1, tau + 1);
    h(1) = 1;
    h(tau + 1) = 0.5;

    H = fft(h, N_fft);
    H_mag = abs(H);
    H_phase = unwrap(angle(H));

    subplot(2, 1, 1); hold on;
    plot(f, H_mag, 'Color', colors{i}, 'LineWidth', 1.5, ...
         'DisplayName', ['Delay \tau = ', num2str(tau)]);

    subplot(2, 1, 2); hold on;
    plot(f, H_phase, 'Color', colors{i}, 'LineWidth', 1.5, ...
         'DisplayName', ['Delay \tau = ', num2str(tau)]);
end

subplot(2, 1, 1);
grid on; xlabel('归一化频率'); ylabel('幅度 |H(f)|');
title('不同时延扩展下的信道幅度响应对比');
legend('Location', 'best');

subplot(2, 1, 2);
grid on; xlabel('归一化频率'); ylabel('相位 (rad)');
title('不同时延扩展下的信道相位响应对比');
legend('Location', 'best');

cd('D:/Program/MekCraft-Labs/docs-lab/ofdm');
saveas(gcf, 'figures/hw1_delay_mag_phase.png');
fprintf('hw1_delay_mag_phase.png saved.\n');
