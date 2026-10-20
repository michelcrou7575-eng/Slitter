# HMI review: screenshots of 10/19/2026, checked against PLC print 1019_10

All tags shown exist in 1019_10 and are Publish Only, so no "Device No Response" is expected from these pages.
The problems are **wrong tags behind correct labels**.

## 🔴 Must fix

### Encoder / diameter page (password page with ACQUIRE), *Screenshot 214421*
| Row label | Tag now | Should be |
|---|---|---|
| ENCODER PULSES / REVOLUTION | Encoder_Pulse | ✓ |
| ENCODER WHEEL DIAMETER | EncoderWheel_Diam | ✓ |
| **CORE OUTSIDE DIAMETER** | **EncoderWheel_Diam** | **UwCoreDiameter** |
| **ENCODER WHEEL DIAMETER** (2nd time) | UwCoreDiameter | Delete the row, or relabel it (it becomes a duplicate once the row above is fixed) |
| UNWINDER MEASURE AT MINIMUM DIAMETER, ACQUIRE | Core_Measure | ✓ |
| **…its value field** | **UwCoreDiameter** | **UwCoreDistance** (the sonar distance that ACQUIRE stores) |

Risk: today, typing the core OD (about 101) into "CORE OUTSIDE DIAMETER" overwrites the **encoder wheel** value (400). The metre counter, the speed and every auto-stop length become 4× wrong.

### Main page, *Screenshot 214211*
| Field | Tag now | Should be |
|---|---|---|
| UNWINDER ACT. DIAMETER [mm] | **AI_Diam_Unwinder** (raw counts 0–4000) | **UwDiam_Act** (REAL, mm) |
| REWINDER ACT. DIAMETER [mm] | **AI_Diam_Rewinder** (raw counts) | **RwDiam** (REAL, mm) |

### IN/OUT page, *Screenshot 214250*
| Row label | Tag now | Should be |
|---|---|---|
| **AUTO SLOW DOWN AT ROLL END** | **I_LowSpd_OS** (same as "MOTOR START SLOW") | **I_RollEnd_SlowDown** |
| **OVER RIDER PHOTOCELL ON** (outputs column) | **I_OR_Auto_OS** (an input) | **O_OR_Auto_Lamp** |
| **SAFETY BYPASS** (outputs column) | **O_Prot_ByPass_Lamp** (has no I/O address, so it is never ON) | **O_FrontGuard_ByPass** (relay 23KA4) |
| EMERGENCY ALARM (outputs column) | AlarmOn (internal flag) | Better: **O_Alarm_Array** (the real lamp output) |
| 4th column, rows 3–13 | Lamps with no label that repeat the 3rd column's tags (O_Brake … O_Prot_ByPass_Lamp) | Delete them (leftover copies) |

## 🟠 Missing (handover §8 to-do)
1. **Diameter setup page** (*214310*): add a **display** of `RwMaxSlowAtDiam`. Rename "REWINDER SLOWDOWN MAX MACHINE DIAMETER" to "…(until learned)", because `RwMaxSlowFallback` is used only while `RwMat_K` = 0.
2. **`UwSlowMargin_m`** (metres at slow speed before the meter stop, now 10) is on **no page**. Add it, for example to the timing page.
3. **New "REWINDER DT35 / LEARNING" page** behind the password. It does not exist yet:
   - Calibration: `RwDist0V`, `RwDist10V`, `RwAxisDist`, `RwRawMin`, `RwRawMax`, `RwFilter_K`
   - Stop: `RwTargetDiam`, `RwSlowMargin_m`, `RwSlowDecel`, `RwTrim`, `RwTreact`, `RwTstopDef`, `RwResetHyst`, `RwUseSlow`, `RwStopOnFault`, `RwMaxDiam`, `UwEmptyHyst`
   - Learning (display): `RwThick_mm`, `RwMat_K`, `RwStopDecel`, `RwSpeed`, `RwDist`, `RwDiam`, `RwRemain_m`, `RwStopLen_m`, `RwSlowLen_m`, `RwSlowAtDiam`, `RwStopAtDiam`
   - Reset-learning buttons: set `RwMat_K` := 0 and `RwStopDecel` := 0 (Set Word / Set Value object)
   - Input limits, for example `RwTrim` 0.8–1.5, `RwAxisDist` 600–750, `RwMaxDiam` ≤ 1360
4. **Main page, centre "AUTO STOP" box:** show `SlowAtDisp` with visibility on `SlowAtShow`, and the unit from `SlowAtMode` (1 = m, 2 = mm).
5. **Alarm texts** (Event Log, label library): [10] REWIND DIAMETER SENSOR FAULT, [11] REWINDER MAX DIAMETER, [15] UNWINDER EMPTY, [16] REWINDER LEARNING FAULT. Delete the duplicate "UNWINDER" on [10].

## ✓ OK
- Timing page (*214332*): Fan_Timeout, OverRider_TimeON/OFF, VelMax.
- Ramp page (*214355*): JogSpd_SP, SpdDelta_Percent, AccelTrim / DecelTrim (inside the band), AccelCoarse / DecelCoarse (outside the band). The labels match the logic: `DecelCoarse` is the one used for deceleration in Motor_Manager rungs 14/15.
- Diameter page: UwSlowDown_Diam, UwDiamStop, RwMaxDiam.
- Main page: UwStop_At_Meter, RwTargetDiam, UwStopEnable / RwStopEnable buttons, speeds, Current_Metre, Counter_Reset / CountReset_Req, I_AutoStop_OS, ManMode, Measure_ON, FrontGuard_Closed.
- PLC configuration drawing (*083154*, sheet 28): NX1P2-9024DT1 + NX1W-MAB221, NX-PF0730, NX-AD2603, NX-EC0122, IL EC BK-PAC, IB IL 24 DI 8 / DO 8. Matches the handover.
