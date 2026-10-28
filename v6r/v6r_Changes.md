# v6r: soft stop with a REAL web deceleration (same for every roll)

## Problem
`Decel_Ramp := SoftStopDecel / 250` is a fixed **Hz/s** ramp (500 → 2.25 Hz/s). The motor drives the rewinder, so 400 m/min is ≈ 45 Hz on a 445 mm roll but ≈ 14 Hz on a 1400 mm roll:
small roll → 20 s / 65 m, big roll → 6 s / 21 m. Backwards.

## Principle
At the first scan of the soft stop the PLC freezes the ratio
`SoftStopRatio = InvRef / Velocity_M_min` (drive counts per m/min of web, measured by the encoder = exact for this roll, independent of the DT35 and of the gear ratio).
Then the PLC ramp is computed so that the **web** decelerates at `SoftStopDecel` mm/s²:
```
counts/s  = a [mm/s²] × 0.06 × SoftStopRatio
Decel_Ramp (mm/s per 4 ms scan) = counts/s × Vel_Max_mms / (250 × 4000)
          = a × 0.06 × SoftStopRatio × Vel_Max_mms / 1 000 000
```
Check with the 10/27 scope: 200 m/min, 22.5 Hz = 1500 counts → ratio 7.5; Decel_Ramp 2.0 gave 333 mm/s²; formula: 333 × 0.06 × 7.5 × 13333 / 1e6 = 2.0 ✓

## 1. Variables
- Internals: paste `v6r_Locals_paste.txt` (`SoftStopMem`, `SoftStopRatio`).
- `SoftStopDecel` keeps its name but its **meaning changes**: now real web mm/s². Comment: "Soft stop web decel (mm/s²), 0 = DecelCoarse". **New value: 400** (see table). Initial value 400.

## 2. Motor_Manager rung "Optional faster decel": replace the ST
```
// v6r: soft stop at a REAL web decel SoftStopDecel (mm/s2), same for every roll.
// Ratio drive counts / web m/min frozen at the soft stop start (encoder = exact).
IF SoftStop AND NOT SoftStopMem THEN
    IF Velocity_M_min > 1.0 THEN
        SoftStopRatio := INT_TO_REAL(InvRef) / Velocity_M_min;
    ELSE
        SoftStopRatio := 0.0;
    END_IF;
END_IF;
SoftStopMem := SoftStop;

IF SoftStop AND (SoftStopDecel > 0.0) THEN
    IF SoftStopRatio > 0.0 THEN
        Decel_Ramp := SoftStopDecel * 0.06 * SoftStopRatio * Vel_Max_mms / 1000000.0;
    ELSE
        Decel_Ramp := SoftStopDecel / 250.0;            // fallback (old v6m behaviour)
    END_IF;
    IF Decel_Ramp > 8.0 THEN
        Decel_Ramp := 8.0;                              // max 9 Hz/s asked from the PLC
    END_IF;
END_IF;
```

## 3. Result (SoftStopDecel = real web decel)
| SoftStopDecel | 400 m/min → stop | run-out | 200 m/min → stop |
|---|---|---|---|
| 300 mm/s² | ≈ 22 s | ≈ 74 m | ≈ 11 s |
| 400 mm/s² | ≈ 17 s | ≈ 56 m | ≈ 8 s |
| 600 mm/s² | ≈ 11 s | ≈ 37 m | ≈ 5.5 s |
| 800 mm/s² | ≈ 8 s | ≈ 28 m | ≈ 4 s |
**Same for every roll diameter.** (10/27 test at 445 mm ≈ 333 mm/s².)
Small roll: high Hz/s but little energy (no problem for the drive). Big roll: low Hz/s but most energy → check VBUS on the first stops with a big roll at 400 m/min.

## Test
1. 200 m/min, any roll, STOP once: stop time ≈ 6667/2/a… e.g. 400 mm/s² → ≈ 8 s. Watch tab: `TaglMonoTRM.SoftStopRatio` (≈ 7.5 at 445 mm), `Decel_Ramp`.
2. Same at another diameter: same stop time.
3. Big roll at 300–400 m/min with the SoMove scope (VBUS) before raising `SoftStopDecel` above 400.
