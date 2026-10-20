# v6i: pots with finer adjustment (Work 0–400, Final 0–40 m/min)

## Problem
Both console pots (13RP1 Work speed, 13RP2 Final speed, plan sheet 13) cover **0–`VelMax`** (800 m/min) over a full turn: too sensitive.
Wanted: **Work 0–400 m/min**, **Final 0–40 m/min**.

## How the pots are used today (print 1019_10)
| Where | Use |
|---|---|
| Motor_Manager rung 6 | `Pot1_Work_Velocity` / `Pot2_Slow_Velocity` (raw 0–4000) → `Pot1_Mem` / `Pot2_Mem` (dead band ≤ 5) |
| rung 7 | `Speed_Display` / `LowSpd_Display` = Pot_Mem / `Input_Ratio` (m/min) |
| rung 8 (auto) | `VelSet` = Pot_Mem / `Input_Ratio` |
| rung 17 (ManMode) | `InvRef` := **raw** pot (bypasses Pot_Mem) |
| AutoStop_Control section 6 | `SpdWork_Pps` / `SpdFinal_Pps` from Pot_Mem / `Input_Ratio` |

`Input_Ratio` = `Analog_Res` / `VelMax`, so full pot = `VelMax`.
→ Scaling **Pot_Mem** in rung 6 by `WorkSpd_Max / VelMax` (and `FinalSpd_Max / VelMax`) makes rungs 7 and 8 and AutoStop follow automatically. Rung 17 must use Pot_Mem instead of the raw value.

## Changes

### 1. Globals (Retain, Publish Only)
Paste `v6i_Globals_paste.txt` in Global Variables and `v6i_Externals_paste.txt` in the program Externals:
`WorkSpd_Max` = **400.0**, `FinalSpd_Max` = **40.0** (m/min, settable from the HMI).

### 2. Motor_Manager rung 6: replace the 4 compare + MOVE blocks with one inline ST
```
// v6i: pots scaled to their own full scale (m/min). 0..Analog_Res -> 0..xxxSpd_Max
IF WorkSpd_Max < 50.0 THEN
    WorkSpd_Max := 50.0;
ELSIF WorkSpd_Max > VelMax THEN
    WorkSpd_Max := VelMax;
END_IF;
IF FinalSpd_Max < 5.0 THEN
    FinalSpd_Max := 5.0;
ELSIF FinalSpd_Max > WorkSpd_Max THEN
    FinalSpd_Max := WorkSpd_Max;
END_IF;

IF Pot1_Work_Velocity > INT#5 THEN
    Pot1_Mem := REAL_TO_INT(INT_TO_REAL(Pot1_Work_Velocity) * WorkSpd_Max / VelMax);
ELSE
    Pot1_Mem := INT#0;
END_IF;
IF Pot2_Slow_Velocity > INT#5 THEN
    Pot2_Mem := REAL_TO_INT(INT_TO_REAL(Pot2_Slow_Velocity) * FinalSpd_Max / VelMax);
ELSE
    Pot2_Mem := INT#0;
END_IF;
```
(Rung 5 runs before it, so `VelMax` is already clamped to 600–1000 and never 0.)

### 3. Motor_Manager rung 17 (ManMode): use the scaled values
```
IF SlowDown = FALSE THEN
    InvRef := Pot1_Mem;            // was Pot1_Work_Velocity
ELSE
    InvRef := Pot2_Mem;            // was Pot2_Slow_Velocity
END_IF;
```

### 4. HMI (ramp page, behind the password)
Two numeric inputs: **WORK SPEED POT MAX** → `WorkSpd_Max` (#### m/min, limits 50–1000) and **FINAL SPEED POT MAX** → `FinalSpd_Max` (### m/min, limits 5–400).

## Result
| Pot | Before | After |
|---|---|---|
| Work speed (13RP1) | 0–800 m/min | **0–400 m/min** (2× finer) |
| Final speed (13RP2) | 0–800 m/min | **0–40 m/min** (20× finer) |

- `VelMax` (800) stays the analog scale of the drive reference (10 V = 800 m/min), and is unchanged.
- AutoStop (slow-down / stop lengths) uses the new speeds automatically.
- In **ManMode**, the HMI display (rung 7, the "÷ Analog_Res/40" formula) now also reads half / one twentieth. It was already not in m/min. Optional: let me know if you want ManMode to show m/min too.

## Test
1. Pot at maximum → `Speed_Display` = 400, `LowSpd_Display` = 40.
2. Run at 400 m/min: `Velocity_M_min` ≈ 400 (the speed loop is unchanged).
3. Auto slow-down: the machine goes to final speed (≤ 40 m/min), then stops at the meter or diameter point.
