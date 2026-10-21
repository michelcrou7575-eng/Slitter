# Record the installed values BEFORE each transfer

A full transfer can reset Retain variables to their **Initial Value** (always for new or renamed variables, and also when "clear retained values" is selected).
→ **Before every transfer**, record the values that are in the PLC now.

## 1. Quickest: Sysmac Studio variable backup
Online with the PLC (old project, the one that matches the PLC):
**Tools → Backup → Variables backup** (save to a file, for example `Vars_2026-10-21.xml`).
After the transfer: **Variables restore** from that file (it restores the variables whose name and type did not change).
*(The menu name can differ slightly with the Sysmac version: look under Tools / Backup.)*

## 2. Safe: write them down (Watch tab), the important ones
Fill in the "Installed" column before the transfer, check after.

| Variable | Initial in project | Installed (PLC now) | After transfer OK? |
|---|---|---|---|
| **Unwinder / encoder** | | | |
| Encoder_Pulse | 1000 | | |
| EncoderWheel_Diam | 400 | | |
| UwCoreDistance | 785.56 | | |
| UwCoreDiameter | 101 | | |
| UwSlowDown_Diam | 200 | | |
| UwDiamStop | 110 | | |
| UwStop_At_Meter | 5100 | | |
| UwSlowMargin_m | 10 | | |
| UwEmptyHyst | 5 | | |
| Measure_ON | True | | |
| **Rewinder DT35** | | | |
| RwAxisDist | 675.3 | | |
| RwDist0V / RwDist10V | 0 / 750 | | |
| RwRawMin / RwRawMax | 10 / 3900 | | |
| RwCoreOD | 100 | | |
| RwTargetDiam | 300 | | |
| RwMaxDiam | 1330 | | |
| RwMaxSlowFallback | 1250 | | |
| RwSlowMargin_m | 10 | | |
| RwTrim | 1.0 | | |
| **Learned (keep them!)** | | | |
| RwMat_K | 0 | | |
| RwStopDecel | 0 | | |
| RwSlowDecelLrn (v6f) | 0 | | |
| RwSlowDecelK / RwStopDecelK (v6g) | 0.15 / 0 | | |
| **Speeds / ramps** | | | |
| VelMax | 800 | | |
| JogSpd_SP | 10 | | |
| SpdDelta_Percent | 8 | | |
| AccelTrim / DecelTrim | 0.08 / 0.08 | | |
| AccelCoarse / DecelCoarse | 1 / 0.5 | | |
| WorkSpd_Max / FinalSpd_Max (v6i) | 400 / 40 | | |
| **Timers** | | | |
| Fan_Timeout | 0.5 | | |
| OverRider_TimeON / OFF | 0.05 / 0.01 | | |
| **Selections** | | | |
| UwStopEnable / RwStopEnable | False / False | | |
| ManMode | — | | |

## 3. After the transfer
1. Watch tab: compare with the "Installed" column.
2. A value that went back to its initial value: **type the installed value back online** (or restore the backup file).
3. **Learned values:** if `RwMat_K` / `RwStopDecel` / the decel K went back to 0, enter them again. Otherwise the machine re-learns over 1–2 rolls (the first stops are less precise).
4. Then the HMI (tags re-imported, same session).
