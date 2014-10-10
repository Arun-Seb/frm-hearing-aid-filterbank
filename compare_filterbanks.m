%% =========================================================
%  compare_filterbanks.m
%  Runs BOTH 10-band and 12-band filter banks and produces
%  a comprehensive side-by-side comparison.
%
%  Reproduces comparison of:
%    - Subband structure
%    - Audiogram matching for all 6 test audiograms
%    - Error statistics table
% =========================================================

clear; clc; close all;

fprintf('=====================================================\n');
fprintf('  10-Band vs 12-Band FRM Filter Bank Comparison\n');
fprintf('=====================================================\n\n');

Fs       = 16000;
MF_len   = 11;
norm_tbw = 0.15;
H_len    = 19;

%% --- Design shared prototype filters ---
[Hz, MFz] = design_halfband_filters(H_len, MF_len, norm_tbw);

%% --- Build both filter banks ---
fprintf('\n>> Building 10-band filter bank...\n');
[~, freq_axis, H_10] = build_filterbank(Hz, MFz, 10, Fs);

fprintf('\n>> Building 12-band filter bank...\n');
[~, ~, H_12] = build_filterbank(Hz, MFz, 12, Fs);

%% --- Generate audiograms ---
audiograms = generate_audiograms();

%% --- Filter bank multiplier analysis ---
frm_multiplier_count(Hz, MFz);
frm_stopband_attenuation(Hz);
print_filter_info(Hz, MFz);

%% --- Side-by-side filter bank plots (dB) ---
freq_Hz = freq_axis * Fs;

fig1 = figure('Name', '10 vs 12 Band — dB Response', 'Position', [50, 100, 1300, 550]);
subplot(1,2,1);
hold on;
cmap = lines(10);
for i = 1:10
    mag = 20*log10(max(H_10(i,:),1e-10));
    plot(freq_Hz, mag, 'Color', cmap(i,:), 'LineWidth', 1.5);
end
hold off; grid on;
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('10-Band FRM Filter Bank'); xlim([0,8000]); ylim([-100,5]);

subplot(1,2,2);
hold on;
cmap12 = lines(12);
for i = 1:12
    mag = 20*log10(max(H_12(i,:),1e-10));
    plot(freq_Hz, mag, 'Color', cmap12(i,:), 'LineWidth', 1.5);
end
hold off; grid on;
xlabel('Frequency (Hz)'); ylabel('Magnitude (dB)');
title('12-Band FRM Filter Bank'); xlim([0,8000]); ylim([-100,5]);
sgtitle('Non-Uniform FRM Filter Bank — Magnitude Response (dB)', 'FontSize', 13);

saveas(fig1, 'Comparison_10vs12_dB.png');

%% --- Audiogram matching comparison ---
fprintf('\n=====================================================\n');
fprintf('  Audiogram Matching: 10-Band\n');
perform_audiogram_matching(H_10, freq_axis, Fs, audiograms, 10);

fprintf('\n  Audiogram Matching: 12-Band\n');
perform_audiogram_matching(H_12, freq_axis, Fs, audiograms, 12);

fprintf('\n>> All comparison plots saved.\n');
