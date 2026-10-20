# v6f: the machine stops before final speed is reached

## Cause
The slow-down start point is calculated with the **PLC ramp** (`DecelCoarse` 0.5 = 125 mm/s², then `DecelTrim` 20 mm/s² inside the band).
The real deceleration is set by the **ATV930**. With a heavy unwinder roll and no braking resistor, the drive stretches its ramp to avoid DC-bus overvoltage. The real deceleration is lower than 125 mm/s², and it changes with the roll weight.
→ The slow-down starts too late → the stop point (meters or diameter) arrives while the speed is still high.

## Fix: learn the real slow-down deceleration
New section **5b** in AutoStop_Control:
- It starts at the `SlowDown` edge (auto, at speed) and ends when final speed is reached, **or when the stop comes first**, so even a failed roll teaches it.
- `a = (v0² − v1²) / (2 × distance)` → `RwSlowDecelLrn` (mm/s², Retain, filter 0.5), with the plausibility limits `RwDecelMin_mm` / `RwDecelMax_mm`.
- It does not learn in jog, manual mode or with the slow button (2nd ramp).

Section 6 now takes the deceleration in this order:
**`RwSlowDecel` (manual) > `RwSlowDecelLrn` (learned) > DecelCoarse/DecelTrim model.**

## Steps (on top of the PLC version v6e_PLC: GSM_LearnFault / GSM_Learned_OK)
1. Global Variables: paste `v6f_Globals_paste.txt` (`RwSlowDecelLrn`).
2. Program Externals: paste `v6f_Externals_paste.txt`.
3. Internals: paste `v6f_Locals_paste.txt` (7 rows).
4. Replace the AutoStop_Control ST with `AutoStop_Control_v6f.st`.
5. F7 = 0 errors → transfer.
6. HMI (DT35 / LEARNING page): a display of `RwSlowDecelLrn` [mm/s²], and a "reset" button that writes 0.

## Until it has learned (first roll after the transfer)
The first roll still uses the old model and may stop early again. It learns on that roll. To avoid this, before the first roll either:
- **set `RwSlowDecel` by hand** (Watch or HMI) to a measured value, and set it back to 0 afterwards to use the learned value, or
- **raise the margin** for one roll: `UwSlowMargin_m` / `RwSlowMargin_m` from 10 to 40 m.

**Quick measurement** (watch `Velocity_M_min` and time it):
`a [mm/s²] = (V_start − V_final) [m/min] × 16.67 / t [s]`
Example: 400 → 100 m/min in 30 s → 300 × 16.67 / 30 ≈ **167 mm/s²**.

## Check after 2–3 rolls
- `RwSlowDecelLrn` > 0 and stable (± 20 %).
- The machine reaches final speed, then runs about `UwSlowMargin_m` / `RwSlowMargin_m` metres at final speed, then stops.
- If the margin at final speed is too long, reduce `UwSlowMargin_m` / `RwSlowMargin_m`, but not below 5 m.

## If it still stops early
Check in Watch which stop it was:
- `AutoStopCmd` TRUE → the auto stop (meters / diameter / max diameter `RwMaxStop`)
- `UwStopByDiam` → the unwinder sonar stop diameter (`UwDiamStop`)
- the paper-break photocell, or the slow button

Send me those values and `Velocity_M_min`, `UwSlow_at_Metre`, `UwStop_At_Meter`, `Current_Metre`, `RwSlowDecelLrn`.
