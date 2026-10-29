// V7: coarse ramps in REAL web mm/s2 (DecelWeb / AccelWeb), same on every roll.
// The motor drives the rewinder: drive counts per m/min of web = RwRatioD / diameter.
// RwRatioD (Retain) is learned while running steady in AUTO (drive reference vs encoder).
IF StartMotor_Cmd AND NOT ManMode AND NOT I_LowSpd_OS AND NOT SoftStop
   AND RangeOK AND NOT OverSpeed AND NOT UnderSpeed
   AND (Velocity_M_min > 30.0) AND (DecelDiam >= 100.0) AND NOT RwSensFault THEN
    RatioMeas := INT_TO_REAL(InvRef) * DecelDiam / Velocity_M_min;
    IF (RatioMeas > 1000.0) AND (RatioMeas < 8000.0) THEN
        IF RwRatioD <= 0.0 THEN
            RwRatioD := RatioMeas;
        ELSE
            RwRatioD := RwRatioD + 0.001 * (RatioMeas - RwRatioD);   // 4 ms scan: ~4 s filter
        END_IF;
    END_IF;
END_IF;

IF (RwRatioD > 0.0) AND (DecelDiam >= 100.0) THEN
    WebRatio := RwRatioD / DecelDiam;                                 // counts per m/min
ELSE
    WebRatio := 0.0;
END_IF;

// Coarse ramp active (more than SpdDelta away from the set speed): web units.
// Inside the band DecelTrim / AccelTrim (rung 14) are kept: they are the loop gain.
IF StartMotor_Cmd AND (UnderSpeed OR OverSpeed) AND (WebRatio > 0.0) THEN
    IF DecelWeb > 0.0 THEN
        Decel_Ramp := DecelWeb * 0.06 * WebRatio * Vel_Max_mms / 1000000.0;
        IF Decel_Ramp > 8.0 THEN
            Decel_Ramp := 8.0;
        END_IF;
    END_IF;
    IF AccelWeb > 0.0 THEN
        Accel_Ramp := AccelWeb * 0.06 * WebRatio * Vel_Max_mms / 1000000.0;
        IF Accel_Ramp > 8.0 THEN
            Accel_Ramp := 8.0;
        END_IF;
    END_IF;
END_IF;
