# V7: feed-forward speed loop + ramps in real web mm/s² (+ setting clamps)

**Base:** print **1029** (= 1028_2 + v6y). Check against the next PDF before transferring.
**Way back at any time:** `FFEnable` = FALSE → the old loop (rung 16) runs exactly as before.

## Why (traces 10/29/2026, roll ≈ 970–1010 mm, 450 m/min)
The original loop **searches** the drive frequency (+/− a fixed Hz/s while out of the ±`SpdDelta_Percent` band). On a big roll the web speed reacts ≈ 0.9 s late → overshoot → **hunting** (±32 m/min, 3.5 s period, current 5 ↔ 36 A, 93 % of the time out of the band). The same happened on the original machine above 450–500 m/min. With coarse 0.3 / band 12 it is stable, but every ramp becomes 3× slower.

## How V7 works
1. **Ratio** (rung A): drive counts per m/min of web = **`RwRatioD` / rewinder diameter** (motor drives the rewinder). `RwRatioD` ≈ 2780–2950 from the traces (initial **2900**).
2. **Feed-forward** (rung B): the reference goes **straight to the frequency of the set speed** (`VelSet` × ratio) along a ramp in **real web mm/s²**: `AccelWeb` (200), `DecelWeb` (250), `SoftStopDecel` during a soft stop. The ramp does not depend on the measured speed → **cannot hunt**, whatever the roll.
3. **Correction:** once at the target for 2 s, the measured speed adapts `RwRatioD` slowly (time constant ≈ 10 s, dead band 0.3 %, max ±5 % error per step). Not at the 60 Hz limit, not during soft stop / jog / below 15 m/min. `RwRatioD` is Retain → the next run starts right.
4. **Slow-down length** (AutoStop section 6): one ramp at `DecelWeb` → exact, no learning needed.
5. Same web decel on every roll: small roll fast (in Hz/s), big roll gentle.

| Rewinder Ø | Old `DecelCoarse` 1.0 on the web | V7 `DecelWeb` 250 |
|---|---|---|
| 100 mm | ≈ 45 mm/s² | 250 |
| 300 mm | ≈ 135 | 250 |
| 1000 mm | ≈ 450 (→ hunting) | 250 |

Not changed: manual mode (rung 18), jog speed, auto stop at the target (drive ramp), E-stop, soft stop logic (General rung 9), AutoStop learning (fallback).

## 1. Variables
- Global Variables: paste `V7_Globals_paste.txt` (`DecelWeb` 250, `AccelWeb` 200, `RwRatioD` 2900, **`FFEnable` True**, Retain, Publish Only). Externals: type the 4 names.
- Internals: paste `V7_Locals_paste.txt` (`WebRatio`, `FFActive`, `FFWasActive`, `FFTarget`, `RampRef`, `StepAcc`, `StepDec`, `FFSteadyTicks`, `FFErr`).

## 2. Motor_Manager
| New rung | Where | File |
|---|---|---|
| **A** "V7: web ratio + web ramps" | directly **after rung 14** (factor selection), before rung 15 (soft stop) | `V7_MotorManager_rung.st` |
| **B** "V7: feed-forward speed loop (AUTO)" | **after rung 16** (speed correction, ladder), before rung 17 (inverter reference) | `V7_MotorManager_FF_rung.st` |
| rung 5: clamps | append after the v6y lines, before `Output_Ratio` | `V7_MotorManager_rung5_clamps.st` |
Rungs 14, 15, 16, 17 stay unchanged (rung B overwrites `Vfd_SP_Modif` after rung 16 when `FFEnable`).

## 3. AutoStop_Control
Replace the ST with `AutoStop_Control_V7.st` (= printed v6y + section 6 change).

## 4. HMI (password page 22)
- "ACCELERATION RAMP COARSE" → **`AccelWeb`**, "DECELERATION RAMP COARSE" → **`DecelWeb`**: format ####, mm/s², limits 50–1000.
- New toggle **FEED-FORWARD ON/OFF** → `FFEnable` (enabled only when `MotStop`).
- Display **SPEED RATIO** → `RwRatioD` (####).
- `SpdDelta_Percent`, `AccelTrim`, `DecelTrim`, `AccelCoarse`, `DecelCoarse`: only used with `FFEnable` OFF.

## 5. Tests (with Data Trace 20 ms + SoMove scope, like 10/29)
Trace: `Velocity_M_min`, `VelSet`, `InvRef`, `TaglMonoTRM.RampRef`, `TaglMonoTRM.FFTarget`, `TaglMonoTRM.FFActive`, `TaglMonoTRM.FFSteadyTicks`, `RwRatioD`, `RwDiam`, `SoftStop`, `TaglMonoTRM.SlowDown`.
1. **Small roll, 200 m/min:** start → straight ramp, no overshoot; after ≈ 10 s `Velocity_M_min` = set speed ±1 %; `RwRatioD` settles.
2. **Big roll, 450 → 500 m/min:** steady, **no hunting** (current steady), unlike 10/29.
3. Pot changes up/down while running: straight ramps, no overshoot.
4. Auto slow-down: decel ≈ `DecelWeb`, final speed reached just before "SLOW DOWN AT"; stop at the target.
5. Soft stop from 450: straight decel ≈ `SoftStopDecel`.
6. `FFEnable` OFF (machine stopped) → old behaviour; ON again → V7.
If a speed error stays > 2 % at steady speed: check `RwRatioD` moves; if it sits at 1000/8000 → DT35 diameter calibration.

## V7a (10/29, after the first V7 trace `Traces/GSM20261029150003_00001_V7.csv`)
Result of the first test (roll ≈ 1080–1093 mm, 400 → 517 → 495 m/min, soft stop):
- No hunting. RampRef/InvRef flat at target, accel exactly AccelWeb (≈ 12 m/min/s).
- Steady error about −2 % (411 → 404, 518 → 507, 495 → 484) : RwRatioD 2900 is ~2 % low.
- **Bug:** FFSteadyTicks never passed 8 -> RwRatioD never adapted. The pot (±0.2 m/min)
  and RwDiam noise move FFTarget by ±2 counts each scan, more than the ±StepAcc
  (0.4 count) "at target" window, so the counter reset all the time.

Fix (rung B only, "Ramp generator" part): the ramp itself is unchanged, the
steady counter now counts while `ABS(FFTarget - RampRef) <= FFTarget * 0.005 + 2.0`
(within 0.5 %). Copy the new block from `V7_MotorManager_FF_rung.st`, no new variables.

Expected after V7a: about 2 s after reaching the speed, RwRatioD climbs to
≈ 2950–2960 within ~20 s and Velocity_M_min = VelSet ± 0.3 %.

## V7b (10/29): JOG not working with V7
Jog / slow button (`I_LowSpd_OS`, VelSet = JogSpd_SP 10 m/min) ran through the
feed-forward: 10 m/min x WebRatio on a 1090 mm roll = InvRef ≈ 27 counts ≈ 0.4 Hz,
too low to move the web, and RwRatioD does not adapt below 15 m/min.
The old loop integrates until the web really moves, so jog goes back to it.

Change (rung B, first line):
```
FFActive := FFEnable AND NOT ManMode AND NOT I_LowSpd_OS AND StartMotor_Cmd
            AND ControlVoltage AND (WebRatio > 0.0) AND (Vel_Max_mms > 0.0);
```
Switch-over is bumpless both ways (the old loop starts from the last Vfd_SP_Modif,
rung B starts RampRef from it). Jog uses the rung 14 ramps exactly as before V7.

Rung A, same idea (the web ramps of the FFEnable = FALSE fallback are not used in jog):
```
IF NOT FFEnable AND NOT I_LowSpd_OS AND StartMotor_Cmd AND (UnderSpeed OR OverSpeed)
   AND (WebRatio > 0.0) THEN
```
With both lines, a jog runs exactly like v6y, whatever FFEnable is.
Seen on 10/29 before V7b: jog with FF ON = no motor current (≈ 0.4 Hz), FF OFF = 35 A, erratic.
