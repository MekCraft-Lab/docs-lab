clear; clc; close all;

N_fft = 1024;
f = linspace(0, 1, N_fft);
tau = 5;
alphas = [0.2, 0.5, 0.8, 1.0];
colors = {'#77AC30', '#0072BD', '#D95319', '#A2142F'};

figure('Position', [100, 100, 800, 400]);
hold on;

for i = 1:length(alphas)
    a = alphas(i);
    h = zeros(1, tau + 1);
    h(1) = 1;
    h(tau + 1) = a;

    H_mag = abs(fft(h, N_fft));
    plot(f, H_mag, 'Color', colors{i}, 'LineWidth', 1.5, ...
         'DisplayName', ['Amplitude \alpha = ', num2str(a)]);
end

yline(0, '--k', 'HandleVisibility', 'off');
grid on; xlabel('归一化频率'); ylabel('幅度 |H(f)|');
title('不同反射径幅度对信道衰落深度的影响');
legend('Location', 'northeast');

cd('D:/Program/MekCraft-Labs/docs-lab/ofdm');
saveas(gcf, 'figures/hw1_amplitude.png');
fprintf('hw1_amplitude.png saved.\n');
