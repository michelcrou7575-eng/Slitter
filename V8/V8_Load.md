# V8 package (10/30) — one download

Built on the printed program `Slitter_1029_V7_compressed.pdf` (V7 loaded).
V8 = V7a + V7b + V7c + V7d + V7e + V7f. Details / reasons: `V7/V7_Changes.md` (V7a, V7b, V7e),
`V7/V7c_Changes.md`, `V7/V7d_Changes.md`, `V7/V7f_Changes.md`.

| Part | What it does |
|---|---|
| V7a | RwRatioD learning works (steady counter within 0.5 % of the target) |
| V7b | Jog / slow button on the old loop (feed-forward gave only 0.4 Hz) |
| V7c | Unwinder DIAMETER slow-down follows the speed (no AutoStop needed) |
| V7d | Jog blocked above `RwJogMaxDiam` (400 mm) rewinder diameter |
| V7e | AutoStop slow-down model in ManMode as before V7 |
| V7f | S-curve on the AUTO ramps (`SCurveTime` 0.5 s) + `TOneDecel` signal |

## 0. Before
Save the project as a new name (e.g. `Slitter_V8`), keep the V7 project as backup.
Note the online values of `RwRatioD`, `RwMat_K`, `RwStopDecel` (Retain, should stay).

## 1. Variables
- **Global Variables:** paste `V8_Globals_paste.txt` (6 lines):
  `UwSlowDiamAuto` True R, `UwSlowDiamAct`, `RwJogMaxDiam` 400 R, `JogInhibit`, `SCurveTime` 0.5 R, `TOneDecel`.
- **TaglMonoTRM Externals:** type the same 6 names.
- **TaglMonoTRM Internals:** paste `V8_Internals_paste.txt` (5 lines):
  `UwSlowDiamCalc`, `UwSlowDiamLatch`, `FFRate`, `FFRateSet`, `FFJerk`.

## 2. Motor_Manager
| Rung | Action | File |
|---|---|---|
| 5 | **add at the end** (after the `RwMaxSlowFallback` clamp) | `MotorManager_rung5_add_V8.st` |
| 15 (V7 rung A, "Ratio drive counts…") | **replace all the code** | `MotorManager_rungA_V8.st` |
| 18 (V7 rung B, "Slow adaptation of RwRatioD…") | **replace all the code** | `MotorManager_rungB_V8.st` |

## 3. AutoStop_Control
Replace all the ST with `AutoStop_Control_V8.st` (860 lines; ends with `UwTeachUndo := FALSE; END_IF;`).

## 4. General (2 ladder edits)
- **Rung 8** "Main Motor start", slow branch `I_LowSpd_OS — Slow_Inhibit (NC) — I_Start_PB (NC) — T_StartLow`:
  add a **NC contact `JogInhibit`** in series, before `T_StartLow`.
- **Rung 16** `SlowByDiam` compare `<=`: change **In2** `UwSlowDown_Diam` → **`UwSlowDiamAct`**.

## 5. Build
Build → **0 errors**. (Real literals: `REAL#` already used where MAX/MIN need it.)
Optional: Simulator check of `JogInhibit` (RwDiam 300 / 500) and `UwSlowDiamAct` (pot speed).

## 6. HMI
| Page | Object | Address | Format / limits |
|---|---|---|---|
| 22 (ramps) | Numeric "S-CURVE (s)" | `SCurveTime` | #.#, 0–2 |
| 22 | Numeric "JOG MAX Ø (mm)" | `RwJogMaxDiam` | ####, 0 or 150–1450 |
| Diameter page | Display "UW SLOW AT Ø (mm)" | `UwSlowDiamAct` | #### |
| Diameter page | Toggle "AUTO SLOW Ø" | `UwSlowDiamAuto` | ON/OFF |
| Main / jog area | Lamp "JOG BLOCKED – ROLL TOO BIG" | `JogInhibit` | |
`UwSlowDown_Diam` (200) stays: it is the fallback while the paper thickness is not learned.

## 7. Download & tests (trace 20 ms)
Tags: `Velocity_M_min, VelSet, InvRef, TaglMonoTRM.RampRef, TaglMonoTRM.FFTarget,
TaglMonoTRM.FFRate, TaglMonoTRM.FFSteadyTicks, RwRatioD, RwDiam, SoftStop,
TaglMonoTRM.SlowDown, TOneDecel, JogInhibit, UwSlowDiamAct, UwDiam_Act`

1. **Retain kept:** `RwRatioD`, `RwMat_K`, `RwStopDecel` same as noted in step 0.
2. **Jog:** `RwJogMaxDiam` above the roll → jog works (FFActive 0); below the roll → nothing, lamp ON; 0 → always.
3. **S-curve:** 500 → 300 → 500 m/min with `SCurveTime` 0, 0.5, 1.0 → rounded start/end, no overshoot,
   smaller current dip (scope LCR / OTR if it records). Keep the best value.
4. **RwRatioD:** 30 s steady at 400–500 m/min → `FFSteadyTicks` > 500, speed = set ±0.3 %.
5. **Rewinder AutoStop:** `RwTargetDiam` 30–50 mm above the roll, 300–400 m/min →
   slows at `RwSlowAtDiam`, final speed before the target, stop ±2 mm. (`RwSlowDecel` must be 0.)
6. **Unwinder diameter slow-down (small parent roll):** `UwSlowDiamAct` larger at higher speed;
   slows there, final speed ≈ `UwSlowMargin_m` before `UwDiamStop`; `UwSlowDiamLatch` 1.
7. Soft stop from 400: as before (+ S-curve rounding).
Fallbacks without download: `FFEnable` OFF (old loop), `SCurveTime` 0, `UwSlowDiamAuto` OFF, `RwJogMaxDiam` 0.

## 8. After the tests (before the licence ends)
Print the program PDF to GitHub (I check it), copy the learned values into Initial Values,
back up the project + HMI (see `V7/V7_Load_Plan.md`).

## Later (not in V8)
- T-one boost: `TOneDecel` → spare digital output → T-one stop/boost input (needs the T-one manual).
- Jog breakaway (minimum reference) if jog on small rolls is still rough.
- Edit stop targets while AUTO is ON (TODO.md).
