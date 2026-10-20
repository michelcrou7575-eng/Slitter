# v6d corrections (review of print `Slitter_Program_1019_1.pdf`)

Apply these **on top of v6c**, in this order, in the same session as the other v6/v6b/v6c steps.
At the end, **F7 = 0 errors**, then run an Offline Comparison against "from PLC".

---

## A. Variables

### A1. New Internals (program `TaglMonoTRM`)
Paste `v6d_Locals_paste.txt` (6 rows) into the program's Internals table.
- `T_Sample` is no longer used. Delete it, or leave it (you will get an "unused" warning only).

### A2. Initial values to enter (Global Variables table)
These are retained variables whose **Initial Value is blank or wrong in the print**. After a full transfer with cleared retain memory, a blank value comes up as 0.

| Variable | Print | Enter | Why |
|---|---|---|---|
| `Encoder_Pulse` | (blank) | **1000** | Blank → Motor_Manager rung 1 forces 1 → mm/pulse 1000× too big |
| `UwCoreDiameter` | 100 | **101** | Measured core OD |
| `VelMax` | (blank) | **800** | Blank → clamped to 600 |
| `UwStop_At_Meter` | (blank) | **5020** | |
| `UwDiamStop` | (blank) | **110** | |
| `UwSlowMargin_m` | (blank) | **10** | Was 2; handover suggests 10 |
| `OverRider_TimeON` | (blank) | **0.05** | |
| `OverRider_TimeOFF` | (blank) | **0** | |

Already correct in the print: `EncoderWheel_Diam` 400, `UwCoreDistance` 785.56, `UwSlowDown_Diam` 200, `DeadZone` 60, `Reading_Max` 2000, `Fan_Timeout` 0.5, `JogSpd_SP` 10, `Measure_ON` True, `Core_Measure` False.

### A3. `UwEmptyHyst`
Change **Network Publish** from "Do not publish" to **Publish Only** so the HMI can show and edit it. Its value (5) is still an open decision; see the handover's §7.

---

## B. Section `AutoStop_Control`
Replace the whole ST box with `AutoStop_Control_v6d.st`.

| # | Change | Reason |
|---|---|---|
| 1 | 100 ms tick = 25-scan counter | The self-resetting TON ran about 104–108 ms, so the speed read 4–8 % high |
| 3/5 | Standstill = ≤ 20 pulses/s (≤ 2 counts per 100 ms) | Encoder jitter at standstill could block the stop measurement forever |
| 5 | `RunWasJog` / `StopLearnValid` | Do not learn stop decel after jog, ManMode or slow-button runs (2nd ramp `O_AccDec2`), or when the auxiliaries drop (E-stop) |
| 6 | Work and final speed from `Pot1_Mem` / `Pot2_Mem` ÷ `Input_Ratio` | `Speed_Display` / `LowSpd_Display` are not m/min in ManMode |
| 6 | Slow-down length adds the **DecelTrim tail** | Within ±`SpdDelta_Percent` (8 m/min) of the target, Motor_Manager rungs 14/15 switch from DecelCoarse (125 mm/s²) to DecelTrim (20 mm/s²). At 100 m/min final speed, that tail alone is about 11 m, more than the 10 m margin. With `RwSlowDecel` > 0, the single manual ramp is still used. |

Nothing else changed. Sections 2, 4 and 6b–12 are identical to v6c.

---

## C. Ladder edits

### C1. Alarms rung 12: DT35 fault (alarm 10) in every mode while running
The DT35 fault disables the always-active max-diameter protection, so it must not stay silent outside Rewinder AUTO.
```
ControlVoltage ──┤ ├── RwSensFault ──┤ ├──┬── RwStopEnable ───┤ ├──┬──(S) Alarm_Array[10]
                                          └── StartMotor_Cmd ──┤ ├──┘
```
(Add `StartMotor_Cmd` in **parallel** with the existing `RwStopEnable` contact. While the machine is stopped in another mode, for example with the shaft out for unloading, it does not alarm.)
Rung 13 (reset) is unchanged.

### C2. New rungs after rung 15: Rewinder learning fault (alarm 16)
Rung 16 (new), "Rewinder learning fault":
```
ControlVoltage ──┤ ├── RwLearnFault ──┤ ├────────────────────────(S) Alarm_Array[16]
```
Rung 17 (new), "Rewinder learning fault - Reset":
```
──┬── I_RsetAlarm ──┤ ├──┬── RwLearnFault ──┤/├──────────────────(R) Alarm_Array[16]
  └── Alarm_Reset ──┤ ├──┘
```
(Same pattern as alarm 11, rungs 14/15.)

### C3. Alarms rung 20 (unwinder empty, alarm 15): `StartMotor_Cmd` → `Measure_ON`
```
ControlVoltage ──┤ ├── Measure_ON ──┤ ├── UnWinder_Empty ──┤ ├───(S) Alarm_Array[15]
```
With `StartMotor_Cmd` the alarm could never appear: an empty roll gives `UwStopByDiam`, so `Stop` blocks the start.

### C4. Lamp and buzzer for the new alarms
Add `Alarm_Array[10]`, `Alarm_Array[11]`, `Alarm_Array[15]` and `Alarm_Array[16]` as **parallel** NO contacts to the existing `Alarm_Array[1]…[8]` branch in:
- **Alarms rung 0** (`BuzzerOn`)
- **Output_Manager rung 7** (`O_Alarm_Array`, alarm lamp)

### C5. Alarms rung 10: encoder stopped (alarm 8). Turn it back on.
The machine builder disabled it with a `P_Off` (Always FALSE) contact. Every metre and diameter calculation depends on the encoder.
- Replace the `P_Off` contact with **`ManMode` NC** (`┤/├`). In manual mode, InvRef is the raw potentiometer.
- Change the compare `InvRef > INT#0` to **`InvRef > INT#200`** (5 % of 4000).
- Change the `T_EncoderStill` PT from `T#1000ms` to **`T#3000ms`**.

Result: the alarm comes on when the motor is commanded in auto, the reference is above 5 %, and the encoder shows 0 speed for 3 s.
**Test on the machine:** start normally and check that alarm 8 does not come on during acceleration. Then unplug the encoder at slow speed and check that it does come on.

---

## D. HMI
- No new published globals in v6d, so no new tags.
- `UwEmptyHyst` is now published, so it can go on the page 3 / DT35 page.
- Alarm 16 text: **REWINDER LEARNING FAULT**. It was already planned in the handover's §8.

## E. Checks at commissioning
1. **AI Ch2 scaling:** hold a target at the DT35's far end (or at 10 V). `AI_Diam_Rewinder` must read about **4000** counts. `RwRawMax` 3900 and the `/4000.0` scaling depend on it.
2. **Slow-down length:** on the first rolls in each AUTO mode, compare `RwSlowLen_m` (or `UwStop_At_Meter − UwSlow_at_Metre`) with the metres actually run at final speed before the stop. Adjust `RwSlowMargin_m` / `UwSlowMargin_m`, or set `RwSlowDecel`.
3. **Stop learning:** after a few normal stops, `RwStopDecel` should be > 0 and `StopFailCnt` 0. After a jog, `RwStopDecel` must **not** change.
4. **Speed:** `RwSpeed` should now match `Velocity_M_min` (Motor_Manager) within about 1 %.

## Not changed (needs site information)
- `O_Prot_ByPass_Lamp` and `I_SafeGuard_Closed` have **no AT address**. The guards-bypassed lamp never lights. Check the electrical drawings for a free output.
- `EncoderWheel_Diam` (400) behaves as the wheel **circumference** (`400 / (1000 × 4)` = 0.1 mm/count). The metre counter is correct; only the name is misleading.

---

## Status in `Slitter_Program_1019_10.pdf` (10/19/2026 8:47 PM)
| Item | Status |
|---|---|
| A1 new Internals (6) | ✓ |
| A2 `Encoder_Pulse` 1000, `VelMax` 800, `UwDiamStop` 110, `UwSlowMargin_m` 10, `OverRider_TimeON` 0.05 | ✓ |
| A2 `UwStop_At_Meter` | 5100 (not 5020). OK if intended |
| A2 `OverRider_TimeOFF` | 0.01 (not 0). OK if intended |
| A2 `UwCoreDiameter` | ✗ **still 100. Enter 101** |
| A3 `UwEmptyHyst` Publish Only | ✓ (value still 5, open decision) |
| B AutoStop_Control v6d | ✓ identical. Cosmetic: header lines 1 and 2 both open a comment with `(*`. Delete line 2 |
| C1 alarm 10 while running | ✓ Alarms rung 12 |
| C2 alarm 16 rungs | ✓ Alarms rungs 16/17 |
| C3 alarm 15 on `Measure_ON` | ✓ Alarms rung 22 |
| C4 buzzer (Alarms rung 0) | ✓ 10, 11, 15, 16 added |
| C4 **alarm lamp (Output_Manager rung 7)** | ✗ **still alarms 1–8 only. Add `Alarm_Array[10]`, `[11]`, `[15]`, `[16]` in parallel** |
| C5 encoder alarm | ✓ ManMode NC, InvRef > 200, 3 s |
