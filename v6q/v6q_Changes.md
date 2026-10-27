# v6q: S-curve start in AUTO + password 66 fix (print 1027 check)

## Print 1027: status
| Item | Status |
|---|---|
| Fix 5 rung deleted (Motor_Manager 15 → 16 "Speed correction") | ✅ |
| AutoStop_Control **v6p** (RwLearnReset, seed removed) | ✅ |
| **Console rung 4: password 66** | ❌ see fix A |
| Initial values still the old ones (only used after a Retain loss) | ⚠ see B |

## A. Console rung 4: 66 is treated as a WRONG code
The "wrong code" chain is `Psw <> 22` AND `Psw <> 44` AND `Psw <> 0`. **66 is not in it** → typing 66 → in the same scan `Psw := 0` and `HMI_Screen[0] := 10`. `Psw66` is ON for one scan only, so popup 66 never opens.
**Fix:** add a 4th compare block **`<>` Psw, INT#66** in series in the top chain (after `<> INT#0`, before `Up`).

## B. Initial values to update (Global Variables, column Initial Value)
Only used when Retain values are lost (battery, "clear all memory", renamed variable). Make them match today's settings:
| Variable | Initial now | Set to |
|---|---|---|
| RwMinLearnSpd | 50.0 | **10.0** (auto stops are at final speed ≤ 40 m/min) |
| SoftStopDecel | 0.0 | **500.0** |
| RwDist10V | 750.0 | **785.2** |
| RwAxisDist | 675.3 | current value (≈ 725.8) |
| RwMaxDiam / RwMaxSlowFallback | 1340 / 1310 | the values set for the 1440 roll |
| General rung 3 (Init_Ramp) | DecelCoarse := 0.5 | **1.0** |

## C. S-curve start in AUTO (new)
In AUTO the acceleration is made by the **PLC** ramp (`AccelCoarse` 1.0 ≈ 1.1 Hz/s), not the drive (ACC 3 s ≈ 20 Hz/s) → the drive's S-curve (rPt / TA1–TA2) has almost no effect in AUTO. And since the motor drives the rewinder, the same Hz/s gives a web accel and a torque that grow with the roll: a big roll gets the hardest start.
→ The PLC accel ramp rises progressively after the start: accel 5 % → 100 % in `SoftStartTime` (3 s) = jerk-limited start (speed ∝ t² at the beginning). The end of the accel is already rounded by `AccelTrim` inside the ±8 m/min band.

### Variables
- Global: paste `v6q_Globals_paste.txt` (`SoftStartTime` 3.0 s, Retain). Externals: `v6q_Externals_paste.txt`.
- Internals: `v6q_Locals_paste.txt` (`SoftStartTicks`, `SoftStartK`).

### Motor_Manager: new inline-ST rung between "Optional faster decel" and "Speed correction factor calculation"
Comment: `v6q: S-curve start (AUTO)`
```
// v6q: S-curve start: the accel ramp rises from 5 % to 100 % in SoftStartTime
IF NOT StartMotor_Cmd THEN
    SoftStartTicks := 0;
ELSIF SoftStartTicks < 30000 THEN
    SoftStartTicks := SoftStartTicks + 1;              // 4 ms task
END_IF;
IF SoftStartTime > 0.0 THEN
    SoftStartK := INT_TO_REAL(SoftStartTicks) * 0.004 / SoftStartTime;
    IF SoftStartK < 0.05 THEN
        SoftStartK := 0.05;
    END_IF;
    IF SoftStartK < 1.0 THEN
        Accel_Ramp := Accel_Ramp * SoftStartK;
    END_IF;
END_IF;
```
- Only the start of a run is affected (a pot increase while running is unchanged).
- `SoftStartTime` = 0 → off (as before). 3 s for a start; 5 s for a very soft start of a big roll.
- Manual mode / jog: drive ramp 2 → use the drive S-curve there: rPt = Customized, TA1 / TA2 = 20 %.

### Test
Start in AUTO with a big roll: speed rises gently at first (no jerk on the web, no current peak), then normally. Scope: FRH curve starts flat, LCR without a peak.
