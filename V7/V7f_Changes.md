# V7f: S-curve on the AUTO feed-forward ramps + T-one decel signal (10/30)

## Why
The T-one (load cells + pneumatic brakes) only reacts after the tension has dropped,
plus the air delay. A ramp that starts at full decel at once gives the biggest tension
dip; with a loose tension setting the web can go slack. The S-curve builds the decel
up over `SCurveTime` (and rounds it off before the target), so the brake can follow.

## How (Motor_Manager rung B)
`FFRate` (reference per 4 ms scan) changes at most `FFJerk = Step × 0.004 / SCurveTime`
per scan. Near the target the rate is limited to `SQRT(2 × FFJerk × distance)`, so it
arrives with rate 0: no overshoot (checked in simulation, also with ±2 counts pot noise).
- Same max ramp as before (AccelWeb / DecelWeb / SoftStopDecel), the ramp only takes
  `SCurveTime` longer. Example 500 → 300 m/min at 250 mm/s²: 13.3 s → 13.8 s.
- `SCurveTime` 0 = plain V7a ramp. Clamped 0–2 s. Default 0.5 s.
- AutoStop section 6 adds the extra length `(SpdRef − SpdFinal)/2 × SCurveTime`
  (500 → 30 m/min, 0.5 s: +2 m) to the slow-down, so the slow-down point stays right.
- `TOneDecel` = line ramping down (> 1 % above the target) or soft stop. For a
  T-one "stop / boost" input on a spare PLC output (see below).

## Load
1. Globals: `V7f_Globals_paste.txt` (`SCurveTime` 0.5 Retain, `TOneDecel`).
2. Motor_Manager internals: `V7f_Locals_paste.txt` (`FFRate`, `FFRateSet`, `FFJerk`).
3. Rung B: replace all of it with `V7_MotorManager_FF_rung.st` (includes V7a + V7b + V7f).
4. AutoStop_Control: replace all of it with `AutoStop_Control_V7.st`
   (includes V7e line 401 + V7f slow-down length; then paste V7c block again if loaded
   separately — or paste V7c after this).
5. HMI page 22: `SCurveTime` "S-CURVE (s)", Format limits 0–2, 1 decimal.

## T-one boost (option, needs the T-one manual + a spare digital output)
Map `TOneDecel` to a spare output (Output_Manager, one coil) and wire it to the T-one
input for stop / quick stop / inertia compensation / gain boost, if it has one.

## Test
- 500 → 300 → 500 m/min with SCurveTime 0, then 0.5, then 1.0: trace `RampRef`,
  `TaglMonoTRM.FFRate`, `Velocity_M_min`, `TOneDecel`; scope LCR / OTR.
  Expected: smaller current dip and faster settling with the S-curve.
- Rewinder AutoStop: slows down, reaches the slow speed before the target, stops on target.
