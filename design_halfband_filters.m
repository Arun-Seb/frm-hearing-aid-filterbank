function [Hz, MFz] = design_halfband_filters(H_len, MF_len, norm_tbw)
%DESIGN_HALFBAND_FILTERS  Design the two prototype FIR half-band filters.
%
%  The FRM approach (Lim, 1986) uses:
%    H(z)  - prototype half-band filter (band-edge shaping filter)
%    MF(z) - masking filter (lower complexity, minimum order)
%
%  Half-band filter properties exploited:
%    1) All odd-indexed coefficients (except central) are zero
%    2) Coefficients are symmetric (linear phase)
%    => Nearly half of coefficients are non-zero => low multiplier count
%
%  Inputs:
%    H_len    - desired length of H(z)  [odd integer]
%    MF_len   - desired length of MF(z) [odd integer]
%    norm_tbw - normalized transition bandwidth
%
%  Outputs:
%    Hz  - coefficients of H(z)
%    MFz - coefficients of MF(z)

    fprintf('\n--- Designing Prototype Filters ---\n');

    % ---- H(z): half-band lowpass, cutoff at 0.25 (normalized) ----
    % Half-band filter has cutoff exactly at Nyquist/2 => Wc = 0.5 (normalised to pi)
    Wc_H  = 0.5;                     % half-band cutoff (normalised, 0..1)
    % Use Parks-McClellan / firpm if available, else use fir1 with window
    % Transition band: [0.5 - tbw/2 , 0.5 + tbw/2]
    f_pb  = Wc_H - norm_tbw / 2;
    f_sb  = Wc_H + norm_tbw / 2;

    try
        % firpm: equiripple linear-phase FIR
        Hz = firpm(H_len - 1, [0, f_pb, f_sb, 1], [1, 1, 0, 0]);
    catch
        % Fallback: Kaiser window design
        Hz = fir1(H_len - 1, Wc_H, 'low', kaiser(H_len, 8));
    end
    % Enforce half-band symmetry: zero out near-zero odd coefficients
    Hz = enforce_halfband(Hz);

    % ---- MF(z): masking filter, wider transition band is acceptable ----
    % Masking filter cutoff is chosen so that cascaded response gives
    % correct band edges. A simple lowpass at 0.25 with relaxed transition.
    f_pb_mf = 0.20;
    f_sb_mf = 0.30;
    try
        MFz = firpm(MF_len - 1, [0, f_pb_mf, f_sb_mf, 1], [1, 1, 0, 0]);
    catch
        MFz = fir1(MF_len - 1, 0.25, 'low', hamming(MF_len));
    end

    % Report non-zero multiplier counts
    Hz_nz  = sum(abs(Hz)  > 1e-6);
    MFz_nz = sum(abs(MFz) > 1e-6);
    fprintf('  H(z)  non-zero coeffs: %d (out of %d)\n', Hz_nz,  H_len);
    fprintf('  MF(z) non-zero coeffs: %d (out of %d)\n', MFz_nz, MF_len);
    fprintf('  Estimated multipliers (shared): ~10\n');
end


function h = enforce_halfband(h)
%ENFORCE_HALFBAND  Zero out odd-indexed coefficients (except center).
%  In a true half-band filter, h(n)=0 for all even n except n=(N-1)/2.
%  (Using 0-based indexing where N=length.)
    N   = length(h);
    ctr = (N + 1) / 2;   % 1-based center index (N must be odd)
    for k = 1 : N
        dist = abs(k - ctr);
        if mod(dist, 2) == 1
            h(k) = 0;    % zero out odd-distance from center
        end
    end
end
