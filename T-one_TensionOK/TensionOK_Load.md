> **Superseded by `V12_1106/V12_1106_Changes.md`** (program V12_1106_6 on the PLC; alarm numbers differ: 14 sonar, 17 thickness, 18-21).

# T-one "Tension OK" add-on (11/03) — on top of V12 (not V13)

After START in AUTO, the slitter holds `TensWaitSpd` (15 m/min) until the T-one reports
that the tension is established, then ramps to the set speed as usual. If the tension is lost later
while running, it gives a warning only (no slow-down). With `TensCheckEnable` OFF, the start works as before.

## 1. T-one (manual T-ONE.pdf p. 9, 20, 23, 28)
Password needed for F.4 and up: F.3 → ENTER → password → ENTER. "PASS" blinking = wrong password.
**First photograph / write down every F value (backup).**

| Function | Set | Meaning |
|---|---|---|
| F.11 Second alarm threshold | **full scale** (set FIRST: F.10 range is 0 → F.11) | Alarm 1 not used |
| F.10 First alarm threshold | ≈ **50 % of the tension set point** (kg) | "tension established" |
| F.9 Type of alarm | **0** | both alarms = tension ABOVE threshold |
| F.72 Alarm display | 0 | no "ALL.0" blinking on the display |

The relays are **not latched**: they follow the tension. No hysteresis given → the PLC debounces.

## 2. Wiring
- T-one **pin 15** ← +24 V (same 24 V supply as the Inline DI 8 module)
- T-one **pin 16** → Inline **IB IL 24 DI 8/HD-ECO, IN05, pin 1.3** (was the "slow-down photocell", Alarms rung 18)
- Dry relay contact (Alarm 0 = 15-16, Alarm 1 = 17-18 spare).
- Check first that nothing else is wired to pin 1.3.

## 3. Variables
- **I/O Map:** rename `I_SlowSens_PH` → **`I_T_one_TensionOK`** (same `_IN05 (Pin 1.3)` mapping),
  comment "T-one Alarm 0 (15-16): tension established". It was used in Alarms rung 18 (`Alarm_Array[13]`), see 4c.
- **Global Variables:** paste `TensionOK_Globals_paste.txt` lines 2–6 (line 1 = the renamed input, for reference).
  Set Network Publish = **Publish Only**. `TensCheckEnable`, `TensWaitSpd` are **Retain**.
- **TaglMonoTRM Externals:** add `I_T_one_TensionOK`, `TensCheckEnable`, `TensWaitSpd`, `TensionOK`, `TensWait`, `TensLostWarn`.
- **TaglMonoTRM Internals:** paste `TensionOK_Internals_paste.txt` (`T_TensOn`, `T_TensOff` = **TON**).

## 4. Program
| Step | Section / rung | Action | File |
|---|---|---|---|
| 4a | General, **new ST rung (no contact) directly below rung 7** (JogRun / GuardStopOK) | paste | `General_TensionOK.st` |
| 4b | Motor_Manager rung B "V7: feed-forward speed loop", after the `FFTarget` clamp, before `IF SpdHold THEN` | insert 3 lines | `MotorManager_rungB_TensWait_insert.st` |
| 4c | Alarms rung 18 "Web Tension Monitor" (was slow-down photocell) | contact `I_T_one_TensionOK` (NO) → **`TensLostWarn` (NO)**, coil `Alarm_Array[13]` stays (13 = already a warning: 1 s beep, no stop) | — |

Build → 0 errors.

## 5. HMI
| Page | Object | Address | Format |
|---|---|---|---|
| Settings | Toggle "TENSION CHECK" | `TensCheckEnable` | |
| Settings | Numeric "WAIT TENSION SPEED (m/min)" | `TensWaitSpd` | ###, 5–50 |
| Main | Lamp "WAITING FOR TENSION" | `TensWait` | |
| Main / I/O | Lamp "T-ONE TENSION OK" | `I_T_one_TensionOK` | |
| Alarm list | Text of alarm 13 | "Web tension lost (T-one)" | |

## 6. Tests
1. `TensCheckEnable` OFF: start as before.
2. Watch the IN05 LED (pin 1.3): OFF at standstill, ON once the tension > F.10, OFF again at stop.
   If it stays ON after the tension falls → the relay latches, tell me.
3. `TensCheckEnable` ON, AUTO START at 300 m/min: holds 15 m/min (`TensWait` ON) until the tension is
   there, then ramps up to 300 m/min (`TensWait` OFF).
4. Running: drop the tension below F.10 for > 2 s → `TensLostWarn` ON, speed unchanged.
5. JOG: not affected.

Only in AUTO with the feed-forward active (`FFActive`): with `FFEnable` OFF or ManMode, no hold.

## Encoder note (MNI40N, same date)
`EncoderWheel_Diam` is used as the measuring-roll **circumference** (mm per turn = value / (Encoder_Pulse × 4)).
Tape measure: 402.0 mm. If measured with a tape around the roll → keep 402.0 (tape ≈ paper thickness).
If measured as diameter × π → 402.4 (adds π × paper thickness, 80–120 GSM, ±0.02 %).
Encoder D1 wheel (100 poles, Ø63.7, bore 35): label pulse count must match `Encoder_Pulse` (1000).
After a change: Initial Values + NEW PAPER (RwMat_K re-learns).
