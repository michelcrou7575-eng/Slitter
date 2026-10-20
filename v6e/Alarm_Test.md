# Alarm test: PLC → HMI

Two levels:
- **A. Display test:** an HMI field forces any alarm number. It checks the alarm text (Event Log / AlarmCodeSV), the alarm bar, the lamp, the buzzer and the reset. Use it once after the HMI alarm texts are edited.
- **B. Functional test:** triggers each alarm through its real condition. Use it at commissioning.

Alarms only drive the buzzer, the lamp and the HMI. **No alarm stops the motor by itself** (stops come from `Stop` in Motor_Manager rung 4). The tests below are still done **with the machine stopped** unless noted.

---

## A. Display test from the HMI (new, optional)

### A1. Global variable (paste in Global Variables)
`v6e/AlarmTest_Global_paste.txt`:

| Name | Type | Initial | AT | Retain | Constant | Network Publish | Comment |
|---|---|---|---|---|---|---|---|
| AlarmTest_No | INT | 0 | | False | False | Publish Only | HMI alarm test: 1..32 = force this alarm (motor stopped only), 0 = off |

### A2. New rung at the **end** of section **Alarms** (after rung 27), inline ST
```
// Alarm test from HMI: forces Alarm_Array[AlarmTest_No]. Motor stopped only.
IF StartMotor_Cmd OR (AlarmTest_No < 0) OR (AlarmTest_No > 32) THEN
    AlarmTest_No := 0;
END_IF;
IF AlarmTest_No > 0 THEN
    Alarm_Array[AlarmTest_No] := TRUE;
END_IF;
```
Why at the end: the alarm rungs above rewrite `Alarm_Array` on every scan. The test rung runs last, so the forced bit survives into the next scan's Console rung 6 (copy to `AlarmCodeSV`), Alarms rung 0 (buzzer) and Output_Manager rung 7 (lamp).
The test cancels itself as soon as the motor starts.

### A3. HMI
On the password page (Psw 44): a numeric input **ALARM TEST No.** → `AlarmTest_No` (INT, limits 0–32).

### A4. Procedure
1. Machine stopped. Enter 1 → check the text, lamp and buzzer. Enter 0.
2. Repeat for **1–8, 10, 11, 12, 13, 14, 15, 16, 30**.
3. **Latched alarms** (1, 2, 4, 6, 10, 11, 15, 16) stay ON after 0. Press **ALARM RESET** (panel `Alarm_Reset` and the push button `I_RsetAlarm`). The alarm must clear. This also tests the reset.
4. **OUT-coil alarms** (3, 5, 7, 8, 9, 12, 13, 14, 30) clear by themselves on 0.

| No. | Text expected on the HMI | Type |
|---|---|---|
| 1 | Motor fan thermal | latched |
| 2 | Inverter fault | latched |
| 3 | Emergency stop | direct |
| 4 | Motor thermal switch | latched |
| 5 | Front guard moving | direct |
| 6 | Paper break | latched |
| 7 | Extractor fan thermal | direct |
| 8 | Encoder stopped | direct |
| 10 | REWIND DIAMETER SENSOR FAULT | latched (S/R) |
| 11 | REWINDER MAX DIAMETER | latched (S/R) |
| 12 | Stop button / rope switch held 2 s | direct |
| 13 | Slow-down photocell active | direct |
| 14 | End-of-roll photocell | direct |
| 15 | UNWINDER EMPTY | latched (S/R) |
| 16 | REWINDER LEARNING FAULT | latched (S/R) |
| 30 | Hub not in position | direct |

The lamp (Output_Manager rung 7) reacts to 10/11/15/16 only after the v6d C4 lamp edit is done (still missing in 1019_10).

---

## B. Functional test (real conditions)

**Write down every setpoint before you change it, and restore it right after** (they are Retain).
"Watch" = Sysmac Studio Watch tab, online. "Force" = right-click → *Forced Refreshing → TRUE/FALSE* on an I/O (AT) variable, then *Cancel All Forced Refreshing* at the end.

| No. | How to trigger | Expected | Restore / clear |
|---|---|---|---|
| 1 | Force `I_FanTemp_Ok` = FALSE | Alarm 1, latched | Cancel force → RESET |
| 2 | Force `I_VFD_Alarm` = FALSE, or a real inverter fault | Alarm 2, latched | Cancel → RESET |
| 3 | Press the E-stop | Alarm 3, lamp steady | Release, re-arm the auxiliaries |
| 4 | Force `I_Motor_Thermal` = FALSE | Alarm 4, latched | Cancel → RESET |
| 5 | Stop the front guard halfway (neither closed nor open) | Alarm 5 | Close the guard |
| 6 | Run at **work speed** with paper-break monitoring ON, then force `I_WebBreak_PH` = TRUE (or break the web for real) | Alarm 6 **and** machine stops | Cancel → RESET |
| 7 | Force `I_Vacuum_OK` = FALSE | Alarm 7 | Cancel |
| 8 | Auto mode (not ManMode), run at slow speed, disconnect the encoder (or force `Encoder_On` = FALSE) | Alarm 8 after 3 s | Reconnect / cancel |
| 10 | Rewinder AUTO ON (`RwStopEnable`), Watch: `RwRawMax` 3900 → **0** | Alarm 10 (`RwSensFault`) | `RwRawMax` = 3900 → RESET |
| 11 | Watch: `RwMaxDiam` 1330 → a value **below** the current `RwDiam` (for example 100) | Alarm 11 (`RwMaxStop`), start blocked | `RwMaxDiam` = 1330 **first**, then RESET |
| 12 | Hold STOP (or pull the rope switch) for > 2 s | Alarm 12 | Release |
| 13 | Block the slow-down photocell | Alarm 13 | Clear |
| 14 | — | `I_RollEnd_PH` has no I/O address: **can't happen**. Test with A only | — |
| 15 | Sonar ON (`Measure_ON`), Watch: `UwDiamStop` 110 → a value **above** `UwDiam_Act` (for example 2000) | Alarm 15, start blocked | `UwDiamStop` = 110 → RESET |
| 16 | Watch: `RwLearnFailMax` 12 → **0** | Alarm 16 (`LearnFault`), `RwLearned_OK` = FALSE | `RwLearnFailMax` = 12 → RESET |
| 30 | Hub/chuck in extraction position, motor stopped | Alarm 30 | Hub back |

Check for every alarm: the HMI text, the alarm bar, the buzzer (1–8, 10, 11, 15, 16), the lamp, and the reset.

### At the end
- *Cancel All Forced Refreshing* (Sysmac shows **"Forced"** in the status bar while any force is active).
- Check that the setpoints are back: `RwRawMax` 3900, `RwMaxDiam` 1330, `UwDiamStop` 110, `RwLearnFailMax` 12.
- `AlarmTest_No` = 0.
