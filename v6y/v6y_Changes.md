# v6y: work speed limited to 500 m/min when the rewinder AUTO stop is ON

**Base:** print 1028_2 (Motor_Manager rungs 5/7/8 as printed, AutoStop v6x). Also merged into V7 (`V7/AutoStop_Control_V7.st`).

## Behaviour
- Rewinder AUTO stop ON (`RwStopEnable`) in AUTO mode → the work speed set point is limited to **`RwAutoMaxSpd`** (new global, REAL, Retain, **500** m/min, Publish Only). 0 = no limit.
- **Changes are taken over at standstill only** (like the pot ranges, v6n): switching rewinder AUTO on/off or changing `RwAutoMaxSpd` while running has no effect on the speed until the next stop. Meanwhile **`SpdMax_Pending`** is ON (HMI "NEW RANGE AT NEXT STOP" already uses it).
- The work pot keeps its scale; above the limit it has no effect.
- The HMI WORK SPEED display shows the limited value.
- The slow-down length (AutoStop section 6) is computed with the limited speed.
- Unwinder AUTO (meters), manual mode, jog: unchanged.

## 1. Variables
- Global Variables: paste `v6y_Globals_paste.txt` (`RwAutoMaxSpd`). Externals: type `RwAutoMaxSpd`.
- Internals: paste `v6y_Locals_paste.txt` (`RwAutoLimAct`, `RwAutoMaxSpdAct`).

## 2. Motor_Manager rung 5: add at the end (after the JogSpd_SP clamp)
```
// v6y: rewinder AUTO max speed, 0 = no limit
IF RwAutoMaxSpd > VelMax THEN
    RwAutoMaxSpd := VelMax;
ELSIF (RwAutoMaxSpd > REAL#0) AND (RwAutoMaxSpd < REAL#50) THEN
    RwAutoMaxSpd := REAL#50;
END_IF;
// taken over at standstill only
IF NOT StartMotor_Cmd THEN
    RwAutoLimAct := RwStopEnable AND (RwAutoMaxSpd > REAL#0);
    RwAutoMaxSpdAct := RwAutoMaxSpd;
END_IF;
```

## 2b. Motor_Manager rung 6: SpdMax_Pending (lines 19–20) becomes
```
SpdMax_Pending := (WorkSpd_Max <> WorkSpd_Max_Set)
               OR (FinalSpd_Max <> FinalSpd_Max_Set)
               OR (RwAutoLimAct <> (RwStopEnable AND (RwAutoMaxSpd > REAL#0)))
               OR (RwAutoLimAct AND (RwAutoMaxSpdAct <> RwAutoMaxSpd));
```

## 3. Motor_Manager rung 7 ("Updating the set speed"): ManMode = FALSE branch, after the 2 lines
```
IF ManMode = FALSE THEN;
    Speed_Display := UINT_TO_REAL(Pot1_Mem) / Input_Ratio;
    LowSpd_Display := UINT_TO_REAL(Pot2_Mem) / Input_Ratio;
    // v6y: rewinder AUTO stop -> work speed limited
    IF RwAutoLimAct AND (Speed_Display > RwAutoMaxSpdAct) THEN
        Speed_Display := RwAutoMaxSpdAct;
    END_IF;
ELSE;
    ... (unchanged)
```

## 4. Motor_Manager rung 8 ("Updating potentiometer value", ManMode NC): ST box
```
IF SoftStop THEN
    VelSet := 0.0;                                  // v6m: soft stop
ELSIF SlowDown = FALSE THEN
    VelSet := UINT_TO_REAL(Pot1_Mem) / Input_Ratio;
    // v6y: rewinder AUTO stop -> work speed limited
    IF RwAutoLimAct AND (VelSet > RwAutoMaxSpdAct) THEN
        VelSet := RwAutoMaxSpdAct;
    END_IF;
ELSE
    VelSet := UINT_TO_REAL(Pot2_Mem) / Input_Ratio;
END_IF;
VelSet_mms := VelSet * Mt_To_mm;
```

## 5. AutoStop_Control
Replace the ST with `AutoStop_Control_v6y.st` (= v6x + 5 lines in section 6). (With V7: use `V7/AutoStop_Control_V7.st`, it already contains them.)

## 6. HMI (optional)
Password page: input **REWINDER AUTO MAX SPEED [m/min]** → `RwAutoMaxSpd`, format ###, limits 0–800.

## Test
Machine stopped, rewinder AUTO ON, start with the work pot at max (> 500): speed = 500, display = 500. While running: AUTO OFF or `RwAutoMaxSpd` changed → speed unchanged, "NEW RANGE AT NEXT STOP" shown; after STOP + START the new setting applies.
