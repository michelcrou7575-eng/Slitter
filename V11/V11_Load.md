# V11 package (10/31) — V10 + V11 in ONE download, on top of the printed V9
(`Slitter_1030_V9_compressed.pdf`; no V10 print on GitHub yet). Rung numbers = printed V9.
Files from `V10/` are used where V11 does not replace them.

| # | Change | From |
|---|---|---|
| 1 | General rung 11: delete leftover `I_Start_PB` NC (START held + JOG release did not stop) | V10 |
| 2 | `JogRun` (JOG really running) instead of the raw JOG button: no guard bypass / 2nd ramp / FF drop during a run | V10 |
| 3 | Thickness long baseline restarts if the encoder goes 2 m back | V10 |
| 4 | Sonar OFF popup (`SonarAsk` / `SonarAskYes`) | V10 |
| 5 | **Guard bypass after a stop only when the web has really stopped** (\|speed\| < 2 m/min for 0.5 s) | V11 |
| 6 | **Unwinder stop command earlier** (`UwStopCmdDiam`) so the web stops AT `UwDiamStop` | V11 |
| 7 | **Unwinder display, 3 states:** STOP LENGTH / SLOW AT Ø / STOP AT Ø (`UwShowStopDiam`) | V11 |

## 1. Variables
- **Global Variables + Externals:** `V10/V10_Globals_paste.txt` (2) + `V11/V11_Globals_paste.txt` (2):
  `SonarAsk`, `SonarAskYes`, `UwShowStopDiam`, `UwStopCmdDiam`.
- **TaglMonoTRM Internals:** `V10/V10_Internals_paste.txt` (3) + `V11/V11_Internals_paste.txt` (2):
  `SonarRunMem`, `SonarInit`, `JogRun`, `T_GuardStill` (**TON**), `GuardStopOK`.

## 2. General
| Rung | Action | File |
|---|---|---|
| 7 "START blocked by JOG" (ST) | replace all | **`V11/General_rung7_startblock_V11.st`** (JogRun + GuardStopOK) |
| 11 "Main Motor stop", JOG-release branch | delete `I_Start_PB` (NC) → `I_Jog_PB↓ — Slow_Inhibit(NC) — StartPB_OK(NC)` | |
| 18 `UwStopByDiam` compare `<=` | In2 `UwDiamStop` → **`UwStopCmdDiam`** | |

## 3. Motor_Manager
| Rung | Action | File |
|---|---|---|
| 8 "Updating potentiometer value" | contact `I_Jog_PB` (NC) → `JogRun` (NC) | |
| 14 "Ratio drive counts…" (ST) | replace all | `V10/MotorManager_rungA_V10.st` |
| 17 "Slow adaptation of RwRatioD…" (ST) | replace all | `V10/MotorManager_rungB_V10.st` |

## 4. AutoStop_Control
| Rung | File |
|---|---|
| 0 | `V10/AutoStop_Control_V10_part1_rung0.st` (477 lines) |
| 1 | **`V11/AutoStop_Control_V11_part2_rung1.st`** (≈ 560 lines: sonar popup + section 8 V11) |

## 5. Output_Manager
| Rung | Action |
|---|---|
| 12 "Second acc/dec ramp" | contact `I_Jog_PB` → `JogRun` (ManMode branch unchanged) |
| 13 "Front guard bypass" | top branch contact `StartMotor_Cmd` (NC) → **`GuardStopOK` (NO)**; TOF input `I_Jog_PB` → `JogRun` |
Result: `O_FrontGuard_ByPass = GuardStopOK OR TOF(JogRun, 100 ms)`.

## 6. HMI
- Unwinder column, same place: numeric **display `UwStopCmdDiam`** (####), label "STOP AT Ø [mm]",
  visibility **`UwShowStopDiam`** ON (with `UwShowStopLen` / `UwShowSlowDiam` as before).
- Sonar popup: Direct Window on `SonarAsk`; NO = `SonarAsk` Set OFF; YES = `SonarAskYes` Set ON.

## 7. Build → 0 errors, download, tests
1. **Guard bypass after STOP at 400 m/min:** `O_FrontGuard_ByPass` stays **OFF** during the ramp-down and the
   pull-back, comes **ON** about 0.5 s after `Velocity_M_min` is within ±2 m/min. At power-up (stopped): ON after 0.5 s.
2. **JOG at standstill:** works, bypass ON while JOG held (as before). **JOG during a run:** bypass stays OFF, `O_AccDec2` OFF.
3. **Hold JOG, hold START, release JOG** → motor stops.
4. **Unwinder small roll (sonar ON, normal run):** SLOW AT Ø shown → at the slow-down it switches to STOP AT Ø
   (`UwStopCmdDiam`, a few mm above `UwDiamStop` at final speed) → the web stops at ≈ `UwDiamStop` (check `UwDiam_Act`).
5. **Sonar popup** after a stop with the sonar OFF (never while running).
6. Then print the PDF to GitHub for the final check + backups.
