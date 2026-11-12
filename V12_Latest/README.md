# V12_Latest — latest version of every program section

Source: `Slitter_Program_261110_compressed.pdf` (V12_1110_6) + Fix 11/11 + Metre reset (pending), assembled 11/12.

| File | Section | Content |
|---|---|---|
| `1_General.st` | General | rungs 0–19 (ST verbatim; ladder as equations) |
| `2_Motor_Manager.st` | Motor_Manager | rungs 0–20 + **1b metre reset (pending)**; rung 17 = feed-forward with tension hold |
| `3_OverRider_Manager.st` | OverRider_Manager | rungs 0–4 (ladder as equations) |
| `4_Console.st` | Console | rungs 0–6 |
| `5_Alarms.st` | Alarms | rung 0/1 ST; rungs 2–33 as equations, alarm numbers 1–21 |
| `6_Output_Manager.st` | Output_Manager | rungs 0–13 (horn ST) |
| `7a_AutoStop_Control_part1_rung0.st` | AutoStop rung 0 | sections 1–5c (+ `RwSlowLearnMin_mm`) |
| `7b_AutoStop_Control_part2_rung1.st` | AutoStop rung 1 | sections 6–14c (latch fix, refusal, AutoStopDone, metre-reset guards) |
| `8_Tension_Manager_rung0.st` | Tension_Manager | complete rung 0 |

Notation in ladder lines: `A AND NOT B -> ( C )` coil, `(S)` / `(R)` set / reset, `RISING()` / `FALLING()` edge.
Lines marked **pending** are not in 1110_6 yet (Metre_Reset package, `OR CntResetPend` in section 6b).
The PDF printout stays the reference for the exact ladder graphics.
