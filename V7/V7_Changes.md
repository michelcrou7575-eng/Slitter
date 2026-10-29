# V7: all AUTO ramps in REAL web mm/s² (same on every roll size)

**Base:** checked against **print 1029** (10/29/2026) = 1028_2 + **v6y** (Motor_Manager rungs 5/6/7/8, AutoStop v6y, `RwAutoMaxSpd`, `RwWinLen_m`). `AutoStop_Control_V7.st` = the printed v6y + the V7 section 6 change only. v6q S-curve not loaded.
**When:** after the first order (100 → 300 mm). Until then: v6x + `DecelCoarse` 2.0.

## Why
`DecelCoarse` / `AccelCoarse` are a fixed **Hz/s**. The motor drives the rewinder, so the web decel/accel is proportional to the diameter:
| Rewinder Ø | `DecelCoarse` 1.0 on the web | V7 `DecelWeb` 250 |
|---|---|---|
| 100 mm | ≈ 45 mm/s² | 250 mm/s² |
| 300 mm | ≈ 135 | 250 |
| 600 mm | ≈ 270 | 250 |
| 1000 mm | ≈ 450 | 250 |
| 1400 mm | ≈ 630 | 250 |
→ Small rolls: slow-downs/accelerations much shorter. Big (heavy) rolls: gentler. And the slow-down length is **known** from the setting: no more learning delay, no wrong K.

## How
- **Ratio** drive counts per m/min of web = **`RwRatioD` / diameter** (web speed per Hz grows with the diameter). `RwRatioD` (Retain, initial **2780** from the 10/27–28 scopes: 400 m/min = 28 Hz at 595 mm, 150 m/min = 16.7 Hz at 375 mm) is learned while running steady in AUTO (> 30 m/min, inside the band, DT35 OK), filtered ≈ 4 s.
- **Motor_Manager:** when the coarse ramp is active (more than `SpdDelta_Percent` from the set speed), `Decel_Ramp` / `Accel_Ramp` are computed from **`DecelWeb` / `AccelWeb`** (mm/s²) × ratio. Same formula as v6r (checked on the scope). Max 8.0 (9 Hz/s). Inside the band the trim ramps stay (loop gain).
- **AutoStop section 6:** slow-down length = manual `RwSlowDecel` > **`DecelWeb` (coarse) + trim tail converted to web units** > learned (fallback) > old model.
- `DecelWeb` / `AccelWeb` = 0 → old `DecelCoarse` / `AccelCoarse` behaviour (way back).
- Soft stop (v6r `SoftStopDecel`) and the S-curve start (v6q) are unchanged.

## 1. Variables
- Global Variables: paste `V7_Globals_paste.txt` (`DecelWeb` 250, `AccelWeb` 200, `RwRatioD` 2780, Retain, Publish Only). Externals: type the 3 names.
- Internals: paste `V7_Locals_paste.txt` (`WebRatio`, `RatioMeas`).

## 2. Motor_Manager: new inline-ST rung
**Directly after** rung 14 "Acceleration/deceleration factor selection (1 = 250 mm/s²)" and **before** rung 15 "Soft Stop - SoftStopDecel (mm/s2), same for every roll" (it must act after V7). If the v6q S-curve rung is added later, it goes after V7 too.
Comment: `V7: coarse ramps in real web mm/s2`. Content: `V7_MotorManager_rung.st`.

## 2b. Motor_Manager rung 5: setting limits (clamps)
Append `V7_MotorManager_rung5_clamps.st` in rung 5 after the v6y lines (after `RwAutoMaxSpdAct := RwAutoMaxSpd; END_IF;`, before `Output_Ratio`):
`SpdDelta_Percent` 2–15, `AccelTrim`/`DecelTrim` 0.02–0.5, `AccelCoarse`/`DecelCoarse` 0.2–4, `DecelWeb`/`AccelWeb` 0 or 50–1000, `SoftStopDecel` ≤ 1500, **`RwMaxDiam` 300–1450 (mechanical limit, adjust if the real limit differs)**, `RwMaxSlowFallback` < `RwMaxDiam`.
Also set the same limits on the HMI numeric inputs (EasyBuilder: Numeric → Limits), so a wrong entry is refused instead of being corrected silently.

## 2c. v6y
Already in the PLC (print 1029): nothing to add.

## 3. AutoStop_Control
Replace the ST with `AutoStop_Control_V7.st` (= v6x + section 6 change; uses `RwCoreDiameter`).

## 4. HMI page 22 (ramps)
- "DECELERATION RAMP OUTSIDE THE BAND" → tag **`DecelWeb`**, format ####, unit mm/s², limits 50–1000.
- "ACCELERATION RAMP OUTSIDE THE BAND" → tag **`AccelWeb`**, same.
- Optional display `RwRatioD` (####) on a technician page.

## 5. Test
1. Watch: `RwRatioD` stays ≈ 2700–2900 while running (if very different: DT35 diameter calibration).
2. Auto slow-down on a small roll (≈ 200 mm) and on a big roll: SoMove scope → web decel ≈ `DecelWeb` on both (Hz/s higher on the small roll).
3. "SLOW DOWN AT" from the first run after a core change (no learning delay); final speed reached just before the target.
4. Start from the core: no jerk (S-curve) and the acceleration noticeably shorter than before.
