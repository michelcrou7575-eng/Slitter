# HMI window 12 "IN / OUT": proposed tag for every lamp

Only **Global (Publish Only)** variables can be shown. Program locals (`SlowDown`, `Stop`, `BrakeHold`, `StopNow`, `RangeOK`, `AutoSlowCmd`, `AutoStopCmd`) are not visible to the HMI.

## Inputs (green), left column: check the existing lamps
| Label | Tag | I/O |
|---|---|---|
| CONTROL VOLTAGE ON | `I_ControlVoltage` | CPU IN 00 |
| MOTOR START | `I_Start_PB` | IN 01 |
| STOP MOTOR | `I_Stop_PB` | IN 02 |
| MOTOR THERMAL PAD | `I_Motor_Thermal` | IN 03 |
| SAFETY DEVICE OFF | `I_Prot_ByPass` | IN 04 |
| REWIND SHAFT IN EXTRACTION | `I_Hub_Position` | IN 05 |
| FRONTAL GATE CLOSED | `I_FrontGuard_Closed` | IN 06 |
| MOTOR START SLOW | `I_LowSpd_OS` | IN 07 |
| MAIN MOTOR ALARM | `I_VFD_Alarm` | IN 08 |
| FRONTAL GATE OPEN | `I_FrontGuard_Open` | IN 09 |
| AUTOMATIC STOP BY METERS / DIAMETERS | `I_AutoStop_OS` | IN 10 |
| AUTO SLOW DOWN AT ROLL END | `I_RollEnd_SlowDown` | IN 11 |
| WEB BREAK CONTROL ON | `I_WebBreak_Monitor` | IN 12 |
| OVER RIDER SENSOR LIFTING CUTTING GROUP | `I_OverRider_PH` | IN 13 |
| BLOWER ALARM | `I_Vacuum_OK` | encoder unit ext. input 0 |

## Inputs, right column
| Label | Tag | I/O |
|---|---|---|
| PHOTOCELL LIFTING CUTTING GROUP | `I_OR_Position_Sens` | EtherCAT DI IN01 |
| OVER RIDER SWITCH | `I_OR_Pressure_Sens` | DI IN02 |
| OVER RIDER IN AUTO MODE | `I_OR_Auto_OS` | DI IN03 |
| OVER RIDER IN CONTINUOUS MODE | `I_OR_Cont_OS` | DI IN04 |
| SLOW DOWN PHOTOCELL | `I_SlowSens_PH` | DI IN05 |
| FAN MOTOR PROTECTION OFF | `I_FanTemp_Ok` | DI IN06 |
| WEB BREAK PHOTOCELL | `I_WebBreak_PH` | DI IN07 |
| ALARM RESET | `I_RsetAlarm` | DI IN08 |
| **new rows: analog inputs, Numeric display instead of a lamp** | | |
| WORK SPEED POT [0–4000] | `Pot1_Work_Velocity` | CPU AI Ch1 |
| FINAL SPEED POT [0–4000] | `Pot2_Slow_Velocity` | CPU AI Ch2 |
| UNWINDER SONAR [0–4000] | `AI_Diam_Unwinder` | AD unit Ch1 |
| REWINDER DT35 [0–4000] | `AI_Diam_Rewinder` | AD unit Ch2 |
| ENCODER COUNT | `Encoder_Pos` | encoder unit |
| ENCODER PULSES / 100 ms | `PulseRate` | encoder unit |
| REWINDER DT35 FAULT (lamp, red) | `RwSensFault` | (raw < 10 or > 3900) |

## Outputs (brown), left column
| Label | Tag | I/O |
|---|---|---|
| MOTOR START | `O_MotorStart` | CPU OUT 00 |
| MOTOR ON POWER | `O_Motor_Lamp` | OUT 01 |
| REEL BRAKE IN AUTOMATIC | `O_Brake` | OUT 02 |
| MOTOR AND BRAKE FAN | `O_CoolingFan` | OUT 03 |
| ELECTROVALVE LOCKING CUTTING GROUP | `O_OverRider_Hold` | OUT 04 |
| MAIN MOTOR SLOW ACC/DEC | `O_AccDec2` | OUT 05 |
| OVER RIDER PHOTOCELL ON | `O_OR_Auto_Lamp` | OUT 06 |
| UNLOADER UP ENABLED | `O_RwUnload` | DO OUT03 |
| ACOUSTIC INDICATOR | `O_AcousticSignal` | OUT 08 |
| OVER RIDER RAISE | `O_OverRider_Up` | OUT 09 |
| EMERGENCY ALARM | `O_Alarm_Array` | DO OUT01 |
| UNLOADER DOWN ENABLED | `RwUnload_Enable` | OUT 07 |
| SAFETY BYPASS | `O_FrontGuard_ByPass` | DO OUT04 (23KA4) |

## Outputs, right column: analog out + machine status (lamps, ON = active)
| Label | Tag |
|---|---|
| INVERTER SPEED REF [0–4000] (Numeric) | `InvRef` (CPU AO Ch2) |
| SPEED SET POINT [m/min] (Numeric) | `VelSet` |
| SOFT STOP | `SoftStop` |
| SPEED TOO HIGH | `OverSpeed` |
| SPEED TOO LOW | `UnderSpeed` |
| REWINDER SLOW REQUEST | `RwSlowReq` |
| REWINDER STOP REQUEST | `RwStopReq` |
| UNWINDER SLOW REQUEST (meters) | `UwSlowReq` |
| REWINDER MAX DIAM SLOW | `RwMaxSlow` |
| REWINDER MAX DIAM STOP | `RwMaxStop` |
| GSM / DECEL LEARNED | `GSM_Learned_OK` |
| NEW POT RANGE PENDING | `SpdMax_Pending` |

"REWINDER STOP ON FAULT" (`RwStopOnFault`) and "REWINDER USE SLOW" (`RwUseSlow`) are **settings**, not outputs → better on the rewinder settings page (Toggle switch), not on IN/OUT.

Optional (needs a PLC change): to see `SlowDown`, `Stop`, `BrakeHold`, `StopNow`, move them from the program Internals to Global Variables (Publish Only) and add them to the Externals. No code change.
