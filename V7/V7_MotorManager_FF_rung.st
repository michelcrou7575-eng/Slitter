// ==== V7 rung B: put AFTER rung 16 ("Speed correction factor calculation")
// ==== and BEFORE rung 17 ("Management of the inverter speed reference ...").
// ==== Comment: "V7: feed-forward speed loop (AUTO)"
// The PLC sends the drive STRAIGHT to the frequency of the set speed
// (VelSet x WebRatio), along a ramp in REAL web mm/s2 that does not depend on the
// measured speed -> no hunting, whatever the roll inertia / web delay.
// The measured speed only adapts RwRatioD slowly (~10 s), once at target.
// It overwrites Vfd_SP_Modif after rung 16, so rung 16 has no effect in AUTO.
// FFEnable = FALSE -> old loop (rung 16) exactly as before.
FFActive := FFEnable AND NOT ManMode AND StartMotor_Cmd AND ControlVoltage
            AND (WebRatio > 0.0) AND (Vel_Max_mms > 0.0);

IF NOT StartMotor_Cmd THEN
    RampRef := 0.0;
    FFSteadyTicks := 0;
END_IF;

IF FFActive THEN
    IF NOT FFWasActive THEN
        RampRef := Vel_Max_mms - Vfd_SP_Modif;          // bumpless start / switch-over
    END_IF;

    // Target reference (mm/s of the 0..10 V scale) for the set speed
    FFTarget := VelSet * WebRatio * Output_Ratio;
    IF FFTarget > Vel_Max_mms THEN
        FFTarget := Vel_Max_mms;
    ELSIF FFTarget < 0.0 THEN
        FFTarget := 0.0;
    END_IF;

    // Ramp steps per 4 ms scan: web mm/s2 -> reference mm/s per scan
    IF AccelWeb > 0.0 THEN
        StepAcc := AccelWeb * 0.06 * WebRatio * Vel_Max_mms / 1000000.0;
    ELSE
        StepAcc := AccelCoarse;
    END_IF;
    IF SoftStop AND (SoftStopDecel > 0.0) THEN
        StepDec := SoftStopDecel * 0.06 * WebRatio * Vel_Max_mms / 1000000.0;
    ELSIF DecelWeb > 0.0 THEN
        StepDec := DecelWeb * 0.06 * WebRatio * Vel_Max_mms / 1000000.0;
    ELSE
        StepDec := DecelCoarse;
    END_IF;
    IF StepAcc > 8.0 THEN
        StepAcc := 8.0;
    END_IF;
    IF StepDec > 8.0 THEN
        StepDec := 8.0;
    END_IF;

    // Ramp generator
    IF RampRef < FFTarget - StepAcc THEN
        RampRef := RampRef + StepAcc;
        FFSteadyTicks := 0;
    ELSIF RampRef > FFTarget + StepDec THEN
        RampRef := RampRef - StepDec;
        FFSteadyTicks := 0;
    ELSE
        RampRef := FFTarget;                             // at target
        IF FFSteadyTicks < 30000 THEN
            FFSteadyTicks := FFSteadyTicks + 1;
        END_IF;
    END_IF;

    // Slow adaptation of RwRatioD on the relative speed error (2 s after the
    // target is reached, not at the 60 Hz limit, not during soft stop / jog)
    IF (FFSteadyTicks >= 500) AND NOT SoftStop AND NOT I_LowSpd_OS
       AND (VelSet > 15.0) AND (Velocity_M_min > 10.0) AND NOT RwSensFault
       AND (FFTarget < Vel_Max_mms * 0.98) THEN
        FFErr := (VelSet - Velocity_M_min) / VelSet;
        IF FFErr > 0.05 THEN
            FFErr := 0.05;
        ELSIF FFErr < -0.05 THEN
            FFErr := -0.05;
        END_IF;
        IF ABS(FFErr) > 0.003 THEN                       // dead band 0.3 % (encoder noise)
            RwRatioD := RwRatioD * (1.0 + 0.0004 * FFErr);  // ~10 s time constant
        END_IF;
        IF RwRatioD < 1000.0 THEN
            RwRatioD := 1000.0;
        ELSIF RwRatioD > 8000.0 THEN
            RwRatioD := 8000.0;
        END_IF;
    END_IF;

    Vfd_SP_Modif := Vel_Max_mms - RampRef;               // rung 17 -> InvRef
END_IF;
FFWasActive := FFActive;
