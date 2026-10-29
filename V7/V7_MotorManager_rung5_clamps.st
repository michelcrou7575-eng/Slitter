// ---- V7: add at the END of Motor_Manager rung 5 ("Check the maximum and minimum values...")
// ---- after the JogSpd_SP clamp, before Output_Ratio. Same style as the VelMax / JogSpd clamps.
// V7: limits on settings that stop the machine or break the auto stop if 0 / absurd
IF SpdDelta_Percent < REAL#2 THEN                  // fine band [m/min]: 0 = speed hunting
    SpdDelta_Percent := REAL#2;
ELSIF SpdDelta_Percent > REAL#15 THEN
    SpdDelta_Percent := REAL#15;
END_IF;

IF AccelTrim < REAL#0.02 THEN                      // trim ramps: 0 = no speed correction
    AccelTrim := REAL#0.02;
ELSIF AccelTrim > REAL#0.5 THEN
    AccelTrim := REAL#0.5;
END_IF;
IF DecelTrim < REAL#0.02 THEN
    DecelTrim := REAL#0.02;
ELSIF DecelTrim > REAL#0.5 THEN
    DecelTrim := REAL#0.5;
END_IF;

IF AccelCoarse < REAL#0.2 THEN                     // coarse ramps: 0 = never reaches speed
    AccelCoarse := REAL#0.2;
ELSIF AccelCoarse > REAL#4 THEN
    AccelCoarse := REAL#4;
END_IF;
IF DecelCoarse < REAL#0.2 THEN
    DecelCoarse := REAL#0.2;
ELSIF DecelCoarse > REAL#4 THEN
    DecelCoarse := REAL#4;
END_IF;

IF DecelWeb > REAL#0 THEN                          // V7 web ramps: 0 = old coarse ramp (allowed)
    IF DecelWeb < REAL#50 THEN
        DecelWeb := REAL#50;
    ELSIF DecelWeb > REAL#1000 THEN
        DecelWeb := REAL#1000;
    END_IF;
END_IF;
IF AccelWeb > REAL#0 THEN
    IF AccelWeb < REAL#50 THEN
        AccelWeb := REAL#50;
    ELSIF AccelWeb > REAL#1000 THEN
        AccelWeb := REAL#1000;
    END_IF;
END_IF;
IF SoftStopDecel > REAL#1500 THEN                  // 0 = DecelCoarse (allowed)
    SoftStopDecel := REAL#1500;
END_IF;

IF RwMaxDiam > REAL#1450 THEN                      // rewinder MECHANICAL limit [mm]
    RwMaxDiam := REAL#1450;
ELSIF RwMaxDiam < REAL#300 THEN
    RwMaxDiam := REAL#300;
END_IF;
IF RwMaxSlowFallback >= RwMaxDiam THEN             // fallback slow-down below the max
    RwMaxSlowFallback := RwMaxDiam - REAL#30;
END_IF;
