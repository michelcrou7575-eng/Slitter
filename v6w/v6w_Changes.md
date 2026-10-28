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
- The window closes after a **length of paper** (encoder), not after 10 s.
- That length is **modulated by the diameter**: the window ends when the roll should have grown **`RwWinGrow_mm`** (new global, 2.5 mm), computed from the learned thickness: `pulses = RwWinGrow_mm × diameter / RwMat_K`. Limits **4 m … `RwWinLen_m`** (new global, 30 m). Thickness not learned yet → 30 m.

| Rewinder Ø | Window (kraft 0.105 mm) |
|---|---|
| 100–200 mm | 4 – 7.5 m |
| 300 mm | 11 m |
| 450 mm | 17 m |
| 600 mm | 22 m |
| 800 mm and up | 30 m (max) |
Same ≈ 2.5 mm of growth in every window → same accuracy (≈ ±12 % per window, much better after the 30 % filter) at every speed and every roll size.
- Motor stopped during a window → the window is **dropped** (no learning, no fault).
- `RwWinTicks` is no longer used. `RwMinPulses` stays as an extra minimum (1000 is fine).
- `RwLearnFailMax` (12) = 12 windows without a valid result before alarm 16.

## Steps (base: print 1027 + v6v)
1. Global Variables: paste `v6w_Globals_paste.txt` (`RwWinLen_m` 30.0, `RwWinGrow_mm` 2.5, Retain). Externals: type `RwWinLen_m` and `RwWinGrow_mm`.
2. Internals: paste `v6w_Locals_paste.txt` (`LearnWinLen_Pls`).
3. Replace the ST with `AutoStop_Control_v6w.st`. F7 → transfer.
4. Optional: `RwThickMin_mm` 0.07 / `RwThickMax_mm` 0.22 (kraft 80–120 g/m²).

## Test (trace)
`TaglMonoTRM.ThickWin_mm` at 24 m/min and at 400 m/min should both be ≈ 0.10–0.11 mm (80 g/m² kraft). Paper change 80 → 120 g/m²: detected after 2 windows.
`RwWinGrow_mm` larger (3–4) = smoother but longer windows; smaller (2) = faster but noisier.

## Also in v6w: ALARM RESET clears the learning fail counters (section 12)
`I_RsetAlarm` (panel button) or `Alarm_Reset` (HMI) → `LearnFailCnt` := 0 and `StopFailCnt` := 0. Alarm 16 then resets with the same press (Alarms rung 17 sees `GSM_LearnFault` = FALSE on the next scan, the button is held longer than one scan). If the cause is still there, alarm 16 comes back after 12 failed windows / 3 failed stops. No need to write `StopFailCnt` = 0 in the Watch tab any more.
