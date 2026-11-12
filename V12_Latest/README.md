# V12_Latest — latest version of every program section

Source: `Slitter_1112PDF_C_compressed (1).pdf` = **V12_1112_1** (Fix 11/11 + metre reset at START loaded), updated 11/12.

| File | Section | Content |
|---|---|---|
| `1_General.st` | General | rungs 0–19 (ST verbatim; ladder as equations) |
| `2_Motor_Manager.st` | Motor_Manager | rungs 0–20 (rung 1 also holds the metre reset at START); rung 17 = feed-forward with tension hold |
| `3_OverRider_Manager.st` | OverRider_Manager | rungs 0–4 (ladder as equations) |
| `4_Console.st` | Console | rungs 0–6 |
| `5_Alarms.st` | Alarms | rung 0/1 ST; rungs 2–33 as equations, alarm numbers 1–21 |
| `6_Output_Manager.st` | Output_Manager | rungs 0–13 (horn ST) |
| `7a_AutoStop_Control_part1_rung0.st` | AutoStop rung 0 | sections 1–5c (+ `RwSlowLearnMin_mm`) |
| `7b_AutoStop_Control_part2_rung1.st` | AutoStop rung 1 | sections 6–14c (latch fix, refusal, AutoStopDone, metre-reset guards) |
| `8_Tension_Manager_rung0.st` | Tension_Manager | complete rung 0 |

Notation in ladder lines: `A AND NOT B -> ( C )` coil, `(S)` / `(R)` set / reset, `RISING()` / `FALLING()` edge.
Open: `PulseRate` I/O mapping (HMI I/O page), `CntAutoReset` Retain → False.
The PDF printout stays the reference for the exact ladder graphics.
