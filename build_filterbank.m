function [subbands, freq_axis, H_bank] = build_filterbank(Hz, MFz, NUM_BANDS, Fs)
%BUILD_FILTERBANK  Construct the FRM non-uniform filter bank.
%
%  Implements the tree-structured filter bank from the papers.
%  Each subband is formed by cascading interpolated versions of H(z) and MF(z).
%
%  Transfer functions (10-band case, Table I of paper):
%    P1  = H(z^16) MF(z^8) MF(z^4) MF(z^2) MF(z)
%    P2  = H(z^8)  MF(z^4) MF(z^2) MF(z)
%    P3  = H(z^4)  MF(z^2) MF(z)
%    P4  = H(z^2)  MF(z)
%    P5  = H(z)
%    P6  = Hc(z)
%    P7  = H(z^2)  MFc(z)
%    P8  = H(z^4)  MF(z^2) MFc(z)
%    P9  = H(z^8)  MF(z^4) MF(z^2) MFc(z)
%    P10 = H(z^16) MF(z^8) MF(z^4) MF(z^2) MFc(z)
%
%  For 12-band, two extra bands are added (P1/P12 use z^32 interpolation).
%
%  The FRM complementary filter:
%    MFc(z) = z^{-(N-1)/2} - MF(z)   [equation (2) in paper]
%    Hc(z)  = z^{-(N-1)/2} - H(z)
%
%  Subband outputs (lower half, eq 3):
%    B1(z) = P1(z)
%    Bi(z) = Pi(z) - P_{i-1}(z),  i = 2..5  (10-band) or i=2..6 (12-band)
%
%  Subband outputs (upper half, eq 4):
%    B_last(z) = P_last(z)
%    Bi(z) = Pi(z) - P_{i+1}(z),  i = 6..9 (10-band) or i=7..11 (12-band)
%
%  Inputs:
%    Hz       - prototype H(z) coefficients
%    MFz      - prototype MF(z) coefficients
%    NUM_BANDS- 10 or 12
%    Fs       - sampling frequency (Hz)
%
%  Outputs:
%    subbands - struct with subband info
%    freq_axis- normalized frequency vector (0..0.5)
%    H_bank   - matrix [NUM_BANDS x NFFT] of subband magnitude responses

    fprintf('\n--- Building %d-band FRM Filter Bank ---\n', NUM_BANDS);

    NFFT     = 4096;
    freq_axis = (0 : NFFT/2) / NFFT;  % normalised 0..0.5

    %% ---- Compute DTFT of prototype filters ----
    H_H  = freqz(Hz,  1, NFFT, 'whole');  % H(z)
    H_MF = freqz(MFz, 1, NFFT, 'whole');  % MF(z)

    %% ---- Complementary filters (eq. 2 in paper) ----
    N_H  = length(Hz);
    N_MF = length(MFz);
    % Hc(z)  = z^{-(N_H -1)/2} - H(z)
    % MFc(z) = z^{-(N_MF-1)/2} - MF(z)
    % In frequency domain: delay = e^{-j*w*(N-1)/2}
    w = (0 : NFFT-1)' * 2*pi / NFFT;   % column vector
    H_Hc  = exp(-1j * w * (N_H  - 1)/2) - H_H;
    H_MFc = exp(-1j * w * (N_MF - 1)/2) - H_MF;

    %% ---- Interpolated filter responses: H(z^M) <=> stretch spectrum ----
    %  H(z^M) in freq domain = H(e^{jwM}) which is just H evaluated at M*w.
    %  Implementation: upsample (interleave zeros) and re-compute DTFT,
    %  OR equivalently evaluate H at M times the frequency.
    %
    %  We use the "evaluation at M*w mod 2pi" approach in the DTFT.
    %  H_Hm{k} = DTFT of H(z^{2^k})

    if NUM_BANDS == 10
        max_interp = 4;  % max interpolation factor exponent: 2^4 = 16
    else
        max_interp = 5;  % 2^5 = 32 for 12-band
    end

    H_Hm  = cell(max_interp + 1, 1);  % H_Hm{1}=H(z^1), H_Hm{2}=H(z^2)...
    H_MFm = cell(max_interp,     1);  % H_MFm{1}=MF(z^1), ...

    H_Hm{1}  = H_H;
    H_MFm{1} = H_MF;

    for k = 2 : max_interp + 1
        M = 2^(k-1);
        % H(z^M): upsample Hz by M then DTFT
        hz_up = upsample_filter(Hz, M);
        H_Hm{k} = freqz(hz_up, 1, NFFT, 'whole');
    end
    for k = 2 : max_interp
        M = 2^(k-1);
        mfz_up = upsample_filter(MFz, M);
        H_MFm{k} = freqz(mfz_up, 1, NFFT, 'whole');
    end
    % MFc interpolated
    H_MFcm = cell(max_interp, 1);
    H_MFcm{1} = H_MFc;
    for k = 2 : max_interp
        M = 2^(k-1);
        mfcz_up = upsample_filter_complement(MFz, N_MF, M);
        H_MFcm{k} = freqz(mfcz_up, 1, NFFT, 'whole');
    end

    %% ---- Compute Pi(z) branch responses ----
    if NUM_BANDS == 10
        P = compute_branches_10(H_Hm, H_MFm, H_MFcm, H_Hc);
    else
        P = compute_branches_12(H_Hm, H_MFm, H_MFcm, H_Hc);
    end

    %% ---- Compute subband outputs Bi(z) ----
    half = NUM_BANDS / 2;
    B = zeros(NFFT, NUM_BANDS);

    % Lower half (eq. 3)
    B(:, 1) = P(:, 1);
    for i = 2 : half
        B(:, i) = P(:, i) - P(:, i-1);
    end
    % Upper half (eq. 4): mirror structure
    B(:, NUM_BANDS) = P(:, NUM_BANDS);
    for i = NUM_BANDS-1 : -1 : half+1
        B(:, i) = P(:, i) - P(:, i+1);
    end

    %% ---- Extract one-sided magnitude response ----
    H_bank = zeros(NUM_BANDS, NFFT/2 + 1);
    for i = 1 : NUM_BANDS
        H_bank(i, :) = abs(B(1:NFFT/2+1, i));
    end

    subbands.NUM_BANDS  = NUM_BANDS;
    subbands.Fs         = Fs;
    subbands.freq_axis  = freq_axis;

    fprintf('  Filter bank constructed successfully.\n');
    fprintf('  Subband count: %d\n', NUM_BANDS);
end


%% ---- Helper: upsample filter by M (insert M-1 zeros between coeffs) ----
function h_up = upsample_filter(h, M)
    N    = length(h);
    h_up = zeros(1, (N-1)*M + 1);
    h_up(1:M:end) = h;
end

%% ---- Helper: upsample complement filter MFc(z^M) ----
function h_up = upsample_filter_complement(mf, N_MF, M)
    % MFc(z) = z^{-(N_MF-1)/2} - MF(z)
    % MFc(z^M) = z^{-M*(N_MF-1)/2} - MF(z^M)
    mf_up    = upsample_filter(mf, M);
    delay_len = M * (N_MF - 1) / 2 + 1;
    delay_imp = zeros(1, length(mf_up));
    if delay_len <= length(delay_imp)
        delay_imp(delay_len) = 1;
    else
        delay_imp = [zeros(1, delay_len-1), 1];
    end
    % Pad to same length
    L = max(length(delay_imp), length(mf_up));
    delay_imp(end+1:L) = 0;
    mf_up(end+1:L)     = 0;
    h_up = delay_imp - mf_up;
end


%% ---- 10-band branch transfer functions (Table I, paper 1) ----
function P = compute_branches_10(H_Hm, H_MFm, H_MFcm, H_Hc)
    % P columns: P1..P10  (NFFT x 10)
    NFFT = length(H_Hm{1});
    P    = zeros(NFFT, 10);

    % Lower 5 branches (original MF path)
    % P1 = H(z^16) MF(z^8) MF(z^4) MF(z^2) MF(z)
    P(:,1)  = H_Hm{5} .* H_MFm{4} .* H_MFm{3} .* H_MFm{2} .* H_MFm{1};
    % P2 = H(z^8)  MF(z^4) MF(z^2) MF(z)
    P(:,2)  = H_Hm{4} .* H_MFm{3} .* H_MFm{2} .* H_MFm{1};
    % P3 = H(z^4)  MF(z^2) MF(z)
    P(:,3)  = H_Hm{3} .* H_MFm{2} .* H_MFm{1};
    % P4 = H(z^2)  MF(z)
    P(:,4)  = H_Hm{2} .* H_MFm{1};
    % P5 = H(z)
    P(:,5)  = H_Hm{1};

    % Upper 5 branches (complementary MFc path)
    % P6 = Hc(z)
    P(:,6)  = H_Hc;
    % P7 = H(z^2)  MFc(z)
    P(:,7)  = H_Hm{2} .* H_MFcm{1};
    % P8 = H(z^4)  MF(z^2) MFc(z)
    P(:,8)  = H_Hm{3} .* H_MFm{2} .* H_MFcm{1};
    % P9 = H(z^8)  MF(z^4) MF(z^2) MFc(z)
    P(:,9)  = H_Hm{4} .* H_MFm{3} .* H_MFm{2} .* H_MFcm{1};
    % P10 = H(z^16) MF(z^8) MF(z^4) MF(z^2) MFc(z)
    P(:,10) = H_Hm{5} .* H_MFm{4} .* H_MFm{3} .* H_MFm{2} .* H_MFcm{1};
end


%% ---- 12-band branch transfer functions (Table I, paper 2) ----
function P = compute_branches_12(H_Hm, H_MFm, H_MFcm, H_Hc)
    % P columns: P1..P12  (NFFT x 12)
    NFFT = length(H_Hm{1});
    P    = zeros(NFFT, 12);

    % Lower 6 branches
    % P1  = H(z^32) MF(z^16) MF(z^8) MF(z^4) MF(z^2) MF(z)
    P(:,1)  = H_Hm{6} .* H_MFm{5} .* H_MFm{4} .* H_MFm{3} .* H_MFm{2} .* H_MFm{1};
    % P2  = H(z^16) MF(z^8)  MF(z^4) MF(z^2) MF(z)
    P(:,2)  = H_Hm{5} .* H_MFm{4} .* H_MFm{3} .* H_MFm{2} .* H_MFm{1};
    % P3  = H(z^8)  MF(z^4)  MF(z^2) MF(z)
    P(:,3)  = H_Hm{4} .* H_MFm{3} .* H_MFm{2} .* H_MFm{1};
    % P4  = H(z^4)  MF(z^2)  MF(z)
    P(:,4)  = H_Hm{3} .* H_MFm{2} .* H_MFm{1};
    % P5  = H(z^2)  MF(z)
    P(:,5)  = H_Hm{2} .* H_MFm{1};
    % P6  = H(z)
    P(:,6)  = H_Hm{1};

    % Upper 6 branches
    % P7  = Hc(z)
    P(:,7)  = H_Hc;
    % P8  = H(z^2)  MFc(z)
    P(:,8)  = H_Hm{2} .* H_MFcm{1};
    % P9  = H(z^4)  MF(z^2) MFc(z)
    P(:,9)  = H_Hm{3} .* H_MFm{2} .* H_MFcm{1};
    % P10 = H(z^8)  MF(z^4) MF(z^2) MFc(z)
    P(:,10) = H_Hm{4} .* H_MFm{3} .* H_MFm{2} .* H_MFcm{1};
    % P11 = H(z^16) MF(z^8) MF(z^4) MF(z^2) MF(z)   [paper typo: should be MFc]
    P(:,11) = H_Hm{5} .* H_MFm{4} .* H_MFm{3} .* H_MFm{2} .* H_MFcm{1};
    % P12 = H(z^32) MF(z^16) MF(z^8) MF(z^4) MF(z^2) MFc(z)
    P(:,12) = H_Hm{6} .* H_MFm{5} .* H_MFm{4} .* H_MFm{3} .* H_MFm{2} .* H_MFcm{1};
end
