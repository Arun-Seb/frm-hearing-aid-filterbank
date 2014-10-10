function plot_filterbank(H_bank, freq_axis, Fs, NUM_BANDS)
%PLOT_FILTERBANK  Plot the magnitude responses of all subbands.
%
%  Inputs:
%    H_bank   - [NUM_BANDS x NFFT/2+1] magnitude response matrix
%    freq_axis- normalized frequency axis (0..0.5)
%    Fs       - sampling frequency (Hz)
%    NUM_BANDS- number of subbands

    freq_Hz = freq_axis * Fs;  % convert to Hz

    %% ---- Plot 1: All subbands in dB (normalized frequency) ----
    fig1 = figure('Name', sprintf('%d-Band FRM Filter Bank (Normalized Freq)', NUM_BANDS), ...
                  'Position', [50, 100, 900, 500]);

    colors = lines(NUM_BANDS);
    hold on;
    for i = 1 : NUM_BANDS
        mag_dB = 20 * log10(max(H_bank(i,:), 1e-10));
        plot(freq_axis, mag_dB, 'Color', colors(i,:), 'LineWidth', 1.5);
    end
    hold off;
    grid on;
    xlabel('Normalized Frequency (×\pi rad/sample)');
    ylabel('Magnitude (dB)');
    title(sprintf('Magnitude Response of %d-Band Non-Uniform FRM Filter Bank', NUM_BANDS));
    ylim([-100, 5]);
    xlim([0, 0.5]);
    legend(arrayfun(@(i) sprintf('B_%d', i), 1:NUM_BANDS, 'UniformOutput', false), ...
           'Location', 'eastoutside', 'FontSize', 7);

    saveas(fig1, sprintf('FilterBank_%dBand_Magnitude_dB.png', NUM_BANDS));

    %% ---- Plot 2: All subbands in linear scale ----
    fig2 = figure('Name', sprintf('%d-Band FRM Filter Bank (Linear)', NUM_BANDS), ...
                  'Position', [100, 100, 900, 500]);

    hold on;
    for i = 1 : NUM_BANDS
        plot(freq_axis, H_bank(i,:), 'Color', colors(i,:), 'LineWidth', 1.5);
    end
    hold off;
    grid on;
    xlabel('Normalized Frequency (×\pi rad/sample)');
    ylabel('Magnitude');
    title(sprintf('Linear Magnitude Response — %d-Band FRM Filter Bank', NUM_BANDS));
    xlim([0, 0.5]);
    ylim([0, 1.2]);

    saveas(fig2, sprintf('FilterBank_%dBand_Magnitude_Linear.png', NUM_BANDS));

    %% ---- Plot 3: Frequency axis in Hz ----
    fig3 = figure('Name', sprintf('%d-Band FRM Filter Bank (Hz)', NUM_BANDS), ...
                  'Position', [150, 100, 900, 500]);

    hold on;
    for i = 1 : NUM_BANDS
        plot(freq_Hz, H_bank(i,:), 'Color', colors(i,:), 'LineWidth', 1.5);
    end
    hold off;
    grid on;
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    title(sprintf('%d-Band Non-Uniform FRM Filter Bank (Fs = %d Hz)', NUM_BANDS, Fs));
    xlim([0, Fs/2]);
    ylim([0, 1.2]);
    legend(arrayfun(@(i) sprintf('Band %d', i), 1:NUM_BANDS, 'UniformOutput', false), ...
           'Location', 'eastoutside', 'FontSize', 7);

    saveas(fig3, sprintf('FilterBank_%dBand_Hz.png', NUM_BANDS));

    fprintf('\n  Filter bank plots saved.\n');
end
