# Mono Canada II Slitter: Project Handover (state on 2026-10-19)

## 1. Machine and hardware
- **Machine:** La Meccanica Fumagalli single-shaft trimmer/slitter "Mono Canada II", job 04820KA001 (HMI title shows "D903").
- **PLC:** Omron NX1P2-9024DT1, Sysmac Studio 1.60 (**trial licence**, about 18 days left on 10/19). PrimaryTask 4 ms, one program `TaglMonoTRM`.
  - Option board NX1W-MAB221: Ch1 = Pot1 work speed, Ch2 = Pot2 final speed, AO1 = fixed 10 V for the pots, AO2 = inverter reference.
  - NX-PF0730 power feed; **NX-AD2603** (AI Ch1 = unwinder sonar, P+F UC2000; **AI Ch2 = SICK DT35 rewinder**); NX-EC0122 encoder.
  - EtherCAT: Phoenix IL EC BK + DI8 + DO8.
- **Inverter:** ATV930D30N4 (30 kW). Stop = run command (DI1) drops and the ATV930 stops with its own ramp. There is **no motor brake**: `O_Brake` is the unwinder reel-brake enable. STO via safety relay 4KA2.
- **HMI:** Weintek cMT2108X2, EasyBuilder Pro 6.10.02, project `.cmtp`.
- **Network:** PLC **192.168.250.10**, HMI 192.168.250.11, laptop 192.168.250.200. Switch 24SW1 is also linked to the factory network. A SEVIO remote-access router (24SW2) gives the machine builder remote access.

## 2. Backups (keep on USB)
- Controller backup set: `NXBackup.dat` + `RestoreCommand.ini` + `AutoloadCommand.ini`. Never leave it on the PLC's own SD card.
- "Mono Canada II from PLC" `.smc2`: verified identical to the PLC.
- Original HMI upload `.cxob` and the original HMI project `Weintek_HMI_Slitter_Org.cmtp`.
- Watch list of old Retain values (see §6).

## 3. Machine-builder change found on 12/19/2024 (KEEP)
- Output_Manager rung 13: safety bypass `O_FrontGuard_ByPass` (relay 23KA4) is now ON only when the motor is stopped or the jog button is held (TOF `T_ByPassProtOff`, 100 ms).
- Rung 11: the horn sounds during slow-down only while running and not stopping.
- Already merged into the modified project.

## 4. Modification: logic (verified on print 1019: identical to original except intended changes)
- **Rewinder diameter (DT35):** 0 V = near (fail-safe). Calibration: `RwDist0V` 0, `RwDist10V` 750, `RwAxisDist` 675.3 (100 mm core), `RwRawMin` 10, `RwRawMax` 3900. Plausibility check `RwDist > RwAxisDist`, diameter clamped ≥ 0.
- **Section `AutoStop_Control`** (ST, latest **v6d**, see `v6d/v6d_Changes.md`):
  1. tick / `MmPerPulse`
  2. DT35 → filtered distance → `RwDiam` (fault detection)
  3. speed from encoder
  4. material learning `RwMat_K` (with paper-thickness plausibility)
  5. stop-deceleration learning `RwStopDecel` (with plausibility)
  6. stop/slow lengths (speed-compensated)
  6b. live displays `RwSlowAtDiam`, `RwStopAtDiam`, `UwSlow_at_Metre`, latched `UwSlowReq`
  7. rewinder requests
  8. Unwinder/Rewinder AUTO interlock + single display `SlowAtDisp` / `SlowAtMode` / `SlowAtShow`
  9. **12SA5 selector (`I_AutoStop_OS`) = master** → `AutoSlowCmd` / `AutoStopCmd`
  10. `UnWinder_Empty`
  11. **max diameter protection, always active** (`RwMaxDiam`, fallback `RwMaxSlowFallback`, display `RwMaxSlowAtDiam`), OR-ed after the master
  12. learning supervision → `RwLearnFault`, `RwThick_mm`
- **Motor_Manager rung 3:** `SlowDown` = end-of-roll photocell OR `AutoSlowCmd` OR (`Measure_ON` · `SlowByDiam`).
  **Rung 4:** `Stop` = paper break OR `AutoStopCmd` OR (`Measure_ON` · `UwStopByDiam`).
- **Console rung 3:** `CountReset_Req` = `I_AutoStop_OS` · `UwStopEnable` · meters ≥ stop length.
- **Alarms (ladder, set/reset latched):** [10] DT35 fault (Rewinder AUTO **or motor running**, v6d), [11] rewinder max diameter, [15] unwinder empty, [16] learning fault (rungs to add, see v6d C2). All four drive the lamp and the buzzer (v6d C4). Encoder-stopped alarm [8] re-enabled (v6d C5). The tub-off alarm was removed (no physical input).
- **Naming convention:** Uw = unwinder, Rw = rewinder; `_mm`, `_m`, `_Pls` (pulses), `_Pps`, `_Pps2`. The v6 rename list is in `AutoStop_v6_Renames.txt`.

## 5. Files delivered (latest versions)
- `v6d/AutoStop_Control_v6d.st`: code to paste into the ST box (replaces v6c).
- `v6d/v6d_Locals_paste.txt` (6 new Internals), `v6d/v6d_Changes.md` (initial values, ladder edits, commissioning checks).
- `AutoStop_v6_Renames.txt`: Internals + 5 globals to rename.
- `v6b_Globals_paste.txt` / `v6b_Externals_paste.txt` (`RwMaxSlowFallback`, `RwMaxSlowAtDiam`).
- `v6c_Globals_paste.txt` (8), `v6c_Externals_paste.txt` (8), `v6c_Locals_paste.txt` (6).
- Paste formats: Globals = Name, Type, Initial, AT, Retain, Constant, Network Publish, Comment. Externals = Name, Constant, Comment. Internals = Name, Type, Initial, AT, Retain, Constant, Comment. No trailing empty line.

## 6. Retain values to restore (renamed variables lose their value)
Values read from the PLC on 10/19. Enter them as **Initial Values** before the transfer, or set them online right after.

Names below are the names **in the program (print 1019_1)**. An earlier version of this table used names that do not exist in the program (UwCoreDist, UwCoreOD, DiamStop, Stop_At_Meter, ManSpd_SP). Do not use those for the HMI Find/Replace.

| Name in program | Value | Initial in print 1019_1 |
|---|---|---|
| Encoder_Pulse | **1000** | blank → **set** |
| EncoderWheel_Diam | 400 | 400 ✓ |
| UwCoreDistance (sonar distance to empty core) | **785.56** | 785.56 ✓ |
| UwCoreDiameter (core OD) | **101** | 100 → **set** |
| UwSlowDown_Diam | 200 | 200 ✓ |
| UwDiamStop | 110 | blank → **set** |
| DeadZone / Reading_Max | 60 / 2000 | ✓ |
| UwStop_At_Meter | 5020 (1019_10 uses 5100) | 5100 in 1019_10 |
| UwSlowMargin_m | 2 → 10 | blank → **set 10** |
| Fan_Timeout | **0.5** (minutes) | ✓ |
| OverRider_TimeON / OFF | 0.05 / 0 (1019_10 uses 0.01 for OFF) | 0.05 / 0.01 in 1019_10 |
| JogSpd_SP (jog = HMI "SAFETY SPEED", clamped 10–70) | 10 | 10 ✓ |
| Measure_ON | True | ✓ |
| VelMax | 800 | blank → **set** |

- `Core_Measure` initial must be **False** (otherwise it re-teaches the core at the first scan).
- The ramps re-initialise themselves through `Init_Ramp`.

## 7. Open items before or at the transfer
0. **Latest project: print 1019_10.** v6d is applied except the alarm lamp (Output_Manager rung 7) and `UwCoreDiameter` = 101; see the status table at the end of `v6d/v6d_Changes.md`.
1. Apply the v6 renames, then v6b + v6c + v6d pastes, the v6d ST code, and the ladder edits in `v6d/v6d_Changes.md` (alarm-16 rungs, alarm 10/15 rungs, lamp/buzzer, encoder alarm), and set the initial values in §6. **F7** = 0 errors. Offline Comparison against "from PLC": only the intended differences.
2. ~~Alarms rung 20: `StartMotor_Cmd` → `Measure_ON`~~ now part of v6d (C3).
3. Decide: `UwStopEnable` initial (False = meter stop off after transfer), `RwMaxDiam` (1330; 1300 is safer), `UwEmptyHyst` (5 mm is small; 50–100 suggested), `RwMaxSlowFallback` (1250).
4. After the transfer, do the commissioning checks in `v6d/v6d_Changes.md` §E (AI Ch2 = 4000 counts at 10 V, slow-down length, stop learning, encoder alarm).
5. Transfer order: record values (old project online) → full transfer (machine stopped) → check values in Watch → HMI.

## 8. HMI status and to-do
- Language EN/FR working: flags on window 200 (Combo Buttons). Group 1 = Set Word LW-9134 (1 EN, 2 FR); Group 2 = macro **Save_Language** (ID 3). **Restore_Language** (ID 2) runs at start-up from RW-0. In the Compile dialog, tick Language 3 and set start-up language ENGLISH.
- Alarm Bar = Event Log. Each `AlarmCodeSV[n]` must appear once, with "Use label library":
  - **[10]** REWIND DIAMETER SENSOR FAULT
  - **[11]** REWINDER MAX DIAMETER (fix the old "REWINDER" event)
  - **[15]** UNWINDER EMPTY (fix)
  - **[16]** REWINDER LEARNING FAULT (new)
  - Delete the duplicate "UNWINDER" event on [10].
- **Every renamed published global must be updated in EasyBuilder** (Find/Replace Addr) in the **same session as the PLC transfer**. A missing or unpublished tag gives "Device No Response" for the whole panel. Close and restart the simulator after every tag change.
- Pages:
  - Page 1: label the unlabelled field (`UwCoreOD`).
  - Page 3: "Rewinder slowdown max" = `RwMaxSlowFallback`; add a display of `RwMaxSlowAtDiam`.
  - IN/OUT page: rename "AUTO SLOW DOWN BY METERS" to "AT ROLL END".
  - Add a **"REWINDER DT35 / LEARNING"** page (calibration, margins, `RwTrim`, learning displays `RwThick_mm` / `RwMat_K` / `RwStopDecel`, reset-learning buttons) behind the password, with input limits.
  - Optional: a flashing frame on the eraser button (`CountReset_Req`); grey out unused setpoints (interlock).

## 9. Key lessons
- Retain + rename = value lost.
- HMI tags must exist **and** be Publish Only in the running PLC.
- PLC first, then HMI.
- Synchronize/Compare before every transfer.
- Online edit is not possible for I/O Map or unit settings.
- Omron reserves the `P_` prefix for system variables.
