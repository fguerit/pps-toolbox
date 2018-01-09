%% Script to get list of possible amplitude values for AB stimulus
% It prints a PDF of the figure

stim = PulseTrainBEDCS118;

% One of the parameter that changes possible amplitude values is the
% asymmetry of the pulse shape (the more asymmetric, the less possible
% steps in amplitudes)
%
% The step calculation is based on oscilloscope recordings performed with a HiRes90K implant-in-the-box,
% see "oscilloscope_values_AB.pdf"

stim.ratio_asymmetry = 8;

%% Calculate and plot possible values

desired_amplitudes_vec = 0:2040;
actual_amplitudes_vec = zeros(size(desired_amplitudes_vec));

for idx = 1:length(desired_amplitudes_vec)
    stim.level = desired_amplitudes_vec(idx);
    actual_amplitudes_vec(idx) = stim.actual_level;
end

desired_amplitudes_dBuA_vec = 20*log10(desired_amplitudes_vec);
actual_amplitudes_dBuA_vec = 20*log10(actual_amplitudes_vec);
actual_steps_amplitude = diff(actual_amplitudes_vec);
actual_steps_dB = diff(actual_amplitudes_dBuA_vec);

actual_steps_amplitude(actual_steps_amplitude == 0) = NaN;
actual_steps_dB(actual_steps_dB == 0) = NaN;

figure
subplot(221)
plot(desired_amplitudes_vec, actual_amplitudes_vec, 'linewidth', 2)
xlim([0 2040])
ylim([0 2040])
xlabel('Desired amplitudes (uA)', 'fontsize', 12)
ylabel('Actual amplitudes (uA)', 'fontsize', 12)
title(['Asymmetry Ratio: ' num2str(stim.ratio_asymmetry)], 'fontsize', 14)
subplot(223)
plot(desired_amplitudes_dBuA_vec, actual_amplitudes_dBuA_vec, 'linewidth', 2)
xlim([0 67])
ylim([0 67])
xlabel('Desired amplitudes (dB re 1 uA)', 'fontsize', 12)
ylabel('Actual amplitudes (dB re 1 uA)', 'fontsize', 12)
subplot(222)
plot(desired_amplitudes_vec(2:end), actual_steps_amplitude, '.', 'linewidth', 2)
xlim([0 2040])
ylim([0 max(actual_steps_amplitude)+5])
xlabel('Desired amplitudes (uA)', 'fontsize', 12)
ylabel('Step size (uA)', 'fontsize', 12)
subplot(224)
plot(desired_amplitudes_dBuA_vec(2:end), actual_steps_dB, '.', 'linewidth', 2)
xlim([0 67])
xlabel('Desired amplitudes (dB re 1 uA)', 'fontsize', 12)
ylabel('Step size (dB re 1 uA)', 'fontsize', 12)

%% Save figure as pdf

set(gcf,'PaperType','a4')
set(gcf,'PaperOrientation','landscape')
set(gcf,'PaperUnits','Normalized')
set(gcf,'PaperPosition',[-0.04 0 1.10 1])
saveas(gcf, ['possible_level_values_AB_ratio_' num2str(stim.ratio_asymmetry) '.pdf'])