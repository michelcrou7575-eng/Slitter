# V12_1106_6 — changes since V12 (1101) — program as running on the PLC

Reference printout: `Slitter_Program_1106_6_compressed.pdf` (and 1105 / 1106_3 / 1106_5 for the steps).
Project file: `04820KA001 Mono Slitter 903_V12_1105.smc2` (upload the 1106_6 `.smc2` + Controller backup too).
This **replaces** the earlier drafts in `T-one_TensionOK/` and `Alarms_1104/` (different alarm numbers there).

## 1. Hardware / I/O
| Input | Address | Tag | Use |
|---|---|---|---|
| T-one Alarm 0 (pins 15-16) | Inline DI8 IN05, pin 1.3 | `I_T_one_TensionOK` | tension established (was `I_SlowSens_PH`) |
| Side door switch | CPU IN13 (`Input_Bit_13`) | `I_Side_Door_Closed` | was `I_OverRider_PH` (photocell never installed) |
| Spare | CPU IN11 (wire 12.55) | `I_Input_11_Spare_1255` | free |
| OverRider pressure switch | Inline IN02 | `I_OR_Hoover_Mode` | renamed (rider "Hoover" mode) |

- T-one: F.9 = 0, F.11 = full scale, F.10 ≈ 50 % of set point, F.72 = 0 (password: in the cabinet, not here).
- Encoder: `EncoderWheel_Circumf` = 402 mm (circumference, not diameter).
- ATV930: IP 192.168.137.15 (laptop 192.168.137.200). Low-speed torque: `UFR` 100 → 120 → 140 % (see TODO).

## 2. Tension check (T-one Alarm 0)
- General rung 8: `TensionOK` (0.5 s on / 2 s off), `TensionSeen` latch, `TensWait`, `TensLostWarn`.
- Motor_Manager rung 17: during `TensWait` the feed-forward target is held at **`TensWaitHz`** (drive Hz,
  default 1.0, independent of the rewinder Ø). `TensWaitHz` = 0 → old m/min hold (`TensWaitSpd`).
- `RwRatioD` learning blocked during the hold (`AND NOT TensWait` in the "at target" condition).
- HMI: `TensCheckEnable` (OFF = start as before), `TensWaitHz`.

## 3. START / JOG interlocks (General rungs 7, 9, 10, 11, 12)
| Condition | START | JOG | While running |
|---|---|---|---|
| No paper at web break photocell (monitoring ON) | refused, alarm 6 | allowed (threading) | web break stop (as before) |
| Front gate open (no key bypass) | refused, warning 19 | allowed (guard bypass) | safety relay |
| Side door open (no key bypass) | refused, warning 18 | **refused**, warning 18 | **soft stop** (START cannot cancel); JOG → immediate stop |
| Key bypass 5SA1 (`I_Prot_ByPass`) ON | allowed | allowed | — |

- `StartBlocked := WebBreakNow OR GuardOpen` — NC in the START branch and in `Slow_Inhibit` (JOG works after a refused START).
- `SideDoorOpen` — NC in the JOG branch and `JogRun`, JOG reset in rung 12, soft stop in rung 11.
- No more one-scan start (relay click + lamp flash + 30 s fans) when conditions are not met.

## 4. Alarms (index = HMI event / `AlarmCodeSV[n]`)
A = alarm (buzzer pulses, lamp blinks, RESET silences 1 min) · W = warning (one 1 s beep per NEW warning, lamp steady)

| # | Type | Text | Condition |
|---|---|---|---|
| 1 | A | Motor fan thermal | `I_FanTemp_Ok` off (latched) |
| 2 | A | Drive fault | `I_VFD_Alarm` (latched) |
| 3 | A | Emergency stop | auxiliaries off |
| 4 | A | Motor thermal | `I_Motor_Thermal` (latched) |
| 5 | W | Front guard moving | neither closed nor open |
| 6 | A | Web break / no paper | running, or START pressed, with monitoring ON and photocell clear |
| 7 | A | Extractor fan thermal | `I_Vacuum_OK` off |
| 8 | A | Encoder off | AUTO, InvRef > 200, speed 0 for 3 s |
| 9 | A | Hub not in position | hub in extraction position, stopped, gate open, no bypass |
| 10 | A | Rewinder DT35 fault | latched, RESET when OK |
| 11 | A | Rewinder MAX diameter | latched |
| 12 | A | STOP held 2 s | |
| 13 | W | Web tension too low / slack | `TensLostWarn` |
| 14 | A | Unwinder sonar fault | raw outside `UwRawMin`..`UwRawMax` 1 s, latched |
| 15 | W | Unwinder roll empty | latched |
| 16 | W | GSM / thickness learning fault | latched |
| 17 | W | Paper thickness not learned | running, `RwMat_K` = 0, rewinder Ø > 300 (not with 16) |
| 18 | W | Side door open | START / JOG pressed or running with door open; latched until door closed + RESET |
| 19 | W | Front gate not closed | START pressed with gate open; latched until RESET |
| 20 | W | AUTO STOP done | 8 s after an auto stop (not after JOG); reason `AutoStopWhy` 1 unw. metres, 2 rew. Ø, 4 rew. MAX, 8 unw. Ø |
| 21 | W | AUTO STOP refused | target already reached when AUTO armed, 5 s; `AutoEnWhy` 1 unwinder, 2 rewinder |

- Rung 0 beeps on each **new** warning bit (`AlarmMem`), no more lost beeps.
- `Msg` = 33 only when no alarm and no warning (no flicker).

## 5. AUTO STOP
- Refusal (AutoStop section 8, before "one AUTO at a time"): rewinder refused if `RwDiam ≥ RwTargetDiam − RwResetHyst`;
  unwinder refused if `Current_Metre ≥ UwStop_at_M_Val`. `RwResetHyst` = 50 mm.
- `AutoStopDone` / `AutoStopWhy` (section 11c); `UwStopLenShow` stays visible during an unwinder refusal.
- Horn: no slow-down / stop beeps during JOG (`HornRun … AND NOT JogRun`).

## 6. HMI (EasyBuilder Pro, `Weintek_HMI_Slitter_V12_1105.cmtp`)
- Macro `AutoStop_Refused_Entry` (periodic 0.5 s): `GetData(…, "PLC", "VAR://AutoEnRefused", 1)` etc.
  → `LW-200` = 0/1/2 (Event Log word events ==1 unwinder text, ==2 rewinder text) and `LB-200..202`
  (visibility of STOP LENGTH / STOP AT Ø / SLOW AT Ø). Do **not** use `LW/LB-9000…9999` (system area).
- Alarm bar: Carousel, ≈ 3 s.

## 7. Initial values (as printed 1105/1106)
`RwRatioD` 3366 (live ≈ 2800 → update), `RwAxisDist` 727, `RwDist10V` 782, `EncoderWheel_Circumf` 402,
`RwResetHyst` 50, `RwMaxDiam` 1315, `SoftStopDecel` 500, `RwMinLearnSpd` 15, `RwTreact` 0.03, `TensWaitHz` 1.0,
`PaperGSM` / `WebWidth_mm` Retain.
