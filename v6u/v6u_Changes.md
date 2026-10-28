# v6u: very short stops are not learning faults (trace 10/28/2026)

## Trace GSM20261028135528 (Traces/), base = print 1027 + v6t
| Time | Event | Start speed | Stop length | Result |
|---|---|---|---|---|
| 12:26 | 3 jog runs (StopLearnValid = 0) | 9–16 m/min | — | not learned (OK) |
| 12:27:20 | auto slow-down 200 → 24.6 m/min | | | slow-down learned |
| **12:28:06** | **auto stop at final speed** | **4030 pps ≈ 23 m/min** | **102 pulses ≈ 10 mm** | **StopFailCnt 3 → 4 → alarm 16** |
Thickness learning fine: `ThickWin_mm` 0.102 mm, `LearnFailCnt` 0. `RwStopDecelK` already learned (1.70).

**Cause:** at the final speed the web stops in ≈ 10 mm. The reaction distance (`StopStartSpd × RwTreact`) is already ≥ 12 mm, so no decel can be computed → counted as a failure. Even with a smaller `RwTreact` the result is > 10 000 mm/s² → above `RwDecelMax_mm` → failure again.
Such a stop is not a problem: the auto stop lands within ≈ 1 cm.

## Change (AutoStop_Control section 5 only)
- Stop shorter than the reaction distance → ignored (no learning, **no fault**).
- Measured decel above `RwDecelMax_mm` (very fast stop) → ignored (**no fault**).
- Measured decel below `RwDecelMin_mm` (stop abnormally **long**: slipping, encoder problem) → counts toward alarm 16, as before.
- Plausible → learned, counter reset (as before).

## Steps
1. Replace the AutoStop_Control ST with `AutoStop_Control_v6u.st` (= v6t + this change; uses `RwCoreDiameter`). No new variable.
2. F7 → transfer → `RwLearnReset` not needed; just ALARM RESET once `StopFailCnt` is cleared: Watch tab `TaglMonoTRM.StopFailCnt` = 0 (or `RwLearnReset`).
