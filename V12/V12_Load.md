# V12 package (11/01) — end-of-roll stop ramp

Built on V11 as loaded, **with your tag names** (from `Slitter_Globals.txt`): `UwStopDiam_Limit` (stop limit,
operator), `UwStop_at_D_Val` (stop command point, display), `UwSlow_at_D_Req` (AUTO SLOW Ø switch),
`UwSlow_at_D_Val` (fixed slow-down Ø), `UwAutoStopEnable`, `UwStop_at_M_Val`, `UwSlow_at_M_Val/_Req`,
`RwSlow/Stop_at_D_Val/_Req`, `UwStopLenShow`, `UwSlowDiamShow`, `UwStopDiamShow`, `I_Jog_PB`.

## Why
A normal end-of-roll stop (unwinder diameter / metres, rewinder target, rewinder max) dropped the run
command at once → the **drive DEC ramp** (DEC 3 s = 20 Hz/s, rounding 10 %): from the final speed on a
1110 mm rewinder roll that is ≈ **8 m/s² of web in 0.2 s** (100 m/min: 4 Hz), hard on the rewinder gearbox.

## What
- These stops now run the **soft stop** at **`FinalStopDecel` = 500 mm/s²** (100 m/min → 3.3 s, ≈ 2.8 m;
  30 m/min → 1 s, ≈ 0.3 m), S-curve rounded; the run command drops below `SoftStopEndSpd` (5 m/min).
- **Stop lengths use the same ramp** (section 6: `StopLen_Pls`, `StopLenFinal_Pls` + S-curve), so the stop
  command comes earlier and the web still stops at `RwTargetDiam` / `UwStopDiam_Limit`
  (`UwStop_at_D_Val`, `RwStop_at_D_Val` and the slow-down points follow automatically).
- **START cannot cancel** an end-of-roll ramp (no speed hold).
- **Immediate stop as before** (`EndStopNow` → `Stop`): `FinalStopDecel` = 0, `FFEnable` OFF, ManMode, JOG,
  machine stopped (start blocked), and **safety net** during the ramp: unwinder 10 mm below
  `UwStopDiam_Limit`, or rewinder at `RwMaxDiam`. Paper break, STOP held 1 s, E-stop, thermals: unchanged.

## Load (rung numbers = printed V9)
1. **Global Variables + Externals:** `V12_Globals_paste.txt` — `FinalStopDecel` 500 **Retain**, `FinalStopRamp` (lamp).
2. **TaglMonoTRM Internals:** `V12_Internals_paste.txt` — `EndStopReq`, `EndRampOK`, `EndRampHard`, `EndStopNow`.
3. **General rung 10** "Soft Stop Process" (ST): replace all with `General_rung10_softstop_V12.st`.
4. **Motor_Manager rung 4** "Checking the stop point" (ladder): delete the 2 branches
   `AutoStopCmd` and `Measure_ON — UwStopByDiam`, add ONE branch **`EndStopNow`** (NO) in parallel with the
   paper-break branch → `Stop`.
5. **Motor_Manager rung 17** (rung B, ST): replace all with `MotorManager_rungB_V12.st`
   (one change: `StepDec` uses `FinalStopDecel` while `SoftStop AND FinalStopRamp`).
6. **AutoStop rung 1** (ST): replace all with `AutoStop_Control_V12_part2_rung1.st`
   (= your renamed V11 rung 1 + section 6 stop lengths + new section 11b; old `(* ==== …` notes removed).
   Rung 0 unchanged.
7. **HMI:** page 22 numeric `FinalStopDecel` "END STOP RAMP (mm/s²)", ####, limits 0 / 50–2000;
   lamp `FinalStopRamp` "END-OF-ROLL STOP" (optional).

## Tests (trace 20 ms: `Velocity_M_min, VelSet, TaglMonoTRM.RampRef, SoftStop, FinalStopRamp, Stop,
StartMotor_Cmd, UwDiam_Act, UwStop_at_D_Val, RwDiam, RwStop_at_D_Val`; scope LCR/OTR if possible)
1. **Unwinder small roll, POT2 100 m/min:** slow-down → `UwStop_at_D_Val` shown → at it `FinalStopRamp` 1,
   `SoftStop` 1, linear ramp ≈ 30 m/min/s, stop ≈ at `UwStopDiam_Limit` (no jolt, current/torque smooth).
2. **Same with POT2 30 m/min:** ≈ 1 s ramp.
3. **Rewinder AUTO, target 30–50 mm above the roll:** stops at the target ±2 mm, smooth.
4. **START during that ramp:** ignored. **STOP button during it:** immediate stop (2nd press rule).
5. **`FinalStopDecel` 0:** old hard stop (fallback). **FFEnable OFF:** old hard stop.
6. Start attempt after an end-of-roll stop (still at the limit): blocked as before.
