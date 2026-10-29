// ==== V7 rung A: put DIRECTLY AFTER rung 14 ("Acceleration/deceleration factor selection")
// ==== and BEFORE rung 15 ("Soft Stop - SoftStopDecel ..."). Comment: "V7: web ratio + web ramps"
// Ratio drive counts per m/min of web at the current rewinder diameter.
// The motor drives the rewinder: web speed per Hz grows with the diameter, so
// counts per m/min = RwRatioD / diameter. RwRatioD (Retain) is adapted by rung B.
IF (RwRatioD > 0.0) AND (DecelDiam >= 100.0) THEN
    WebRatio := RwRatioD / DecelDiam;
ELSE
    WebRatio := 0.0;
END_IF;

// Fallback only (FFEnable = FALSE): old integrating loop (rung 16) with the coarse
// ramps in real web mm/s2. With FFEnable = TRUE, rung B drives the reference.
// V7b: never in jog / slow button -> jog keeps the rung 14 ramps exactly as v6y.
IF NOT FFEnable AND NOT I_LowSpd_OS AND StartMotor_Cmd AND (UnderSpeed OR OverSpeed)
   AND (WebRatio > 0.0) THEN
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
