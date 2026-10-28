# v6w: length-based paper thickness window

## Why
The thickness window was **10 s**. At the final speed (24 m/min) that is 4 m of paper → the roll grows ≈ 0.6 mm, about the DT35 noise (1 count ≈ 0.4 mm of diameter) → ±50 % error (trace 10/28: 0.017 / 0.209 / 0.218 mm).
A **length**-based window gives the same diameter growth, so the same accuracy, at every speed.

| Window | at 24 m/min | at 200 m/min | at 400 m/min | growth (kraft 0.105 mm, Ø 450) | error |
|---|---|---|---|---|---|
| 10 s (before) | 4 m | 33 m | 67 m | 0.6 → 10 mm | ±50 % → ±3 % |
| **30 m (v6w)** | 75 s | 9 s | 4.5 s | **≈ 4.5 mm always** | **≈ ±7 % always** |

(Filtered by `RwLearn_K` 0.3 over several windows → the learned value is much better than one window.)

## Change (AutoStop_Control section 4 only)
- The window closes after **`RwWinLen_m`** (new global, REAL, Retain, **30.0** m) of paper, measured by the encoder.
- Motor stopped during a window → the window is **dropped** (no learning, no fault), a new one starts at the next run.
- `RwWinTicks` is no longer used. `RwMinPulses` stays as an extra minimum (1000 is fine, no need for 300000 any more).
- `RwLearnFailMax` (12) now means 12 windows = 360 m of paper without a valid result before alarm 16.

## Steps (base: print 1027 + v6v)
1. Global Variables: paste `v6w_Globals_paste.txt`. Externals: type `RwWinLen_m`.
2. Internals: paste `v6w_Locals_paste.txt` (`LearnWinLen_Pls`).
3. Replace the ST with `AutoStop_Control_v6w.st`. F7 → transfer.
4. Optional: `RwThickMin_mm` 0.07 / `RwThickMax_mm` 0.22 (kraft 80–120 g/m²).

## Test (trace)
`TaglMonoTRM.ThickWin_mm` at 24 m/min and at 400 m/min should both be ≈ 0.10–0.11 mm (80 g/m² kraft). Paper change 80 → 120 g/m²: detected after 2 windows = 60 m.
Longer window (40–50 m) = smoother but slower; shorter (20 m) = faster but noisier.
