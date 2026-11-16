# V12_Latest — latest version of every program section

Source: `Slitter_1112PDF_C_compressed (1).pdf` = **V12_1112_1** (Fix 11/11 + metre reset at START loaded), updated 11/12.
`8_Tension_Manager_rung0.st` re-taken from `Slitter_Program_1114_compressed.pdf` (TensSPMin_kg, decel boost) + the 11/15 changes below.

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
The PDF printout stays the reference for the exact ladder graphics.

## V12_1115 changes (to load in Sysmac / EasyBuilder)

**Tension_Manager** (`8_Tension_Manager_rung0.st`)
- 8a: AUTO -> MANUAL bumpless: `TensManual_kg := TensAutoBase` (last AUTO level, without JOG / decel boost), `TensTrim_kg := 0`.
- 8: `TensAutoBase := TensTarget;` in the AUTO branch.
- Trim limit +/-20 kg (section 5; was +/-10). HMI ▲/▼ trim macros: limits -20 / +20.
- `TensTrimPos := TensTrim_kg > 0.05;` -> HMI Bit Lamp (no shape, state 0 = blank, state 1 = "+") just left of the trim Numeric (Numeric left-aligned).
- Header comment: old `TensAOEnable` line removed (global `TensAOEnable` no longer used, can be deleted).
- Internals: `Internals_1115_Tension_Manager_paste.txt`.

**Alarms** (`5_Alarms.st`)
- Rung 0: `WarnLastIdx := Index_A;` on each new warning (show it on a maintenance screen to find the flashing warning).
- Rung 6 (warning 5, front guard moving): `ControlVoltage` + `T_GuardMove` TON 500 ms before the coil (sensor flicker flashed the warning bar + 1 s beep).
- Internals: `Internals_1115_Alarms_paste.txt`.

**Globals**
- New: `Globals_1115_paste.txt` (`TensTrimPos`, `WarnLastIdx`).
- Initial values: `TensMin_kg` 10.0 -> **0.0**, `TensMax_kg` 100.0 -> **250.0** (T-one F.34 full scale; with 100 a memory clear would give 2.5 x the tension).
- Comments: `TensMin_kg` "T-one set point at 1 V (= 0 kg, F.38)", `TensMax_kg` "at 10 V (= 250 kg, F.34/F.39)",
  `CntResetMode` "1 = new parent roll, 2 = after auto-stop, 4 = manual (HMI lamps .0/.1/.2)", `TensTrim_kg` "+/-20".

**AutoStop_Control rung 1** (`7b_AutoStop_Control_part2_rung1.st`)
- 8a: 12SA5 (`I_AutoStop_OS`) switched ON with neither `UwStopEnable` nor `RwStopEnable` -> `UwStopEnable := TRUE` (metres by default). Edge only, placed above the refusal checks.
- Internals: `Internals_1115_AutoStop_paste.txt` (`AutoOSMem`).

**Output_Manager** (`6_Output_Manager.st`, horn ST)
- `O_AcousticSignal`: use `Alarm_Array[5] AND Clock1s` instead of the raw guard sensors (filtered like the warning).

Done in 1114: `PulseRate` mapped, `CntAutoReset` internal Retain False.

## V12_1116 changes

**Motor_Manager** (`2_Motor_Manager.st`, before `Pot1_Mem` / `Pot2_Mem`)
- Speed pots filtered (`Pot1F`/`Pot2F`, factor 0.05 per 4 ms scan = ~80 ms) with a 3-count hysteresis (`Pot1Hold`/`Pot2Hold`).
  Trace 11/16: pot noise +/-0.4 % made `InvRef` flicker and reset `FFSteadyTicks` 94 times in 110 s, so the `RwRatioD` adaptation stalled (web speed -2 % on a big roll).
- Manual mode: `Speed_Display` / `LowSpd_Display` from the filtered pots (the drive still gets the raw pot in ManMode, line `InvRef := Pot1_Work_Velocity`).
- Internals: `Internals_1116_Motor_Manager_paste.txt`.
