# V9 package (10/30) — complete, one download

Built on the printed program `Slitter_1029_V7_compressed.pdf` (V7 loaded, newest PDF on GitHub).
**V9 = everything since V7** (V8 content V7a–V7f + the V9 items). V8 does NOT need to be loaded first.
If V8 is already loaded, the steps marked **(V8)** are already done: skip them, do the rest.

| # | Improvement | From |
|---|---|---|
| 1 | RwRatioD learning works (steady counter within 0.5 %) | V7a |
| 2 | JOG / slow button on the old loop | V7b |
| 3 | Unwinder DIAMETER slow-down follows the speed (no AutoStop needed) | V7c |
| 4 | JOG blocked above `RwJogMaxDiam` (400 mm) | V7d |
| 5 | AutoStop slow-down model in ManMode as before V7 | V7e |
| 6 | S-curve on the AUTO ramps (`SCurveTime` 0.5 s) (+ `TOneDecel`, not wired) | V7f |
| 7 | Speed measured over exactly 100 ms (was 48/52 ms: 397 / 431 at 418) | V9 |
| 8 | Horn: start beep, short beep every n s, stop beep, all on the HMI + test button | V9 |
| 9 | Thickness: DT35 averaged per roll revolution, long-baseline learning, LOCKED at 300 mm, `RwWave_mm` | V9 |
| 10 | GSM popup once per real new roll, NEW PAPER closes it | V9 |
| 11 | Unwinder display: STOP LENGTH (AutoStop) ↔ SLOW AT Ø (normal) | V9 |
| 12 | START ignored while JOG held + 2 s (no JOG → full speed) | V9 |
| 13 | START during a soft stop: speed HELD until START again, then gentle ramp up | V9 |

## 0. Before
- Save the project under a new name (`Slitter_V9`), keep the V7 project as backup.
- Note online: `RwRatioD`, `RwMat_K`, `RwStopDecel`, `RwThick_mm` (Retain, must stay).

## 1. Variables
- **Global Variables:** paste `V9_Globals_paste.txt` (21 lines; the first 6 are V8 — skip them if V8 is loaded).
- **TaglMonoTRM Externals:** type the same names (21, or 15 if V8 is loaded).
- **TaglMonoTRM Internals:** paste `V9_Internals_paste.txt` (41 lines; the first 5 are V8).
  `T_JogStartBlk` is of type **TOF** (function block instance).

## 2. Motor_Manager (find the rungs by their comment — numbers shift after step 2d)
| Step | Rung (printed number / comment) | Action | File |
|---|---|---|---|
| 2a **(V8)** | 5 "Check the maximum and minimum values…" | **add at the end** (after the `RwMaxSlowFallback` clamp) | `MotorManager_rung5_add_V9.st` |
| 2b | 15 "Ratio drive counts per m/min…" (V7 rung A) | **replace all the code** (same as V8) | `MotorManager_rungA_V9.st` |
| 2c | 18 "Slow adaptation of RwRatioD…" (V7 rung B) | **replace all the code** | `MotorManager_rungB_V9.st` |
| 2d | 11 "Read the current value of the encoder" + 12 "Speed calculation" | **delete both**, insert ONE ST rung (no contact) at their place | `MotorManager_rung11_12_speed_V9.st` |

## 3. AutoStop_Control
Replace all the ST with `AutoStop_Control_V9.st` (ends with `UwTeachUndo := FALSE; END_IF;`).

## 4. General (ladder edits + 1 new ST rung)
| Step | Rung | Edit |
|---|---|---|
| 4a | **new**, between 6 ("10 V DC source") and 7 | ST rung (no contact) = `General_rung6b_startblock_V9.st` |
| 4b | 7 (Slow_Inhibit) | contact `I_Start_PB` (NO) → **`StartPB_OK`** |
| 4c | 8 "Main Motor start", START branch | contact `I_Start_PB` (NO) → **`StartPB_OK`** |
| 4d **(V8)** | 8, JOG branch `I_LowSpd_OS — Slow_Inhibit(NC) — I_Start_PB(NC) — T_StartLow` | add NC **`JogInhibit`** before `T_StartLow` (leave this `I_Start_PB` NC as it is) |
| 4e | 10 "Main Motor stop", JOG-release branch `I_LowSpd_OS↓ — Slow_Inhibit(NC) — I_Start_PB(NC)` | `I_Start_PB` (NC) → **`StartPB_OK`** (NC) |
| 4f **(V8)** | 16 `SlowByDiam` compare `<=` | In2 `UwSlowDown_Diam` → **`UwSlowDiamAct`** |
Not changed: rung 9 (soft stop: START still cancels it), rung 12 (brake).

## 5. Output_Manager
Rung 11 "Horn / acoustic signal" (ladder): **delete**, insert ONE ST rung (no contact) at its place =
`OutputManager_rung11_horn_V9.st`.

## 6. Build
Build → **0 errors**. Then optional Simulator checks: `JogInhibit` (RwDiam 300 / 500),
`StartPB_OK` (I_LowSpd_OS ON → OFF, I_Start_PB within 2 s = FALSE).

## 7. HMI
| Page | Object | Address | Format / limits |
|---|---|---|---|
| 22 (ramps) | Numeric "S-CURVE (s)" **(V8)** | `SCurveTime` | #.#, 0–2 |
| 22 | Numeric "JOG MAX Ø (mm)" **(V8)** | `RwJogMaxDiam` | ####, 0 / 150–1450 |
| 22 | Numeric "RESUME RAMP (mm/s²)" | `SoftCancelAccel` | ####, 0 / 20–1000 |
| 22 / Horn | Numeric "START BEEP (s)" | `HornStartBeep_s` | #.#, 0–5 |
| 22 / Horn | Numeric "SHORT BEEP (s)" | `HornBeepLen_s` | #.#, 0–2 |
| 22 / Horn | Numeric "BEEP EVERY (s)" | `HornBeepPeriod` | #.#, 0–30 |
| 22 / Horn | Numeric "STOP BEEP (s)" | `HornStopBeep_s` | #.#, 0–10 |
| 22 / Horn | Momentary button "HORN TEST" | `HornTest` | |
| Diameter | Display "UW SLOW AT Ø (mm)" **(V8)** + toggle "AUTO SLOW Ø" | `UwSlowDiamAct`, `UwSlowDiamAuto` | #### |
| Diameter | Numeric "LOCK THICKNESS AT Ø (mm)" / "MIN GROWTH (mm)" | `RwLockDiam`, `RwLockMinGrow_mm` | ####, 0–1450 / 10–500 |
| Diameter | Lamp "THICKNESS LOCKED" | `RwMatLocked` | |
| Diameter | Displays "THICKNESS LONG (mm)", "ROLL WAVE (mm)" | `LongThick_mm`, `RwWave_mm` | #.###, #.# |
| Main | Lamp "JOG BLOCKED – ROLL TOO BIG" **(V8)** | `JogInhibit` | |
| Main | Lamp "SPEED HELD – PRESS START" (near SOFT STOP) | `SpdHold` | |
| Main, unwinder | STOP LENGTH numeric + its label: Visibility bit | `UwShowStopLen` ON | |
| Main, unwinder | **new** numeric display `UwSlowDiamAct` + label "SLOW AT Ø [mm]", same place | visibility `UwShowSlowDiam` ON | #### |

## 8. Download & tests (Data Trace 20 ms)
Tags: `Velocity_M_min, VelSet, InvRef, TaglMonoTRM.RampRef, TaglMonoTRM.FFTarget, TaglMonoTRM.FFRate,
TaglMonoTRM.FFSteadyTicks, RwRatioD, RwDiam, RwDiamRev, RwWave_mm, LongThick_mm, RwMatLocked, SoftStop,
SpdHold, TaglMonoTRM.SlowDown, O_AcousticSignal, JogInhibit, StartPB_OK, UwSlowDiamAct, UwDiam_Act`

1. **Retain kept:** values of step 0 unchanged.
2. **Speed display:** steady 400 m/min → `Velocity_M_min` within ±0.5 (no more ±4 % jumps).
3. **JOG:** below `RwJogMaxDiam` works (FFActive 0); above → nothing, lamp ON.
   Hold JOG, press START → nothing; release JOG, START within 2 s → nothing; after 2 s → starts.
4. **S-curve:** 500 → 300 → 500 with `SCurveTime` 0 / 0.5 / 1.0: rounded, no overshoot.
5. **Soft stop + START:** STOP at 400 → START during the decel → flattens, `SpdHold` ON, speed constant;
   START again → gentle ramp up (`SoftCancelAccel`); STOP during the hold → soft stop again.
   Auto slow-down during the hold still slows down.
6. **Horn:** auto slow-down → start beep, short beep every 5 s, stop beep 3 s at standstill. HORN TEST at standstill.
7. **Thickness:** NEW PAPER (hold 3 s) on an empty core → `LongThick_mm` appears after 20 mm growth
   (80 GSM ≈ 0.10–0.11 mm), `RwMatLocked` ON at 300 mm. `RwWave_mm` shows the roll ovality.
   **Check the DT35 diameter with a tape first** (circumference / π) — the lock keeps what it learned.
8. **GSM popup:** only after the unwinder was empty 3 s and a new roll > stop + 100 mm for 3 s; NEW PAPER closes it.
9. **Unwinder display:** AutoStop unwinder ON → STOP LENGTH; OFF → SLOW AT Ø.
10. **Rewinder AutoStop** (`RwSlowDecel` = 0): slows at `RwSlowAtDiam`, slow speed before the target, stop ±2 mm.
11. **Unwinder diameter slow-down** (small parent roll): `UwSlowDiamAct` larger at higher speed.

Fallbacks without download: `FFEnable` OFF (old loop), `SCurveTime` 0, `UwSlowDiamAuto` OFF,
`RwJogMaxDiam` 0, `RwLockDiam` 0 (never lock), horn settings 0 = that beep off.

## 9. After the tests (before the Sysmac licence ends)
Print the program PDF to GitHub (I check it), copy the learned values into Initial Values,
back up project + HMI (`V7/V7_Load_Plan.md` §backups).

## Not in V9 (later)
T-one: password (La Meccanica / Re), PID F.5–F.7, F.1 pull-back; low-tension warning needs an extra
NX input unit. JOG breakaway minimum. Edit stop targets while AUTO is ON (TODO.md).
