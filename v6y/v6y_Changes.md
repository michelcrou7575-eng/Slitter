# v6y: work speed limited to 500 m/min when the rewinder AUTO stop is ON

**Base:** print 1028_2 (Motor_Manager rungs 5/7/8 as printed, AutoStop v6x). Also merged into V7 (`V7/AutoStop_Control_V7.st`).

## Behaviour
- Rewinder AUTO stop ON (`RwStopEnable`) in AUTO mode → the work speed set point is limited to **`RwAutoMaxSpd`** (new global, REAL, Retain, **500** m/min, Publish Only). 0 = no limit.
- The work pot keeps its scale; above 500 it has no effect while rewinder AUTO is ON.
- AUTO switched ON while running faster → the speed comes down to 500 (normal coarse ramp).
- The HMI WORK SPEED display shows the limited value.
- The slow-down length (AutoStop section 6) is computed with the limited speed.
- Unwinder AUTO (meters), manual mode, jog: unchanged.

## 1. Variables
Global Variables: paste `v6y_Globals_paste.txt`. Externals: type `RwAutoMaxSpd`.

## 2. Motor_Manager rung 5: add at the end (after the JogSpd_SP clamp)
```
// v6y: rewinder AUTO max speed, 0 = no limit
IF RwAutoMaxSpd > VelMax THEN
    RwAutoMaxSpd := VelMax;
ELSIF (RwAutoMaxSpd > REAL#0) AND (RwAutoMaxSpd < REAL#50) THEN
    RwAutoMaxSpd := REAL#50;
END_IF;
```

## 3. Motor_Manager rung 7 ("Updating the set speed"): ManMode = FALSE branch, after the 2 lines
```
IF ManMode = FALSE THEN;
    Speed_Display := UINT_TO_REAL(Pot1_Mem) / Input_Ratio;
    LowSpd_Display := UINT_TO_REAL(Pot2_Mem) / Input_Ratio;
    // v6y: rewinder AUTO stop -> work speed limited
    IF RwStopEnable AND (RwAutoMaxSpd > 0.0) AND (Speed_Display > RwAutoMaxSpd) THEN
        Speed_Display := RwAutoMaxSpd;
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
    IF RwStopEnable AND (RwAutoMaxSpd > 0.0) AND (VelSet > RwAutoMaxSpd) THEN
        VelSet := RwAutoMaxSpd;
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
Rewinder AUTO ON, work pot at max (> 500): speed = 500, WORK SPEED display = 500, "SLOW DOWN AT" consistent. AUTO OFF: back to the pot value.
