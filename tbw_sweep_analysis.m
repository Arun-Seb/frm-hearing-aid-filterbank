%% =========================================================
%  Transition Bandwidth Sweep Analysis
%  Reproduces Table II from both papers:
%    Sweep normalized TBW from 0.025 to 0.20,
%    compute matching error vs filter length.
%
%  Run AFTER main_filterbank.m (uses same audiogram setup).
%  Or run standalone — it regenerates audiograms internally.
% =========================================================

clear; clc; close all;

fprintf('=====================================================\n');
fprintf('  Transition Bandwidth Sweep — Reproducing Table II\n');
fprintf('=====================================================\n\n');

NUM_BANDS = input('Select 10 or 12 band filter bank: ');
if ~ismember(NUM_BANDS, [10, 12]), NUM_BANDS = 12; end

Fs      = 16000;
MF_len  = 11;     % fixed masking filter length (from papers)

% Normalized transition bandwidths to sweep (Table II values)
tbw_vals = [0.20, 0.175, 0.15, 0.125, 0.10, 0.05, 0.025];

% Audiogram: presbycusis (primary test case in papers)
std_freqs        = [125, 250, 500, 1000, 2000, 4000, 8000];
presby_threshold = [10, 15, 20, 25, 35, 55, 65];

fprintf('  Sweeping %d transition bandwidth values...\n\n', length(tbw_vals));
fprintf('  %-12s %-20s %-20s\n', 'Norm TBW', 'Total Length H+MF', 'Max Match Error (dB)');
fprintf('  %s\n', repmat('-', 1, 55));

results = zeros(length(tbw_vals), 3);  % [tbw, total_len, max_error]

for idx = 1 : length(tbw_vals)
    tbw = tbw_vals(idx);

    % Compute filter length from transition bandwidth
    % Approx: N ≈ 3.3 / tbw (Parks-McClellan estimate)
    H_len = round(3.3 / tbw / 2) * 2 + 1;
    H_len = max(H_len, 11);

    total_len = H_len + MF_len;

    % Design filters
    [Hz, MFz] = design_halfband_filters(H_len, MF_len, tbw);

    % Build filter bank
    [~, freq_axis, H_bank] = build_filterbank(Hz, MFz, NUM_BANDS, Fs);

    % Audiogram matching (presbycusis only for speed)
    freq_Hz    = freq_axis * Fs;
    valid      = (freq_Hz >= 125) & (freq_Hz <= 8000);
    freq_valid = freq_Hz(valid);

    target_dB  = interp1(std_freqs, presby_threshold, freq_valid, 'pchip', 'extrap');
    target_dB  = max(target_dB, 0);
    target_lin = 10 .^ (target_dB / 20);

    H_valid    = H_bank(:, valid)';
    try
        gains = lsqnonneg(H_valid, target_lin(:));
    catch
        gains = max(H_valid \ target_lin(:), 0);
    end

    fitted_lin = H_valid * gains;
    fitted_dB  = 20 * log10(max(fitted_lin, 1e-10));
    max_err    = max(abs(fitted_dB - target_dB(:)));

    results(idx, :) = [tbw, total_len, max_err];
    fprintf('  %-12.3f %-20d %-20.2f\n', tbw, total_len, max_err);
end

%% ---- Plot: Reproduction of Table II / Figure from papers ----
fig = figure('Name', 'TBW Sweep — Match Error vs Filter Length', 'Position', [100, 100, 850, 500]);

yyaxis left;
plot(results(:,1), results(:,3), 'bo-', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'b');
ylabel('Max Matching Error (dB)', 'FontSize', 11);
ylim([0, max(results(:,3)) * 1.3]);

yyaxis right;
plot(results(:,1), results(:,2), 'rs--', 'LineWidth', 2, 'MarkerSize', 8, 'MarkerFaceColor', 'r');
ylabel('Total Filter Length (H(z) + MF(z))', 'FontSize', 11);
set(gca, 'XDir', 'reverse');   % wider TBW = simpler, matches paper table order

grid on;
xlabel('Normalized Transition Bandwidth', 'FontSize', 11);
title(sprintf('%d-Band FRM Filter Bank — TBW Sweep (Presbycusis Audiogram)', NUM_BANDS), ...
      'FontSize', 12);
legend({'Max Match Error (dB)', 'Total Filter Length'}, 'Location', 'northwest');

% Highlight optimal point (0.15 from paper)
[~, opt_idx] = min(results(:,3));
hold on;
yyaxis left;
plot(results(opt_idx,1), results(opt_idx,3), 'k*', 'MarkerSize', 14, 'LineWidth', 2, ...
     'DisplayName', sprintf('Optimal TBW=%.3f (Paper)', results(opt_idx,1)));
hold off;
legend({'Max Match Error', 'Total Filter Length', 'Optimal point'}, 'Location', 'northwest');

saveas(fig, sprintf('TBW_Sweep_%dBand.png', NUM_BANDS));

fprintf('\n  Optimal TBW: %.3f | Length: %d | Max Error: %.2f dB\n', ...
        results(opt_idx,1), results(opt_idx,2), results(opt_idx,3));
fprintf('  (Paper reports TBW=0.15, length=30, max error ~1.4 dB for 12-band)\n');
fprintf('\n  Plot saved: TBW_Sweep_%dBand.png\n', NUM_BANDS);
