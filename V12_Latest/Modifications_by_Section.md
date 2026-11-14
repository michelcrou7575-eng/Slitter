# Slitter D903 (Mono Canada II) — all modifications, by program section

Machine: La Meccanica Fumagalli D903, comm. 04820 · PLC Omron NX1P2 (Sysmac 1.60, PrimaryTask 4 ms) ·
HMI Weintek cMT2108X2 (EasyBuilder Pro 6.10) · Drive ATV930D30N4 · Tension Re T-one (load cells, pneumatic brakes).

**Reference program:** `Slitter_Program_261110_compressed.pdf` = V12_1110_6 (Tension Manager loaded,
`TensAOEnable` OFF).
**Running in production (11/12):** V12_1106_6 + Fix 11/11 (unwinder slow-down latch).
**Pending (next download, to add to BOTH projects):** Fix 11/11 (if not in 1110_6), Metre reset at START.

Legend: **NEW** = added · **MOD** = changed · **DEL** = removed · (folder) = package on GitHub with the code.

---

## 0. Hardware / I/O
| Signal | Address | Tag | Status |
|---|---|---|---|
| T-one Alarm 0 (pins 15-16) "tension established" | Inline DI8 IN05, pin 1.3 | `I_T_one_TensionOK` | NEW (was `I_SlowSens_PH`) |
| Side door switch | CPU IN13 | `I_Side_Door_Closed` | NEW (was `I_OverRider_PH`, photocell never installed) |
| Spare (wire 12.55) | CPU IN11 | `I_Input_11_Spare_1255` | free (was `I_RollEnd_SlowDown`, unused) |
| OverRider pressure / Hoover switch | Inline DI8 IN02 | `I_OR_Hoover_Mode` | renamed |
| AO Ch1 (option board) | `BuiltInIO://opt/#0/Ch1_Analog_Output_Value` | `AO_TOne_SetPoint` | MOD (was `Fix10Vdc`): 10 V for the pots until `TensAOEnable` |
| Encoder unit #3 Ch1 Pulse Rate | IOBus unit#3 | `PulseRate` | **missing in 1110_6 → re-map** (HMI I/O page) |
| Rewinder diameter | AD2603 Ch2 (SICK DT35) | `AI_Diam_Rewinder` | added in v6 (not on the original plan) |
| Encoder wheel | MNI40N, 1000 ppr ×4 | `EncoderWheel_Circumf` = 402 mm | MOD (was "diameter" 400) |
| Planned | external 10 V for pots, AO Ch1 → isolator → T-one 20/19 (F.37=1) | | hardware pending |
| Planned (option) | DRO on T-one 22/21 (actual tension) | | |

---

## 1. General
| Rung | Change | Version |
|---|---|---|
| 6 "10 V DC source" | DEL `Fix10Vdc := 4000` (AO Ch1 written by Tension_Manager). Rung = `T_PlcOn` → `ControlVoltage` | 1110 |
| 7 "START blocked by JOG" (ST) | `T_JogStartBlk` 2 s + `StartHeldBlk` → `StartPB_OK`; `SideDoorOpen`; `JogRun := I_Jog_PB AND NOT Slow_Inhibit AND NOT SoftStop AND NOT SideDoorOpen`; `GuardStopOK := NOT StartMotor_Cmd`; `WebBreakNow`, `GuardOpen`, **`StartBlocked`** | V9–V12_1106 |
| 8 T-one tension (ST) | NEW `TensionOK` (0.5 s on / 2 s off), `TensionSeen`, `TensWait`, `TensLostWarn` | 1106 |
| 9 Slow_Inhibit | `StartPB_OK` + NC `StartBlocked` (JOG works after a refused START) | 1106 |
| 10 Main motor start | START branch: `StartPB_OK` + NC `StartBlocked`; JOG branch: NC `JogInhibit` (roll too big), NC `SideDoorOpen` | V8–1106 |
| 11 Soft stop (ST) | STOP = soft stop (`SoftStopDecel`), 2nd press / held 1 s = immediate; START during soft stop = `SpdHold`; end-of-roll ramp (`FinalStopRamp`); **side door open while running → soft stop, START cannot cancel**; timeout 120 s | V6m–1106 |
| 12 Main motor stop | `StopNow`; JOG release; NEW `SideDoorOpen · I_Jog_PB` (JOG stops at once) | 1106 |
| 17–19 Unwinder diameter | `UwDiam_Act` from sonar; `SlowByDiam` vs **`UwSlowDiamAct`** (follows speed); `UwStopByDiam` vs **`UwStop_at_D_Val`** | V7c/V11 |

## 2. Motor_Manager
| Rung | Change | Version |
|---|---|---|
| 1 mm per pulse | uses `EncoderWheel_Circumf` (circumference) | 1101 |
| **new, before 2** | Metre counter auto reset at START (`CntResetMode` 0/1/2, `CntResetPend`, `LastRoll_m`) — (Metre_Reset) | pending |
| 2 Reset encoder counter | + own branch `CntAutoReset` → `Encoder_Reset` | pending |
| 3 SlowDown | DEL old slow-down photocell / tension branch; `AutoSlowCmd` OR `Measure_ON · SlowByDiam` | 1105 |
| 4 Stop | web break (not in JOG) OR **`EndStopNow`** | V12 |
| 5 limits | `RwJogMaxDiam`, `RwMaxSlowFallback` clamp, `RwAutoMaxSpd` (taken over at standstill) | V8/v6y |
| 8 / 9 / 20 | `JogRun` instead of raw `I_Jog_PB` | V10 |
| 11 Speed | ONE ST rung: exact 100 ms window (25 scans), `Velocity_M_min` | V9 |
| 14 (A) Ratio | `WebRatio = RwRatioD / DecelDiam` | V7 |
| 17 (B) Feed-forward (ST) | FF target = `VelSet × WebRatio`, ramps in web mm/s² (`AccelWeb`/`DecelWeb`), **S-curve** `SCurveTime`, `SpdHold`/`SoftCancelAccel`, soft stop `SoftStopDecel`, end-of-roll `FinalStopDecel`, **tension hold `TensWaitHz`** (Hz, else `TensWaitSpd`), `RwRatioD` learning (0.3 % dead band, **not during `TensWait`**), `TOneDecel` | V7–1106 |

## 3. OverRider_Manager
| Rung | Change |
|---|---|
| 2 (old roll-end photocell) | DEL — photocell never installed; IN13 reused for the side door |
| all | renames `OverRider_Hoover` / `I_OR_Hoover_Mode`; hover logic unchanged (position sensor, `OverRider_TimeON/OFF`) |

## 4. Console
| Rung | Change |
|---|---|
| 0 TIME variables | unchanged (`Fan_Timeout`, `OverRider_TimeON/OFF`) |
| 4 Passwords | unchanged (Psw 22 / 33 / 44 / 48 → popups) |

## 5. Alarms (index = HMI event)
| Rung | Change | Version |
|---|---|---|
| 0 (ST) | AlarmOn / WarningOn / counts; warnings **5, 13, 15–21**; buzzer pulses for alarms, RESET silences 1 min; **one 1 s beep per NEW warning (`AlarmMem`)** | 1106 |
| 1 (ST) | NEW sonar fault `UwSensFault` (latched) + `Thickness_Fault` | 1104 |
| 7 Web break | + branch `I_Start_PB` (START without paper → alarm 6) | 1106 |
| 10 Hub | `I_SafeGuard_Closed` removed | 1104 |
| 16 | `TensLostWarn` → **13** "web tension low / slack" (W) | 1106 |
| 17 | `UwSensFault` → **14** sonar fault (A, normal coil) | 1105 |
| 22 | `Thickness_Fault AND NOT [16]` → **17** (W) | 1104 |
| 23/24 | side door → **18** (W): START / JOG / running with door open | 1106 |
| 25/26 | front gate not closed → **19** (W): START with gate open | 1106 |
| 27 | `AutoStopDone` → **20** (W, 8 s) | 1105 |
| 28 | `AutoEnRefused` → **21** (W, 5 s); HMI macro splits unwinder / rewinder text | 1105 |
| 29–33 | message strobe; `Msg` = 33 only with no alarm and no warning (no flicker) | 1105 |
| DEL | dead rungs `I_RollEnd_PH`, `I_Roll_OK` | 1104 |

## 6. Output_Manager
| Rung | Change |
|---|---|
| 1 Motor lamp | blinks during JOG and **SpdHold** |
| 2 O_Brake | `Brake_Cmd OR BrakeHold` (T-one AUTO kept until web < 5 m/min) |
| 7 Alarm lamp | alarm blinks, warning steady |
| 11 Horn (ST) | start beep / short beeps / stop beep (HMI settings), HORN TEST, **no horn during JOG** |
| 12 2nd ramp | `JogRun` OR ManMode |
| 13 Front guard bypass | `GuardStopOK` OR TOF(`JogRun`, 100 ms) |

## 7. AutoStop_Control (2 ST rungs: part 1 sections 1–5c, part 2 sections 6–14c)
| Section | Change | Version |
|---|---|---|
| 1 | exact 100 ms tick; `MmPerPulse` from `EncoderWheel_Circumf` | v6d/1101 |
| 2 / 2b | DT35 → `RwDiam`; **one-revolution average `RwDiamRev`**, `RwWave_mm` | V9 |
| 4 / 4a / 4b | thickness learning: length windows; NEW PAPER; **long baseline + LOCK at `RwLockDiam`** | v6w/V9 |
| 5 | stop decel learning (`RwStopDecelK`) | v6g/v6u |
| 5b | slow-down decel learning; **min `RwSlowLearnMin_mm` (50)** | Fix 11/11 |
| 6 / 6b | stop / slow-down lengths (feed-forward ramp, S-curve, `FinalStopDecel`); rewinder displays; unwinder metre slow-down (**`AND NOT CntResetPend`**, release **`OR CntResetPend`** pending) | V7–V12 / pending |
| 6c | unwinder diameter slow-down follows speed; **latch released vs `UwDiamAtLatch`, latch only while running** | V7c / Fix 11/11 |
| 7 | rewinder requests; `RwResetHyst` 50 | |
| 8 | **AUTO STOP refusal** (target already reached) before "one AUTO at a time"; `UwStopLenShow` during unwinder refusal; 3-state unwinder display | 1105 |
| 9 | `AutoStopCmd` (metres **`AND NOT CntResetPend`**) | pending |
| 10 | `UnWinder_Empty`; GSM popup once per real new roll; sonar popup | V9/V10 |
| 11 | rewinder max diameter protection (always active) | v5 |
| 11b | **end-of-roll stop ramp** `FinalStopRamp` / `EndStopNow` | V12 |
| 11c | **`AutoStopDone` / `AutoStopWhy`** (4 / 2 / 8 / 1), not after JOG | 1105 |
| 13 | `BrakeHold` | v6h/v6v |
| 14 / 14b / 14c | TEACH CORE rewinder / unwinder + UNDO | v6j–v6l |

## 8. Tension_Manager (was Tension_Helper) — (Tension_Manager)
| Part | Content |
|---|---|
| Helper | kg only: `PaperGSM × WebWidth_mm × factor` (**KRAFT 0.80 / BLEACHED 0.54**, `PaperKraft`) |
| Profile | core boost %, **taper %** on the rewinder diameter, preview CORE / MID / MAX |
| Operator | trim ±10 kg (▲/▼ macros), reset when GSM / width / type changes |
| Threading | **JOG boost %** from JOG until START (`TensJogLatch`) |
| Output | rate limit `TensRate_kg_s`; AO Ch1 1–10 V = `TensMin_kg`..`TensMax_kg` when **`TensAOEnable`**, else fixed 10 V |

---

## 9. HMI (Weintek)
| Item | Content |
|---|---|
| Macro `AutoStop_HMI_Manager` | unwinder column LB-200..203, Rw entry LB-204, refusal code LW-200 (Event Log ==1 / ==2), selector OFF → AUTO buttons OFF, simulation LW-210 (16-bit) |
| Macros `Tens_Up` / `Tens_Dn` | Function keys next to TENSION SP |
| Macro `Metre_Auto_Reset` | **obsolete → delete** (PLC does it) |
| Popups | TENSION MANAGER (maintenance), paper popup (KRAFT/BLEACH, GSM, width, JOG velocity, manual kg, JOG boost, `TensWaitHz`, metre reset mode) |
| Event Log | alarms 1–21 texts; 21 split by LW-200 |
| To fix | `PulseRate` tag (re-map), formats `###.#`, delete LB-130..132 / RW-0..2 / LB-140..142 |

## 10. Drive / T-one / mechanics
| Item | State |
|---|---|
| ATV930 (192.168.137.15) | motor 40 HP / 480 V / 46 A / 1778 rpm, tuned; `UFR` back to 100 % |
| T-one | password in cabinet; F.9 = 0, F.10 ≈ 50 % SP, F.11 full scale; remote SP (F.37/38/39) pending hardware |
| Rewind shaft claw coupling | play → knocking on small rolls at low tension; rubber pads (test); 60 kg on 100 g/m² × 680 mm quiet; **repair / parts from La Meccanica** |
| Under rider | manual pressure (0.5–1 N/mm) · Over rider: PLC hover 15–20 mm |

## 11. Initial values to update (next licence session)
`RwRatioD` live (≈ 2800) · `TensWaitHz` found value · `EncoderWheel_Circumf` 402 · `RwResetHyst` 50 ·
`RwSlowLearnMin_mm` 50 · learned K / decels (optional).

## 12. Open
- Alarms rung 29: remove `ControlVoltage` (messages cycle during E-stop).
- `PulseRate` re-map.
- Tension hardware (10 V supply, isolator), then `TensAOEnable` + T-one F.37/38/39.
- Coupling repair; operator manuals EN/FR (waiting for GO).
