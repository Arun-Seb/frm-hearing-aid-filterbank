function perform_audiogram_matching(H_bank, freq_axis, Fs, audiograms, NUM_BANDS)
%PERFORM_AUDIOGRAM_MATCHING  Match filter bank response to audiograms.
%
%  Method:
%  1. For each audiogram, interpolate the hearing threshold onto the
%     filter bank's frequency grid (normalized 0..0.5).
%  2. Compute optimal subband gains gi that minimise:
%       E(f) = |Sum_i [gi * |Hi(f)|] - A(f)|
%     where A(f) is the target audiogram gain profile (dB).
%  3. The combined (fitted) response: R(f) = 20*log10(Sum_i [gi * |Hi(f)|])
%  4. Matching error: err(f) = R(f) - A_dB(f)
%  5. Max and average (RMS) matching error reported.
%
%  Inputs:
%    H_bank    - [NUM_BANDS x NFFT/2+1] filter magnitude responses
%    freq_axis - normalized freq vector (0..0.5)
%    Fs        - sampling frequency
%    audiograms- struct array from generate_audiograms()
%    NUM_BANDS - 10 or 12

    fprintf('\n--- Audiogram Matching ---\n');

    num_ag  = length(audiograms);
    freq_Hz = freq_axis * Fs;

    % Only use frequencies in audible speech range: 125 Hz to 8000 Hz
    f_lo  = 125;
    f_hi  = 8000;
    valid = (freq_Hz >= f_lo) & (freq_Hz <= f_hi);
    freq_valid = freq_Hz(valid);

    % Summary table storage
    max_errors = zeros(num_ag, 1);
    avg_errors = zeros(num_ag, 1);
    rms_errors = zeros(num_ag, 1);

    % Create figure for all audiogram matches
    fig_all = figure('Name', sprintf('%d-Band: All Audiogram Matches', NUM_BANDS), ...
                     'Position', [50, 50, 1400, 900]);

    ncols = 3;
    nrows = ceil(num_ag / ncols);

    for k = 1 : num_ag
        ag = audiograms(k);

        %% ---- Step 1: Interpolate audiogram onto filter freq grid ----
        % Audiogram threshold in dB HL → target gain in dB
        % (we want to amplify by threshold amount to compensate)
        target_gain_dB = interp1(ag.freqs, ag.threshold, freq_valid, 'pchip', 'extrap');
        target_gain_dB = max(target_gain_dB, 0);  % gains are non-negative

        % Convert target gain to linear
        target_lin = 10 .^ (target_gain_dB / 20);

        %% ---- Step 2: Extract valid-range subband magnitudes ----
        H_valid = H_bank(:, valid);    % [NUM_BANDS x N_valid]

        %% ---- Step 3: Solve for optimal subband gains ----
        % Least-squares: H_valid' * g ≈ target_lin
        % H_matrix [N_valid x NUM_BANDS], solve for g [NUM_BANDS x 1]
        H_mat = H_valid';              % [N_valid x NUM_BANDS]

        % Constrained non-negative least squares
        opts_lsq = optimset('Display', 'off');
        try
            gains = lsqnonneg(H_mat, target_lin(:));
        catch
            % fallback: unconstrained, clip to 0
            gains = max(H_mat \ target_lin(:), 0);
        end

        %% ---- Step 4: Compute fitted filter bank response ----
        fitted_lin = H_mat * gains;           % [N_valid x 1]
        fitted_dB  = 20 * log10(max(fitted_lin, 1e-10));
        target_gain_dB = target_gain_dB(:);

        %% ---- Step 5: Compute matching errors ----
        error_dB       = fitted_dB - target_gain_dB;
        max_err        = max(abs(error_dB));
        avg_err        = mean(abs(error_dB));
        rms_err        = sqrt(mean(error_dB .^ 2));

        max_errors(k)  = max_err;
        avg_errors(k)  = avg_err;
        rms_errors(k)  = rms_err;

        fprintf('  [%d] %-30s | Max err: %5.2f dB | Avg err: %5.2f dB | RMS: %5.2f dB\n', ...
                k, ag.name, max_err, avg_err, rms_err);

        %% ---- Plot individual match ----
        subplot(nrows, ncols, k);
        hold on;
        plot(freq_valid, target_gain_dB, 'b-',  'LineWidth', 2.5, 'DisplayName', 'Audiogram');
        plot(freq_valid, fitted_dB,      'r--', 'LineWidth', 2,   'DisplayName', 'Filter Response');
        hold off;
        set(gca, 'XScale', 'log');
        xticks([125, 250, 500, 1000, 2000, 4000, 8000]);
        xticklabels({'125','250','500','1k','2k','4k','8k'});
        grid on;
        xlabel('Frequency (Hz)', 'FontSize', 8);
        ylabel('Gain (dB)', 'FontSize', 8);
        title(sprintf('%s\nMax err=%.1f dB, RMS=%.1f dB', ag.name, max_err, rms_err), ...
              'FontSize', 9);
        legend('FontSize', 7, 'Location', 'best');
        ylim([0, max(target_gain_dB) * 1.3 + 10]);
    end

    sgtitle(sprintf('%d-Band FRM Filter Bank — Audiogram Matching Results', NUM_BANDS), ...
            'FontSize', 13, 'FontWeight', 'bold');

    saveas(fig_all, sprintf('AudiogramMatching_%dBand_All.png', NUM_BANDS));

    %% ---- Plot matching errors for all audiograms ----
    plot_matching_errors(H_bank, freq_axis, Fs, audiograms, NUM_BANDS);

    %% ---- Plot summary bar chart ----
    fig_bar = figure('Name', 'Matching Error Summary', 'Position', [200, 100, 800, 450]);

    names    = {audiograms.name};
    x        = 1 : num_ag;
    bar_data = [max_errors, avg_errors, rms_errors];
    br       = bar(x, bar_data, 'grouped');

    br(1).FaceColor = [0.85, 0.33, 0.10];
    br(2).FaceColor = [0.00, 0.45, 0.74];
    br(3).FaceColor = [0.47, 0.67, 0.19];

    set(gca, 'XTick', x, 'XTickLabel', names, 'XTickLabelRotation', 20);
    grid on; grid minor;
    ylabel('Matching Error (dB)', 'FontSize', 11);
    title(sprintf('%d-Band FRM Filter Bank — Matching Error Summary', NUM_BANDS), 'FontSize', 12);
    legend('Max Error', 'Mean Absolute Error', 'RMS Error', 'Location', 'northwest');

    % Print overall summary
    fprintf('\n  ---- Summary ----\n');
    fprintf('  Overall max error : %.2f dB\n', max(max_errors));
    fprintf('  Overall avg error : %.2f dB\n', mean(avg_errors));
    fprintf('  Overall RMS error : %.2f dB\n', mean(rms_errors));

    saveas(fig_bar, sprintf('MatchingError_Summary_%dBand.png', NUM_BANDS));
    fprintf('  Audiogram matching plots saved.\n');

    %% ---- Print comparison table (paper Table III style) ----
    fprintf('\n  +------------------------------------+------------------+------------------+------------------+\n');
    fprintf('  | Hearing Loss Type                  | Max Error (dB)   | Avg Error (dB)   | RMS Error (dB)   |\n');
    fprintf('  +------------------------------------+------------------+------------------+------------------+\n');
    for k = 1 : num_ag
        fprintf('  | %-34s | %16.2f | %16.2f | %16.2f |\n', ...
                audiograms(k).name, max_errors(k), avg_errors(k), rms_errors(k));
    end
    fprintf('  +------------------------------------+------------------+------------------+------------------+\n');
    fprintf('  | OVERALL                            | %16.2f | %16.2f | %16.2f |\n', ...
            max(max_errors), mean(avg_errors), mean(rms_errors));
    fprintf('  +------------------------------------+------------------+------------------+------------------+\n\n');
end


function plot_matching_errors(H_bank, freq_axis, Fs, audiograms, NUM_BANDS)
%PLOT_MATCHING_ERRORS  Plot the error curves for all audiograms (as in Fig.13 of paper).

    num_ag     = length(audiograms);
    freq_Hz    = freq_axis * Fs;
    valid      = (freq_Hz >= 125) & (freq_Hz <= 8000);
    freq_valid = freq_Hz(valid);
    H_valid    = H_bank(:, valid)';   % [N_valid x NUM_BANDS]

    fig = figure('Name', 'Audiogram Matching Error Curves', 'Position', [300, 200, 900, 500]);
    hold on;

    styles = {'-', '--', ':', '-.', '-', '--'};
    for k = 1 : num_ag
        ag = audiograms(k);
        target_gain_dB = interp1(ag.freqs, ag.threshold, freq_valid, 'pchip', 'extrap');
        target_gain_dB = max(target_gain_dB, 0);
        target_lin     = 10 .^ (target_gain_dB / 20);
        try
            gains = lsqnonneg(H_valid, target_lin(:));
        catch
            gains = max(H_valid \ target_lin(:), 0);
        end
        fitted_lin     = H_valid * gains;
        fitted_dB      = 20 * log10(max(fitted_lin, 1e-10));
        error_dB       = fitted_dB - target_gain_dB(:);

        plot(freq_valid, error_dB, styles{k}, ...
             'Color', ag.color, 'LineWidth', 1.5, 'DisplayName', ag.name);
    end

    yline(0, 'k-', 'LineWidth', 1.2);
    yline(2,  'k:', 'LineWidth', 0.8);
    yline(-2, 'k:', 'LineWidth', 0.8);
    hold off;

    set(gca, 'XScale', 'log');
    xticks([125, 250, 500, 1000, 2000, 4000, 8000]);
    xticklabels({'125','250','500','1k','2k','4k','8k'});
    grid on;
    xlabel('Frequency (Hz)', 'FontSize', 11);
    ylabel('Matching Error (dB)', 'FontSize', 11);
    title(sprintf('%d-Band FRM Filter Bank — Audiogram Fitting Error', NUM_BANDS), 'FontSize', 12);
    legend('Location', 'eastoutside', 'FontSize', 9);
    ylim([-5, 5]);

    saveas(fig, sprintf('MatchingError_Curves_%dBand.png', NUM_BANDS));
end
