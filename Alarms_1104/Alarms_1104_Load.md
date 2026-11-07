> **Superseded by `V12_1106/V12_1106_Changes.md`** (program V12_1106_6 on the PLC; alarm numbers differ: 14 sonar, 17 thickness, 18-21).

# Alarms add-on (11/04) — on top of V12_1103_2 (not V13)

| Index | Type | Text (HMI alarm list) | Condition |
|---|---|---|---|
| **17** | ALARM (buzzer, latched) | "Unwinder diameter sensor fault" | `AI_Diam_Unwinder` < `UwRawMin` (10) or > `UwRawMax` (3990) for 1 s, with `Measure_ON` and (unwinder AutoStop ON or motor running). RESET once the sensor is OK. |
| **21** | WARNING (1 s beep) | "Paper thickness not learned" | `Thickness_Fault`: running, `RwMat_K` = 0, rewinder Ø > 300 mm (any mode: learning always runs, UNWINDER AUTO-SLOW uses it). Not latched. |

## Load
1. **Global Variables:** paste `Alarms_1104_Globals_paste.txt` (Publish Only; `UwRawMin` / `UwRawMax` Retain).
2. **TaglMonoTRM Externals:** add `UwRawMin`, `UwRawMax`, `UwSensFault` (and `AI_Diam_Unwinder`, `Measure_ON`,
   `UwAutoStopEnable`, `RwStopEnable`, `RwMat_K`, `RwDiam` if not there yet).
3. **TaglMonoTRM Internals:** paste `Alarms_1104_Internals_paste.txt` (`T_UwSensFlt` = **TON**).
4. **Alarms rung 0:** warning CASE → `5, 13, 14, 15, 16, 21:` (`Alarms_rung0_CASE_line.st`).
5. **Alarms:** insert a new ST rung (no contact) **after rung 20** = `Alarms_rung_17_21.st`.
6. Build → 0 errors (Cross Reference first: nothing else writes `Alarm_Array[17]` / `[21]`).
7. **HMI:** alarm texts 17 and 21 (Event Log / message list by index). Optional on the I/O page:
   numeric `UwRawMin`, `UwRawMax` (0–4000) next to `AI_Diam_Unwinder`.

## Tests
- Sonar unplugged / covered (or set `UwRawMax` below the live raw value): motor running → after 1 s alarm 17,
  buzzer. Fix (restore `UwRawMax` 3990) → RESET clears it.
- Watch the live `AI_Diam_Unwinder` at the empty core and the full roll first: both must stay inside 10..3990.
  If the UC2000 holds its last value on lost echo (instead of going to 0 / 10 V), alarm 17 will not see it.
- NEW PAPER, run past 300 mm before `RwMat_K` is learned → warning 21 (1 s beep, yellow bar).

## Still open (from the 11/04 alarm review)
- Rungs 16 and 21 both write `Alarm_Array[14]` and are always FALSE → can be deleted (frees index 14).
- Rung 15 coil comment / HMI text 13 → "Web tension lost (T-one)".
- Rung 9: `I_SafeGuard_Closed` not mapped (always FALSE).
- Rung 22: MOVE 33 between messages → bar flicker; only when `NOT AlarmOn AND NOT WarningOn`.
