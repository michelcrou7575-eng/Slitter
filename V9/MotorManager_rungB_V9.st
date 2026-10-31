// ==== V9: REPLACE the code of Motor_Manager rung 18 ("Slow adaptation of RwRatioD on the
// ==== relative speed error." = V7 rung B) with this file. (V7a + V7b + V7f + V9 inside.)
// The PLC sends the drive STRAIGHT to the frequency of the set speed
// (VelSet x WebRatio), along a ramp in REAL web mm/s2 that does not depend on the
// measured speed -> no hunting, whatever the roll inertia / web delay.
// The measured speed only adapts RwRatioD slowly (~10 s), once at target.
// It overwrites Vfd_SP_Modif after rung 16, so rung 16 has no effect in AUTO.
// FFEnable = FALSE -> old loop (rung 16) exactly as before.
// V7b: not in jog / slow button (I_Jog_PB): at 10 m/min the feed-forward gives
// only ~0.4 Hz, too little to move the web -> the old loop (rung 16) runs the jog.
FFActive := FFEnable AND NOT ManMode AND NOT I_Jog_PB AND StartMotor_Cmd
            AND ControlVoltage AND (WebRatio > 0.0) AND (Vel_Max_mms > 0.0);

IF NOT StartMotor_Cmd THEN
    RampRef := 0.0;
    FFRate := 0.0;
    FFSteadyTicks := 0;
    FFSlowAcc := FALSE;
END_IF;
// V9: START during a soft stop: the decel flattens and the speed is HELD
// (SpdHold, HMI lamp) until START is pushed AGAIN -> gentle ramp up at
// SoftCancelAccel (mm/s2) to the set speed. The hold only blocks speeding up:
// a lower target (pot down, auto slow-down, RwAutoMaxSpd) still slows down.
// STOP during the hold = new soft stop (General rung 9).
IF (SoftCancelAccel > 0.0) AND (SoftCancelAccel < 20.0) THEN
    SoftCancelAccel := 20.0;
ELSIF SoftCancelAccel > 1000.0 THEN
    SoftCancelAccel := 1000.0;
END_IF;
FFStartEdge := I_Start_PB AND NOT FFStartMem;
FFStartMem := I_Start_PB;
IF FFSoftMem AND NOT SoftStop AND StartMotor_Cmd AND FFActive THEN   // soft stop cancelled
    SpdHold := TRUE;
    FFSlowAcc := FALSE;
ELSIF SpdHold AND FFStartEdge THEN                       // 2nd START: resume
    SpdHold := FALSE;
    FFSlowAcc := TRUE;
END_IF;
IF SoftStop OR NOT StartMotor_Cmd OR NOT FFActive THEN    // FFEnable OFF: old loop
    SpdHold := FALSE;
    FFSlowAcc := FALSE;
END_IF;
FFSoftMem := SoftStop;
// V7f: S-curve time (s), 0 = off, max 2 s
IF SCurveTime < 0.0 THEN
    SCurveTime := 0.0;
ELSIF SCurveTime > 2.0 THEN
    SCurveTime := 2.0;
END_IF;

IF FFActive THEN
    IF NOT FFWasActive THEN
        RampRef := Vel_Max_mms - Vfd_SP_Modif;          // bumpless start / switch-over
        FFRate := 0.0;
    END_IF;

    // Target reference (mm/s of the 0..10 V scale) for the set speed
    FFTarget := VelSet * WebRatio * Output_Ratio;
    IF FFTarget > Vel_Max_mms THEN
        FFTarget := Vel_Max_mms;
    ELSIF FFTarget < 0.0 THEN
        FFTarget := 0.0;
    END_IF;

    // V9: hold after a cancelled soft stop (the S-curve flattens it smoothly):
    // never above the present reference, lower targets still allowed
    IF SpdHold THEN
        IF FFTarget > RampRef THEN
            FFTarget := RampRef;
        END_IF;
    ELSIF FFSlowAcc AND (ABS(FFTarget - RampRef) <= FFTarget * 0.005 + 2.0) THEN
        FFSlowAcc := FALSE;                              // back at the set speed
    END_IF;

    // Ramp steps per 4 ms scan: web mm/s2 -> reference mm/s per scan
    IF FFSlowAcc AND (SoftCancelAccel > 0.0) THEN
        StepAcc := SoftCancelAccel * 0.06 * WebRatio * Vel_Max_mms / 1000000.0;   // V9
    ELSIF AccelWeb > 0.0 THEN
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
    // V7f: S-curve. FFRate (reference per scan) changes at most FFJerk per scan,
    // so the full ramp is reached after SCurveTime (s) and is rounded off the
    // same way before the target -> the T-one / brake air can follow.
    // SCurveTime = 0 -> plain linear ramp as V7a.
    IF SCurveTime > 0.0 THEN
        IF (FFRate > 0.0) OR ((FFRate = 0.0) AND (FFTarget > RampRef)) THEN
            FFJerk := StepAcc * 0.004 / SCurveTime;
        ELSE
            FFJerk := StepDec * 0.004 / SCurveTime;
        END_IF;
        // rate allowed so that it can still fall to 0 at the target
        // (no MIN(), argument in a REAL variable first: Sysmac data type rules,
        //  same pattern as SqrtArg / SQRT(SqrtArg) in AutoStop)
        IF FFTarget >= RampRef THEN
            FFSqrtArg := REAL#2.0 * FFJerk * (FFTarget - RampRef);
            FFRateSet := SQRT(FFSqrtArg);
            IF FFRateSet > StepAcc THEN
                FFRateSet := StepAcc;
            END_IF;
        ELSE
            FFSqrtArg := REAL#2.0 * FFJerk * (RampRef - FFTarget);
            FFRateSet := SQRT(FFSqrtArg);
            IF FFRateSet > StepDec THEN
                FFRateSet := StepDec;
            END_IF;
            FFRateSet := -FFRateSet;
        END_IF;
        IF FFRateSet > FFRate + FFJerk THEN
            FFRate := FFRate + FFJerk;
        ELSIF FFRateSet < FFRate - FFJerk THEN
            FFRate := FFRate - FFJerk;
        ELSE
            FFRate := FFRateSet;
        END_IF;
        RampRef := RampRef + FFRate;
        IF (ABS(FFTarget - RampRef) <= 3.0) AND (ABS(FFRate) <= 2.0 * FFJerk) THEN
            RampRef := FFTarget;                         // at target (pot noise)
            FFRate := 0.0;
        END_IF;
    ELSE
        FFRate := 0.0;
        IF RampRef < FFTarget - StepAcc THEN
            RampRef := RampRef + StepAcc;
        ELSIF RampRef > FFTarget + StepDec THEN
            RampRef := RampRef - StepDec;
        ELSE
            RampRef := FFTarget;                         // at target
        END_IF;
    END_IF;
    // V7a: "at target" = within 0.5 % of the target (the pot and RwDiam noise
    // move FFTarget by a few counts every scan -> the counter never reached 500)
    IF (ABS(FFTarget - RampRef) <= FFTarget * 0.005 + 2.0)
       AND NOT SpdHold AND NOT FFSlowAcc THEN            // V9: not during the hold
        IF FFSteadyTicks < 30000 THEN
            FFSteadyTicks := FFSteadyTicks + 1;
        END_IF;
    ELSE
        FFSteadyTicks := 0;
    END_IF;

    // Slow adaptation of RwRatioD on the relative speed error (2 s after the
    // target is reached, not at the 60 Hz limit, not during soft stop / jog)
    IF (FFSteadyTicks >= 500) AND NOT SoftStop AND NOT I_Jog_PB
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

// V7f: T-one decel signal (for a T-one "stop / boost" input, spare PLC output):
// ON while the feed-forward ramps down (more than 1 % above the target, so the
// slow drift of the target with the diameter does not pulse it) or soft stop.
TOneDecel := (FFActive AND (RampRef - FFTarget > FFTarget * 0.01 + 5.0))
             OR (SoftStop AND StartMotor_Cmd);
