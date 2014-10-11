%% =========================================================
%  FRM Non-Uniform Digital Filter Bank for Hearing Aid
%  Based on:
%    [1] "A Low Complex 10-Band Non-uniform FIR Digital Filter Bank
%         Using FRM Technique For Hearing Aid" (ICCSC 2014)
%    [2] "A Low Complex 12-Band Non-uniform FIR Digital Filter Bank
%         Using FRM Technique For Hearing Aid" (IJRITCC, Sep 2014)
%
%  Authors of papers: Arun Sebastian, James T. G.
%  MATLAB Implementation: Reproduced for educational/research purposes
%
%  Usage:
%    Run this script. Select 10-band or 12-band mode interactively,
%    or set NUM_BANDS at the top before running.
% =========================================================

clear; clc; close all;

fprintf('=====================================================\n');
fprintf('  FRM Non-Uniform Filter Bank for Hearing Aid\n');
fprintf('  10-Band and 12-Band Implementation\n');
fprintf('=====================================================\n\n');

%% --- USER SELECTION: 10 or 12 band ---
choice = input('Select filter bank mode:\n  Enter 10 for 10-band\n  Enter 12 for 12-band\n  Your choice: ');
if ~ismember(choice, [10, 12])
    warning('Invalid choice. Defaulting to 12-band.');
    choice = 12;
end
NUM_BANDS = choice;
fprintf('\n>> Running %d-band FRM filter bank...\n\n', NUM_BANDS);

%% --- Prototype Filter Design Parameters (from papers) ---
Fs          = 16000;      % Sampling frequency (Hz)
Fp          = 4000;       % Pass band frequency (Hz)
Rp          = 0.0001;     % Max passband ripple
Rs          = 80;         % Min stopband attenuation (dB)
norm_tbw    = 0.15;       % Optimal normalized transition bandwidth (from paper)

% Compute filter lengths from transition bandwidth
% H(z): prototype half-band filter length
% MF(z): masking filter length (fixed at 11 from papers)
MF_len  = 11;            % masking filter length (fixed, paper)
H_len   = round(3.3 / norm_tbw / 2) * 2 + 1;  % odd-length linear phase
H_len   = max(H_len, 19); % paper uses 19 for tbw=0.15

fprintf('--- Filter Design Parameters ---\n');
fprintf('  Sampling frequency  : %d Hz\n', Fs);
fprintf('  Passband frequency  : %d Hz\n', Fp);
fprintf('  Normalized TBW      : %.3f\n', norm_tbw);
fprintf('  H(z) filter length  : %d\n', H_len);
fprintf('  MF(z) filter length : %d\n', MF_len);

%% --- Design Prototype Half-Band Filters ---
[Hz, MFz] = design_halfband_filters(H_len, MF_len, norm_tbw);

%% --- Build the Filter Bank ---
[subbands, freq_axis, H_bank] = build_filterbank(Hz, MFz, NUM_BANDS, Fs);

%% --- Plot Filter Bank Magnitude Response ---
plot_filterbank(H_bank, freq_axis, Fs, NUM_BANDS);

%% --- Generate Sample Audiograms ---
audiograms = generate_audiograms();

%% --- Audiogram Matching ---
perform_audiogram_matching(H_bank, freq_axis, Fs, audiograms, NUM_BANDS);

fprintf('\n>> All done. Figures saved.\n');
