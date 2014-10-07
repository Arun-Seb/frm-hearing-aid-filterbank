function audiograms = generate_audiograms()
%GENERATE_AUDIOGRAMS  Create sample audiograms for common hearing loss types.
%
%  Audiogram: hearing threshold level (dB HL) vs frequency (Hz).
%  Standard audiometric frequencies: 125, 250, 500, 1000, 2000, 4000, 8000 Hz.
%  Normal hearing: 0-20 dB HL. Higher = more loss.
%
%  For the filter bank, we convert the audiogram to a GAIN profile:
%    gain(f) = threshold_loss(f)  [dB]
%  (The filter bank must amplify by this amount at each frequency.)
%
%  Returns a struct array with fields:
%    .name        - hearing loss name
%    .freqs       - audiometric frequencies (Hz)
%    .threshold   - hearing threshold levels (dB HL) — higher = more loss
%    .description - short description

    fprintf('\n--- Generating Sample Audiograms ---\n');

    % Standard audiometric frequencies
    std_freqs = [125, 250, 500, 1000, 2000, 4000, 8000];

    %% 1. Presbycusis (Age-related, high-frequency loss)
    %  Gradual sloping loss, worse at high frequencies
    %  Typical for people > 60 years old
    audiograms(1).name        = 'Presbycusis';
    audiograms(1).freqs       = std_freqs;
    audiograms(1).threshold   = [10, 15, 20, 25, 35, 55, 65];
    audiograms(1).description = 'Age-related hearing loss (progressive high-freq loss)';
    audiograms(1).color       = [0.8, 0.2, 0.2];  % red

    %% 2. Sensorineural Hearing Loss (SNHL) — Noise-induced notch at 4kHz
    %  Classic "noise notch" at 4000 Hz from noise exposure
    audiograms(2).name        = 'SNHL (Noise Notch)';
    audiograms(2).freqs       = std_freqs;
    audiograms(2).threshold   = [10, 10, 15, 20, 40, 65, 45];
    audiograms(2).description = 'Sensorineural loss with 4kHz noise notch';
    audiograms(2).color       = [0.2, 0.5, 0.9];  % blue

    %% 3. Bilateral Conductive Hearing Loss
    %  Flat or rising loss, primarily affects low-to-mid frequencies
    %  Due to middle ear problems (fluid, ossicular fixation)
    audiograms(3).name        = 'Bilateral Conductive Loss';
    audiograms(3).freqs       = std_freqs;
    audiograms(3).threshold   = [40, 45, 45, 40, 35, 30, 25];
    audiograms(3).description = 'Flat/rising conductive loss (middle ear origin)';
    audiograms(3).color       = [0.2, 0.7, 0.3];  % green

    %% 4. Meniere's Disease (Low-frequency fluctuating loss)
    %  Characteristic low-frequency sensorineural loss
    audiograms(4).name        = "Meniere's Disease";
    audiograms(4).freqs       = std_freqs;
    audiograms(4).threshold   = [55, 50, 40, 30, 25, 20, 20];
    audiograms(4).description = 'Low-frequency fluctuating sensorineural loss';
    audiograms(4).color       = [0.9, 0.6, 0.1];  % orange

    %% 5. Severe-to-Profound Loss (Flat)
    %  Uniform severe loss across all frequencies
    audiograms(5).name        = 'Severe Flat Loss';
    audiograms(5).freqs       = std_freqs;
    audiograms(5).threshold   = [65, 70, 70, 70, 70, 75, 75];
    audiograms(5).description = 'Severe uniform hearing loss across all frequencies';
    audiograms(5).color       = [0.6, 0.1, 0.7];  % purple

    %% 6. Cookie-bite (Mid-frequency loss)
    %  Greater loss in mid-frequencies, better at high and low ends
    audiograms(6).name        = 'Cookie-bite (Mid-freq)';
    audiograms(6).freqs       = std_freqs;
    audiograms(6).threshold   = [20, 35, 55, 60, 55, 35, 25];
    audiograms(6).description = 'U-shaped mid-frequency sensorineural loss';
    audiograms(6).color       = [0.5, 0.5, 0.0];  % olive

    %% Print summary
    fprintf('  Generated %d audiograms:\n', length(audiograms));
    for k = 1 : length(audiograms)
        fprintf('    %d. %-30s — %s\n', k, audiograms(k).name, audiograms(k).description);
    end

    %% Plot all audiograms
    fig = figure('Name', 'Sample Audiograms', 'Position', [200, 200, 900, 550]);

    hold on;
    for k = 1 : length(audiograms)
        plot(audiograms(k).freqs, audiograms(k).threshold, ...
             '-o', 'Color', audiograms(k).color, ...
             'LineWidth', 2, 'MarkerSize', 7, 'MarkerFaceColor', audiograms(k).color);
    end
    hold off;

    % Audiogram convention: 0 dB at top, higher threshold = more loss
    set(gca, 'YDir', 'reverse');
    set(gca, 'XScale', 'log');
    xticks(std_freqs);
    xticklabels({'125','250','500','1k','2k','4k','8k'});
    ylim([-10, 90]);
    yticks(-10:10:90);
    grid on; grid minor;
    xlabel('Frequency (Hz)', 'FontSize', 12);
    ylabel('Hearing Level (dB HL)', 'FontSize', 12);
    title('Sample Audiograms — Common Hearing Loss Patterns', 'FontSize', 13);
    legend({audiograms.name}, 'Location', 'southwest', 'FontSize', 9);

    % Reference line for normal hearing upper boundary
    xline_vals = [125, 8000];
    line(xline_vals, [20, 20], 'Color', [0.5 0.5 0.5], ...
         'LineStyle', '--', 'LineWidth', 1, 'DisplayName', 'Normal limit (20 dB)');

    saveas(fig, 'Sample_Audiograms.png');
    fprintf('  Audiogram plot saved.\n');
end
