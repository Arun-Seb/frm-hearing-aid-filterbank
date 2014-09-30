%% =========================================================
%  utils_frm.m — Utility / helper functions for FRM filter bank
%
%  Functions in this file:
%    frm_multiplier_count(Hz, MFz)  - count shared multipliers
%    frm_stopband_attenuation(Hz)   - measure stopband attenuation
%    print_filter_info(Hz, MFz)     - print filter coefficient tables
%    compare_10vs12(Fs)             - side-by-side comparison
% =========================================================

function count = frm_multiplier_count(Hz, MFz)
%FRM_MULTIPLIER_COUNT  Estimate number of multipliers needed.
%
%  In linear-phase FIR, symmetric coefficients share multipliers.
%  In half-band filters, odd-indexed coefficients are zero.
%  => Effective multipliers ≈ ceil((non-zero unique coefficients) / 2)
%
%  The paper claims 10 multipliers for the complete 12-band bank.

    tol = 1e-6;

    % H(z): half-band — only even-indexed non-zero, symmetric
    Hz_nz   = Hz(abs(Hz) > tol);
    n_H     = ceil(length(Hz_nz) / 2);  % symmetry halves the count

    % MF(z): regular symmetric FIR
    MFz_nz  = MFz(abs(MFz) > tol);
    n_MF    = ceil(length(MFz_nz) / 2);

    % Shared multipliers across interpolated versions (same coefficients)
    count = n_H + n_MF;

    fprintf('\n--- Multiplier Count Estimate ---\n');
    fprintf('  H(z)  unique multipliers : %d\n', n_H);
    fprintf('  MF(z) unique multipliers : %d\n', n_MF);
    fprintf('  Total                    : %d\n', count);
    fprintf('  (Paper target: 10 multipliers)\n');
end


function atten_dB = frm_stopband_attenuation(Hz)
%FRM_STOPBAND_ATTENUATION  Measure the stopband attenuation of H(z).

    NFFT    = 8192;
    H_full  = abs(freqz(Hz, 1, NFFT, 'whole'));
    H_half  = H_full(1 : NFFT/2 + 1);
    freq_n  = (0 : NFFT/2) / NFFT;

    % Stopband starts at ~0.6 normalized (rough heuristic for half-band)
    sb_idx  = freq_n > 0.4;
    atten_dB = -20 * log10(max(H_half(sb_idx)));

    fprintf('  Stopband attenuation of H(z): %.1f dB\n', atten_dB);
    fprintf('  (Paper target: 80 dB)\n');
end


function print_filter_info(Hz, MFz)
%PRINT_FILTER_INFO  Print key properties of the prototype filters.

    fprintf('\n--- Prototype Filter Information ---\n');

    % H(z)
    N_H   = length(Hz);
    nz_H  = sum(abs(Hz) > 1e-6);
    fprintf('  H(z) length       : %d\n', N_H);
    fprintf('  H(z) non-zero     : %d\n', nz_H);
    fprintf('  H(z) center coeff : %.6f\n', Hz(ceil(N_H/2)));

    % MF(z)
    N_MF  = length(MFz);
    nz_MF = sum(abs(MFz) > 1e-6);
    fprintf('  MF(z) length      : %d\n', N_MF);
    fprintf('  MF(z) non-zero    : %d\n', nz_MF);

    fprintf('\n  H(z) coefficients:\n    ');
    fprintf('%8.5f  ', Hz);
    fprintf('\n\n  MF(z) coefficients:\n    ');
    fprintf('%8.5f  ', MFz);
    fprintf('\n');
end


function compare_10vs12(Fs)
%COMPARE_10VS12  Run both filter banks and display side-by-side comparison.

    fprintf('\n=====================================================\n');
    fprintf('  Side-by-Side Comparison: 10-Band vs 12-Band\n');
    fprintf('=====================================================\n');

    MF_len   = 11;
    norm_tbw = 0.15;
    H_len    = 19;

    [Hz, MFz] = design_halfband_filters(H_len, MF_len, norm_tbw);

    [~, freq_axis, H_10] = build_filterbank(Hz, MFz, 10, Fs);
    [~, ~,         H_12] = build_filterbank(Hz, MFz, 12, Fs);

    freq_Hz = freq_axis * Fs;

    fig = figure('Name', '10 vs 12 Band Comparison', 'Position', [100, 100, 1200, 550]);

    subplot(1,2,1);
    hold on;
    for i = 1 : 10
        plot(freq_Hz, H_10(i,:), 'LineWidth', 1.5);
    end
    hold off; grid on;
    xlabel('Frequency (Hz)'); ylabel('Magnitude');
    title('10-Band FRM Filter Bank');
    xlim([0, Fs/2]); ylim([0, 1.2]);

    subplot(1,2,2);
    hold on;
    for i = 1 : 12
        plot(freq_Hz, H_12(i,:), 'LineWidth', 1.5);
    end
    hold off; grid on;
    xlabel('Frequency (Hz)'); ylabel('Magnitude');
    title('12-Band FRM Filter Bank');
    xlim([0, Fs/2]); ylim([0, 1.2]);

    sgtitle('10-Band vs 12-Band Non-Uniform FRM Filter Bank', 'FontSize', 13);
    saveas(fig, 'Comparison_10vs12_Band.png');
    fprintf('  Comparison plot saved.\n');
end
