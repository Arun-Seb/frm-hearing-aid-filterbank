# FRM Non-Uniform Digital Filter Bank for Hearing Aid

MATLAB implementation of a **10-band and 12-band non-uniform FIR digital filter bank** for hearing aid applications, using the **Frequency Response Masking (FRM)** technique.

## Based On

| Paper | Details |
|---|---|
| Paper 1 | A. Sebastian, J. T. G., *"A Low Complex 12-Band Non-uniform FIR Digital Filter Bank Using Frequency Response Masking Technique For Hearing Aid"*, IJRITCC, Vol. 2, Issue 9, Sep 2014, pp. 2786–2790 |
| Paper 2 | A. Sebastian, J. T. G., *"A Low Complex 10-Band Non-uniform FIR Digital Filter Bank Using Frequency Response Masking Technique For Hearing Aid"*, ICCSC 2014 |

---

## What This Code Does

- Designs the two prototype half-band FIR filters `H(z)` and `MF(z)` using the FRM technique
- Builds a **10-band or 12-band non-uniform FIR digital filter bank** using cascaded interpolated versions of `H(z)` and `MF(z)`
- Demonstrates the complementary filter `MFc(z) = z^{-(N-1)/2} - MF(z)` for hardware-efficient implementation
- Generates **6 sample audiograms** for common hearing loss types
- Performs **audiogram matching** using non-negative least squares (NNLS) gain optimization
- Reports max, mean, and RMS matching errors
- Reproduces **Table II** (transition bandwidth sweep) from the papers
- Provides a **10-band vs 12-band** side-by-side comparison

---

## Key Results (from papers)

| Property | 10-Band | 12-Band |
|---|---|---|
| Number of multipliers | 10 | 10 |
| Stop-band attenuation | 80 dB | 80 dB |
| Max matching error (Presbycusis) | 2 dB | 1.4 dB |
| Optimal normalized TBW | 0.15 | 0.15 |
| Total filter length (H+MF) | 30 | 30 |

---

## FRM Technique Overview

The Frequency Response Masking approach (Lim, 1986) realizes sharp linear-phase FIR filters efficiently:

```
Ha(z) = H(z^M) · MF(z) + Hc(z^M) · MFc(z)
```

where:
- `H(z)` — prototype half-band filter (band-edge shaping)
- `MF(z)` — masking filter (relaxed transition, minimum order)
- `MFc(z) = z^{-(N-1)/2} - MF(z)` — complementary masking filter
- `M` — interpolation factor (2, 4, 8, 16, or 32 in this bank)

**Key savings:**
- Half-band property: all odd-indexed coefficients (except center) are zero → ~half the multipliers
- Multiplier sharing across interpolated branches
- Entire 12-band bank requires only **10 multipliers**

### Subband Transfer Functions (12-band)

| Band | Transfer Function |
|---|---|
| 1 | `H(z³²) MF(z¹⁶) MF(z⁸) MF(z⁴) MF(z²) MF(z)` |
| 2 | `H(z¹⁶) MF(z⁸) MF(z⁴) MF(z²) MF(z)` |
| 3 | `H(z⁸) MF(z⁴) MF(z²) MF(z)` |
| 4 | `H(z⁴) MF(z²) MF(z)` |
| 5 | `H(z²) MF(z)` |
| 6 | `H(z)` |
| 7 | `Hc(z)` |
| 8 | `H(z²) MFc(z)` |
| 9 | `H(z⁴) MF(z²) MFc(z)` |
| 10 | `H(z⁸) MF(z⁴) MF(z²) MFc(z)` |
| 11 | `H(z¹⁶) MF(z⁸) MF(z⁴) MF(z²) MFc(z)` |
| 12 | `H(z³²) MF(z¹⁶) MF(z⁸) MF(z⁴) MF(z²) MFc(z)` |

---

## File Structure

```
FRM_FilterBank_HearingAid/
├── main_filterbank.m           % Main entry point — select 10 or 12 band
├── design_halfband_filters.m   % Design H(z) and MF(z) prototype filters
├── build_filterbank.m          % Build the full filter bank (10 or 12 band)
├── plot_filterbank.m           % Plot subband magnitude responses
├── generate_audiograms.m       % Generate 6 sample audiograms
├── perform_audiogram_matching.m% Audiogram matching + error analysis
├── tbw_sweep_analysis.m        % Reproduce Table II: TBW sweep
├── compare_filterbanks.m       % 10 vs 12 band side-by-side comparison
├── utils_frm.m                 % Utility functions (multiplier count, etc.)
└── README.md
```

---

## Usage

### Quick Start (Interactive)
```matlab
run('main_filterbank.m')
% → prompts: Enter 10 or 12 for filter bank selection
```

### Run Both and Compare
```matlab
run('compare_filterbanks.m')
```

### Transition Bandwidth Sweep (Reproduce Table II)
```matlab
run('tbw_sweep_analysis.m')
```

---

## Sample Audiograms Included

| # | Type | Description |
|---|---|---|
| 1 | **Presbycusis** | Age-related progressive high-frequency loss |
| 2 | **SNHL (Noise Notch)** | Noise-induced 4kHz notch |
| 3 | **Bilateral Conductive** | Flat/rising middle-ear loss |
| 4 | **Meniere's Disease** | Low-frequency fluctuating loss |
| 5 | **Severe Flat Loss** | Uniform severe loss across all frequencies |
| 6 | **Cookie-bite** | U-shaped mid-frequency loss |

---

## Requirements

- MATLAB R2016b or later
- Signal Processing Toolbox (for `firpm`, `freqz`, `fir1`)
- Optimization Toolbox (for `lsqnonneg` — fallback uses `\` operator if not available)

---

## Output Files Generated

| File | Description |
|---|---|
| `FilterBank_NNBand_Magnitude_dB.png` | Subband responses in dB |
| `FilterBank_NNBand_Magnitude_Linear.png` | Linear magnitude responses |
| `FilterBank_NNBand_Hz.png` | Responses in Hz |
| `Sample_Audiograms.png` | All 6 audiograms plotted |
| `AudiogramMatching_NNBand_All.png` | All audiogram match plots |
| `MatchingError_Curves_NNBand.png` | Error curves (like Fig.13 in paper) |
| `MatchingError_Summary_NNBand.png` | Bar chart of max/avg/RMS errors |
| `TBW_Sweep_NNBand.png` | Transition bandwidth sweep |
| `Comparison_10vs12_*.png` | Side-by-side comparison plots |

---

## References

1. Y. C. Lim, "Frequency-response masking approach for the synthesis of sharp linear phase digital filters," *IEEE Trans. Circuits Systems*, Vol. 33, No. 4, pp. 357–364, April 1986.
2. Y. Lian, Y. Wei, "A Computationally Efficient Non-Uniform FIR Digital Filter Bank for Hearing Aid," *IEEE Trans. on Circuits and Systems I*, Vol. 52, pp. 2754–2762, Dec. 2005.
3. Harry Levyitt, "Digital hearing aids: A tutorial review," *Journal of Rehabilitation Research and Development*, Vol. No. 4, pp 7–20, 1987.

---

## License

This code is provided for educational and research purposes. The filter bank design follows the methodology described in the referenced papers.
