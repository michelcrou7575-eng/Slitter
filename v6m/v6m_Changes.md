# v6m: soft stop on the STOP button

## Field request (10/21/2026)
Operators turn P1 (work speed) down to 0, wait until the machine has almost stopped, then press STOP, to avoid the abrupt stop (web on the floor).
→ The program does this automatically.

## Behaviour
| Operator action | Result |
|---|---|
| **STOP** pressed once, machine running above `SoftStopEndSpd` | **Soft stop:** set point → 0, the speed loop brings the web down (T-one stays in tension control), then the run command drops at ≤ `SoftStopEndSpd` (5 m/min) |
| STOP pressed **again** during the soft stop, or **held ≥ 1 s** | **Immediate stop** (as before) |
| **START** during the soft stop | Soft stop cancelled, back to the work speed |
| Machine already ≤ 5 m/min, jog (slow button), or `SoftStopEnable` = False | Immediate stop (as before) |
| Soft stop longer than 120 s | Immediate stop (safety timeout) |
| **E-stop, paper break, auto stop (meters / diameter / max diameter)** | **Unchanged**, immediate (Motor_Manager rung 4 `Stop` → General rung 9) |

Auto mode: the speed loop decelerates with `DecelCoarse` (or `SoftStopDecel` if > 0), then `DecelTrim` inside the band.
Manual mode (`ManMode`): the drive reference goes to 0 and the drive decelerates on its own ramp (2nd ramp, DI5).

## 1. Variables
- Global Variables: paste `v6m_Globals_paste.txt` (`SoftStop`, `SoftStopEnable` True, `SoftStopEndSpd` 5.0, `SoftStopDecel` 0.0).
- Program **Externals**: paste `v6m_Externals_paste.txt`.
- Program **Internals**: paste `v6m_Locals_paste.txt` (`StopNow`, `StopPB_Mem`, `T_StopLong`, `T_SoftStop`).

## 2. General: new inline-ST rung between rung 8 (start) and rung 9 (stop)
Comment: `v6m: soft stop on STOP button`
```
// v6m: STOP button = soft stop. StopNow replaces I_Stop_PB in rung 9.
StopNow := FALSE;
T_StopLong(In := I_Stop_PB, PT := T#1s);

IF NOT StartMotor_Cmd THEN
    SoftStop := FALSE;
ELSIF I_Stop_PB AND NOT StopPB_Mem THEN            // STOP pressed (edge)
    IF SoftStop OR NOT SoftStopEnable OR I_LowSpd_OS
       OR (Velocity_M_min <= SoftStopEndSpd) THEN
        StopNow := TRUE;                            // 2nd press / jog / slow / disabled
    ELSE
        SoftStop := TRUE;                           // start soft stop
    END_IF;
END_IF;
StopPB_Mem := I_Stop_PB;

IF T_StopLong.Q THEN
    StopNow := TRUE;                                // held 1 s = immediate
END_IF;
IF SoftStop AND I_Start_PB THEN
    SoftStop := FALSE;                              // START cancels the soft stop
END_IF;

T_SoftStop(In := SoftStop, PT := T#120s);
IF SoftStop AND ((Velocity_M_min <= SoftStopEndSpd) OR T_SoftStop.Q) THEN
    StopNow := TRUE;                                // almost stopped (or timeout)
END_IF;
```

## 3. General rung 9 (Main motor stop)
Replace the contact **`I_Stop_PB`** (NO) with **`StopNow`** (NO). The other branches (auxiliaries, slow button released, `Stop`, thermals) are unchanged.
General rung 8 (start) is unchanged: it keeps `I_Stop_PB` NC, so no start while STOP is held.

## 4. Motor_Manager
**Rung 8** (auto set point), ST box:
```
IF SoftStop THEN
    VelSet := 0.0;                                  // v6m: soft stop
ELSIF SlowDown = FALSE THEN
    VelSet := UINT_TO_REAL(Pot1_Mem) / Input_Ratio;
ELSE
    VelSet := UINT_TO_REAL(Pot2_Mem) / Input_Ratio;
END_IF;
VelSet_mms := VelSet * Mt_To_mm;
```
**New inline-ST rung between rung 14 and rung 15** (optional faster decel):
```
// v6m: soft stop decel (0 = keep DecelCoarse / DecelTrim)
IF SoftStop AND (SoftStopDecel > 0.0) THEN
    Decel_Ramp := SoftStopDecel / 250.0;            // 1 = 250 mm/s2 (4 ms task)
END_IF;
```
**Rung 17** (ManMode, open loop), ST box:
```
IF SoftStop THEN
    InvRef := INT#0;                                // v6m: drive ramps down on its own
ELSIF SlowDown = FALSE THEN
    InvRef := Pot1_Work_Velocity;
ELSE
    InvRef := Pot2_Slow_Velocity;
END_IF;
```

## 5. HMI
- Main page: lamp / text **"SOFT STOP…"** on `SoftStop` (blinking).
- Settings page (password): `SoftStopEnable` (ON/OFF), `SoftStopEndSpd` (#.# m/min, 2–20), `SoftStopDecel` (### mm/s², 0–500).

## 6. Test
1. Run at 200 m/min → STOP once → the speed goes down smoothly, "SOFT STOP" shows, the motor stops at about 5 m/min, the web stays tight.
2. During the soft stop: START → back to the work speed. STOP again → immediate stop.
3. STOP held 1 s at speed → immediate stop (as before).
4. Jog, then release → stops as before.
5. E-stop and paper break at speed → immediate, as before.
6. If the soft stop is too slow: set `SoftStopDecel` (for example 200 mm/s²). The real deceleration stays limited by the drive (dEC, brA, no braking resistor).

## Notes
- With v6h (BrakeHold) the T-one also stays in automatic after the run command drops, until < 5 m/min.
- The stop learning (v6g) ignores these stops (start speed < `RwMinLearnSpd`), as intended.
