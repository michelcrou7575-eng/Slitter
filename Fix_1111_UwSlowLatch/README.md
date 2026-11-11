# Fix: UwSlowDiamAct stuck at 1510 (machine stuck in slow-down)

## Cause
1. `UwSlowDiamCalc` jumped to the 1500 clamp (huge slow-down length: most likely a very low learned
   slow-down decel `RwSlowDecelK` from a slow ramp, section 5b).
2. The latch froze `UwSlowDiamAct` = 1510; release needed `UwDiam_Act` > 1540 → never → `SlowByDiam` always TRUE.

## Immediately (online)
1. Note `UwSlowDiamCalc`, `RwSlowDecelK`, `RwSlowDecelLrn`, `RwSlowDecel`, `RwMat_K`, `DecelWeb`.
2. Press **RwLearnReset** (clears the learned decels), then write `UwSlowDiamLatch` := FALSE.
   (Or UNWINDER AUTO-SLOW OFF → fixed `UwSlow_at_D_Val`, then clear the latch.)

## Load the fix
1. Global: paste `Globals_paste.txt` (`RwSlowLearnMin_mm` 50, Retain); add to Externals.
2. Internal: paste `Internals_paste.txt` (`UwDiamAtLatch`).
3. AutoStop rung 1, section 6c: replace the 2 latch blocks with `AutoStop_part2_6c_latch_FIX.st`.
4. AutoStop rung 0, section 5b: replace the `IF (SlowDecelMeas_mm >= RwDecelMin_mm)` line with the 2 lines
   of `AutoStop_part1_5b_learn_FIX.st` (keep `AND (SlowDecelMeas_mm <= RwDecelMax_mm) THEN` below).
5. Build → Transfer.

## Test
- Run a roll, auto slow-down by diameter: STOP AT Ø shown, then a new parent roll → SLOW AT Ø again (latch released).
- AutoStop by metres, then load a new roll → `UwSlowDiamAct` follows `UwSlowDiamCalc` again.
- Watch `RwSlowDecelK` after a few auto slow-downs: should stay plausible (≈ decel 100–500 mm/s2 / diameter).
