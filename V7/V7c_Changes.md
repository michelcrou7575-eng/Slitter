# V7c: unwinder diameter slow-down follows the speed (10/29)

## Why
General rung 16: `SlowByDiam := UwDiam_Act <= UwSlowDown_Diam` (fixed 200 mm), active
whenever the sonar is ON (`Measure_ON`), **without AutoStop**. The same 200 mm is
used at 100 m/min and at 500 m/min: too late at high speed, too long a crawl at low
speed. (The AutoStop metre slow-down `UwSlow_at_Metre` already follows the speed,
but only with selector 12SA5 + unwinder AUTO.)

## How
Same paper on the unwinder and the rewinder -> the learned `RwMat_K` gives the paper
left on the unwinder from its diameter. The slow-down length is the one AutoStop already
computes for the speed (`UwSlowLen_Pls`: decel at DecelWeb from MAX(actual, pot) to the
slow speed + final stop + `UwSlowMargin_m`).

`UwSlowDiamCalc = SQRT(UwDiamStop² + 2 × RwMat_K × UwSlowLen_Pls)`

Example, 0.10 mm paper, UwDiamStop 110, slow speed 30 m/min, margin 10 m, DecelWeb 250:

| Speed | Slow-down length | Slow-down diameter |
|---|---|---|
| 100 m/min | ≈ 15 m | ≈ 118 mm |
| 300 m/min | ≈ 60 m | ≈ 140 mm |
| 500 m/min | ≈ 148 m | ≈ 176 mm |

(Thicker paper -> larger diameters. Check the live value `UwSlowDiamAct` on the HMI.)

- Not learned yet (`RwMat_K` = 0, new paper) or `UwSlowDiamAuto` OFF -> fixed `UwSlowDown_Diam`, exactly as today.
- Latched once reached (frozen + 10 mm), released by a new roll (diameter > point + 30 mm).
- The stop itself is unchanged (`UwStopByDiam`, `UwDiamStop`).

## Load
1. Globals: paste `V7c_Globals_paste.txt` (UwSlowDiamAuto True Retain, UwSlowDiamAct).
2. AutoStop_Control internals: paste `V7c_Locals_paste.txt`.
3. AutoStop_Control: paste `V7c_AutoStop_UwSlowDiam.st` right after the
   "Unwinder slow-down request, latched" block (the two `IF ... UwSlowReq` in section 6).
4. **General rung 16** (ladder `SlowByDiam`): in the `<=` compare, change **In2** from
   `UwSlowDown_Diam` to **`UwSlowDiamAct`**. Nothing else.
5. HMI (diameter page): display `UwSlowDiamAct` "SLOW AT Ø (mm)" + toggle `UwSlowDiamAuto`
   "AUTO SLOW Ø". Keep `UwSlowDown_Diam` as the fallback setting.

## Test
- Running, watch `UwSlowDiamAct` change with the pot (bigger at higher speed).
- With a small roll: the slow-down starts at `UwSlowDiamAct`, speed reaches the slow speed
  about `UwSlowMargin_m` before `UwDiamStop`, `UwSlowDiamLatch` = 1 and stays.
- `UwSlowDiamAuto` OFF -> slows at `UwSlowDown_Diam` (200) as before.

Note: near the core 1 mm of unwinder diameter is only ≈ 2 m of paper (0.10 mm paper,
120 mm roll), so ±2 mm of sonar noise = ±4 m. Keep `UwSlowMargin_m` ≥ 10 m.
