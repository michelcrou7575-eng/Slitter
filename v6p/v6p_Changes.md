# v6p: reset of the learned decelerations

## Problem (10/27/2026)
Writing `RwStopDecel` = 0 in the Watch tab does not hold: section 5c recalculates it every scan from `RwStopDecelK` × diameter. Writing `RwStopDecelK` = 0 does not hold either: the v6f "one-time seed" refills it from `RwStopDecel`. The two values keep each other alive, so the stop learning could never be reset.

## Change (AutoStop_Control section 5c only)
- Seed removed (it was only needed once, for the v6f → v6g migration).
- New global **`RwLearnReset`** (BOOL, Publish Only, not Retain). When TRUE, the PLC clears `RwStopDecelK`, `RwStopDecel`, `RwSlowDecelK`, `StopFailCnt` and resets the bit.

## Steps
1. Global Variables: paste `v6p_Globals_paste.txt`. Program Externals: paste `v6p_Externals_paste.txt`.
2. Replace the AutoStop_Control ST with `AutoStop_Control_v6p.st` (= v6l + the change above).
3. F7 = 0 errors → transfer (no Retain variable renamed).
4. Watch tab: `RwLearnReset` = TRUE → `RwStopDecelK`, `RwStopDecel`, `RwSlowDecelK` read 0 and stay 0.
5. Optional HMI: a "RESET LEARNING" button (Set Bit, Set ON) on window 44, visible only when `MotStop`.

## After the reset
- Until re-learned: the stop length uses `RwTstopDef` (3 s) and the slow-down uses `DecelCoarse` (conservative). `GSM_Learned_OK` = FALSE.
- Re-learned at the next auto slow-down and the next stop ≥ `RwMinLearnSpd` (50 m/min). Soft stops end at `SoftStopEndSpd`, so they don't count.
- Do the reset after every change of `DecelCoarse`, `SoftStopDecel` or the drive settings.
