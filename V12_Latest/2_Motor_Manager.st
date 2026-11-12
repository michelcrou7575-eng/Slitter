(* =====================================================================
   SECTION: Motor_Manager  (V12_1110_6 + pending Metre reset)
   ===================================================================== *)

// Rung 0  "Enable encoder reading"   T_PlcOn.Q -> ( Encoder_On )

// Rung 1  "mm per encoder pulse" (ST)

IF Encoder_Pulse = INT#0 THEN
    Encoder_Pulse := INT#1;
END_IF;
// Encoder Standard 400mm

IF EncoderWheel_Circumf = REAL#0 THEN
    EncoderWheel_Circumf := REAL#400;
END_IF;
EncoderPulse_to_mm := EncoderWheel_Circumf / (INT_TO_REAL(Encoder_Pulse) * REAL#4);

// Rung 1b "Metre counter auto reset at the next START" (ST)  -- PENDING (Metre_Reset)
// ==== Motor_Manager: NEW ST rung (no contact), directly BEFORE rung 2 ("Reset encoder counter")
// ==== Comment: "Metre counter auto reset at the next START"
// CntResetMode: 0 = manual only, 1 = with new roll (new parent roll on the unwinder),
//               2 = after auto-stop.  The event arms CntResetPend; the reset happens
//               with the next accepted START; the old length is kept in LastRoll_m.
// While CntResetPend: the metre AUTO STOP / slow-down / refusal ignore the old metres.

IF (CntResetMode < 0) OR (CntResetMode > 2) THEN
    CntResetMode := 0;
END_IF;

// unwinder roll was empty (at the stop diameter) since the last reset

IF Measure_ON AND UnWinder_Empty THEN
    CntUwWasEmpty := TRUE;
END_IF;
// new parent roll: stopped, sonar ON, roll no longer empty for 3 s, after an empty roll
T_CntNewRoll(In := NOT StartMotor_Cmd AND Measure_ON AND CntUwWasEmpty
                   AND NOT UnWinder_Empty AND (UwDiam_Act > 0.0), PT := T#3s);

// arm the reset (machine stopped)

IF NOT StartMotor_Cmd
   AND (((CntResetMode = 1) AND T_CntNewRoll.Q) OR ((CntResetMode = 2) AND AutoStopDone)) THEN
    CntResetPend := TRUE;
    CntUwWasEmpty := FALSE;
END_IF;

IF CntResetMode = 0 THEN
    CntResetPend := FALSE;
END_IF;

// START accepted with a reset pending -> keep the length, 50 ms reset pulse
CntPulseReq := CntResetPend AND StartPB_OK AND NOT CntStartMem AND NOT StartBlocked;
CntStartMem := StartPB_OK;

IF CntPulseReq THEN
    LastRoll_m := Current_Metre;
    CntPulseDone := TRUE;
END_IF;
T_CntResetPulse(In := CntPulseReq, PT := T#50ms);          // TP
CntAutoReset := T_CntResetPulse.Q;

// pending cleared when the counter is back near 0 (or 2 s after the pulse, safety)
T_CntDone(In := CntPulseDone AND NOT T_CntResetPulse.Q, PT := T#2s);

IF CntPulseDone AND NOT T_CntResetPulse.Q
   AND ((Current_Metre < REAL#1.0) OR T_CntDone.Q) THEN
    CntResetPend := FALSE;
    CntPulseDone := FALSE;
END_IF;

// Rung 2  "Reset encoder counter"
//   (Counter_Reset AND NOT StartMotor_Cmd) OR CntAutoReset (pending)    -> ( Encoder_Reset )
//   (1110_6: only Counter_Reset AND NOT StartMotor_Cmd; I_RsetCnt not used)

// Rung 3  "Checking the slowdown point"
//   (AutoSlowCmd OR (Measure_ON AND SlowByDiam)) AND StartMotor_Cmd     -> ( SlowDown )

// Rung 4  "Checking the stop point"
//   (I_WebBreak_Monitor AND I_WebBreak_PH AND NOT I_Jog_PB AND StartMotor_Cmd) OR EndStopNow -> ( Stop )

// Rung 5  "Check the maximum and minimum values" (ST)

IF VelMax < REAL#600 THEN
    VelMax := REAL#600;
ELSIF VelMax > REAL#1000 THEN
    VelMax := REAL#1000;
END_IF;
Vel_Max_mms := VelMax * REAL#1000 / REAL#60;

IF JogSpd_SP < REAL#10 THEN
    JogSpd_SP := REAL#10;
ELSIF JogSpd_SP > REAL#70 THEN
    JogSpd_SP := REAL#70;
END_IF;
// v6y: rewinder AUTO max speed, 0 = no limit

IF RwAutoMaxSpd > VelMax THEN
    RwAutoMaxSpd := VelMax;
ELSIF (RwAutoMaxSpd > REAL#0) AND (RwAutoMaxSpd < REAL#50) THEN
    RwAutoMaxSpd := REAL#50;
END_IF;

IF NOT StartMotor_Cmd THEN        // taken over at standstill only
    RwAutoLimAct := RwStopEnable AND (RwAutoMaxSpd > REAL#0);
    RwAutoMaxSpdAct := RwAutoMaxSpd;
END_IF;
// V7: limits on settings that stop the machine or break the auto stop if 0 / absurd

IF SpdDelta_Percent < REAL#2 THEN
    SpdDelta_Percent := REAL#2;
ELSIF SpdDelta_Percent > REAL#15 THEN
    SpdDelta_Percent := REAL#15;
END_IF;

IF AccelTrim < REAL#0.02 THEN
    AccelTrim := REAL#0.02;
ELSIF AccelTrim > REAL#0.5 THEN
    AccelTrim := REAL#0.5;
END_IF;

IF DecelTrim < REAL#0.02 THEN
    DecelTrim := REAL#0.02;
ELSIF DecelTrim > REAL#0.5 THEN
    DecelTrim := REAL#0.5;
END_IF;

IF AccelCoarse < REAL#0.2 THEN
    AccelCoarse := REAL#0.2;
ELSIF AccelCoarse > REAL#4 THEN
    AccelCoarse := REAL#4;
END_IF;

IF DecelCoarse < REAL#0.2 THEN
    DecelCoarse := REAL#0.2;
ELSIF DecelCoarse > REAL#4 THEN
    DecelCoarse := REAL#4;
END_IF;

IF DecelWeb > REAL#0 THEN

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

IF SoftStopDecel > REAL#1500 THEN
    SoftStopDecel := REAL#1500;
END_IF;

IF RwMaxDiam > REAL#1450 THEN
    RwMaxDiam := REAL#1450;
ELSIF RwMaxDiam < REAL#300 THEN
    RwMaxDiam := REAL#300;
END_IF;

IF RwMaxSlowFallback >= RwMaxDiam THEN
    RwMaxSlowFallback := RwMaxDiam - REAL#30;
END_IF;
// V7d: jog blocked on a big rewinder roll (0 = no limit, else min 150); DT35 fault -> jog allowed

IF (RwJogMaxDiam > REAL#0) AND (RwJogMaxDiam < REAL#150) THEN
    RwJogMaxDiam := REAL#150;
END_IF;
JogInhibit := (RwJogMaxDiam > REAL#0) AND (RwDiam > RwJogMaxDiam) AND NOT RwSensFault;
Output_Ratio := (VelMax * Mt_To_mm) / UINT_TO_REAL(Analog_Res); //REAL#4000;
Input_Ratio := UINT_TO_REAL(Analog_Res) / VelMax ;

// Rung 6  "Reading the potentiometers" (ST)

IF WorkSpd_Max_Set < 50.0 THEN
    WorkSpd_Max_Set := 50.0;
ELSIF WorkSpd_Max_Set > VelMax THEN
    WorkSpd_Max_Set := VelMax;
END_IF;

IF FinalSpd_Max_Set < 5.0 THEN
    FinalSpd_Max_Set := 5.0;
ELSIF FinalSpd_Max_Set > WorkSpd_Max_Set THEN
    FinalSpd_Max_Set := WorkSpd_Max_Set;
END_IF;

IF NOT StartMotor_Cmd THEN
    WorkSpd_Max := WorkSpd_Max_Set;          // motor stopped: apply
    FinalSpd_Max := FinalSpd_Max_Set;
END_IF;
SpdMax_Pending := (WorkSpd_Max <> WorkSpd_Max_Set)
               OR (FinalSpd_Max <> FinalSpd_Max_Set)
               OR (RwAutoLimAct <> (RwStopEnable AND (RwAutoMaxSpd > REAL#0)))
               OR (RwAutoLimAct AND (RwAutoMaxSpdAct <> RwAutoMaxSpd));
// v6i: pots scaled to their own full scale (m/min)

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

// Rung 7  "Updating the set speed" (ST)

IF ManMode = FALSE THEN
    Speed_Display := UINT_TO_REAL(Pot1_Mem) / Input_Ratio;
    LowSpd_Display := UINT_TO_REAL(Pot2_Mem) / Input_Ratio;
    // v6y: rewinder AUTO stop -> work speed limited

    IF RwAutoLimAct AND (Speed_Display > RwAutoMaxSpdAct) THEN
        Speed_Display := RwAutoMaxSpdAct;
    END_IF;
ELSE
    Speed_Display := Pot1_Work_Velocity / (Analog_Res / UINT#40); // v6i: raw pot, %
    LowSpd_Display := Pot2_Slow_Velocity / (Analog_Res / UINT#40);
END_IF;

// Rung 8  "Updating potentiometer value"   NOT ManMode AND NOT JogRun -> ST:

IF SoftStop THEN
    VelSet := 0.0;                           // v6m: soft stop
ELSIF SlowDown = FALSE THEN
    VelSet := UINT_TO_REAL(Pot1_Mem) / Input_Ratio;

    IF RwAutoLimAct AND (VelSet > RwAutoMaxSpdAct) THEN
        VelSet := RwAutoMaxSpdAct;
    END_IF;
ELSE
    VelSet := UINT_TO_REAL(Pot2_Mem) / Input_Ratio;
END_IF;
VelSet_mms := VelSet * Mt_To_mm;

// Rung 9  "Slow speed"   NOT ManMode AND JogRun -> ST:
VelSet := JogSpd_SP;
VelSet_mms := VelSet * Mt_To_mm;

// Rung 10 "Set speed vs detected speed" (ST)
SpdDelta := SpdDelta_Percent;
SpdDeltaMax := VelSet + SpdDelta;
SpdDeltaMin := VelSet - SpdDelta;

IF Velocity_M_min > SpdDeltaMax THEN
    OverSpeed := TRUE;
ELSE
    OverSpeed := FALSE;
END_IF;

IF Velocity_M_min < SpdDeltaMin THEN
    UnderSpeed := TRUE;
ELSE
    UnderSpeed := FALSE;
END_IF;

// Rung 11 "Speed calculation" (ST, V9 exact 100 ms)
// ==== V9: REPLACE Motor_Manager rungs 11 ("Read the current value of the encoder", MOVE on
// ==== Clock100ms rising edge) and 12 ("Speed calculation", Clock100ms falling edge) by ONE
// ==== ST rung with this code (no contact in front). Comment: "V9: speed over exactly 100 ms".
// Old: window = time between the rising and falling edge of Clock100ms, assumed 50 ms,
// but with the 4 ms PrimaryTask it is 12 or 13 scans (48 / 52 ms) -> the speed jumps
// -4 % / +4 % (418 set: display 397 / 431).
// New: exactly 25 scans = 100 ms (same as AutoStop SpdAct_Pps), updated 10 times/s.
SpdScanCnt := SpdScanCnt + 1;

IF SpdScanCnt >= 25 THEN
    SpdScanCnt := 0;
    DeltaPulse := Encoder_Pos - MemPos;
    MemPos := Encoder_Pos;

    IF ABS(DeltaPulse) > 100000 THEN                 // counter reset (Encoder_Reset)
        DeltaPulse := 0;
    END_IF;
    Velocity := DINT_TO_REAL(DeltaPulse) * EncoderPulse_to_mm * REAL#10;   // mm/s
    Velocity_M_min := Velocity / Mt_To_mm;
END_IF;

// Rung 12 "Set the initial speed"   NOT StartMotor_Cmd OR P_First_RunMode -> ST:
Vfd_SP_Modif := Vel_Max_mms;
InvRef := INT#0;
RangeOK := FALSE;

// Rung 13 "Acceleration/deceleration factor selection (1 = 250 mm/s2)"
//   StartMotor_Cmd AND (UnderSpeed OR OverSpeed): MOVE DecelCoarse -> Decel_Ramp,
//       MOVE AccelCoarse -> Accel_Ramp, (R) RangeOK
//   StartMotor_Cmd AND NOT UnderSpeed AND NOT OverSpeed AND RangeOK:
//       MOVE DecelTrim -> Decel_Ramp, MOVE AccelTrim -> Accel_Ramp

// Rung 14 "Ratio drive counts per m/min" (ST, V10 rung A)
// ==== V10: REPLACE the code of Motor_Manager rung 14 (printed V9) ("Ratio drive counts per m/min of web
// ==== at the current rewinder diameter." = V7 rung A) with this file. (V7b jog line inside.)
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
// V7b: never in jog -> jog keeps the rung 13 ramps exactly as v6y. V10: JogRun (jog really running).

IF NOT FFEnable AND NOT JogRun AND StartMotor_Cmd AND (UnderSpeed OR OverSpeed)
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

// Rung 15 "Soft Stop - SoftStopDecel" (ST)

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
        Decel_Ramp := SoftStopDecel / 250.0;    // fallback (old v6m behaviour)
    END_IF;

    IF Decel_Ramp > 8.0 THEN
        Decel_Ramp := 8.0;                      // max 9 Hz/s asked from the PLC
    END_IF;
END_IF;

// Rung 16 "Speed correction factor calculation" (old integrating loop, ladder)
//   NOT ManMode AND ControlVoltage AND StartMotor_Cmd:
//     (Velocity > VelSet_mms) AND (InvRef > 0)                   -> Vfd_SP_Modif := Vfd_SP_Modif + Decel_Ramp ; (S) RangeOK
//     (Clock1s OR NOT RangeOK) AND (Velocity < VelSet_mms) AND (Vfd_SP_Modif > 0)
//                                                                -> Vfd_SP_Modif := Vfd_SP_Modif - Accel_Ramp
//   (overwritten by rung 17 when FFActive)

// Rung 17 "Slow adaptation of RwRatioD" = feed-forward (ST, V12 rung B + tension hold)
// ==== V12: REPLACE the code of Motor_Manager rung 17 (printed V9) ("Slow adaptation of RwRatioD on the
// ==== relative speed error." = V7 rung B) with this file. (V7a + V7b + V7f + V9 + V10 + V12 inside.)
// The PLC sends the drive STRAIGHT to the frequency of the set speed
// (VelSet x WebRatio), along a ramp in REAL web mm/s2 that does not depend on the
// measured speed -> no hunting, whatever the roll inertia / web delay.
// The measured speed only adapts RwRatioD slowly (~10 s), once at target.
// It overwrites Vfd_SP_Modif after rung 16, so rung 16 has no effect in AUTO.
// FFEnable = FALSE -> old loop (rung 16) exactly as before.
// V7b: not in jog (V10: JogRun = jog really running): at 10 m/min the feed-forward gives
// only ~0.4 Hz, too little to move the web -> the old loop (rung 16) runs the jog.
FFActive := FFEnable AND NOT ManMode AND NOT JogRun AND StartMotor_Cmd
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

    // Tension: hold at a minimum DRIVE FREQUENCY until the T-one reports tension
    // (independent of the rewinder diameter). TensWaitHz = 0 -> old m/min hold.

    IF TensWait THEN

        IF TensWaitHz > REAL#0.0 THEN
            TensRef := TensWaitHz * REAL#4000.0 / REAL#60.0 * Output_Ratio;
        ELSE
            TensRef := TensWaitSpd * WebRatio * Output_Ratio;
        END_IF;

        IF FFTarget > TensRef THEN
            FFTarget := TensRef;
        END_IF;
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

    IF SoftStop AND FinalStopRamp AND (FinalStopDecel > 0.0) THEN
        StepDec := FinalStopDecel * 0.06 * WebRatio * Vel_Max_mms / 1000000.0;   // V12 end-of-roll
    ELSIF SoftStop AND (SoftStopDecel > 0.0) THEN
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
       AND NOT SpdHold AND NOT FFSlowAcc AND NOT TensWait THEN            // V9: not during the hold

        IF FFSteadyTicks < 30000 THEN
            FFSteadyTicks := FFSteadyTicks + 1;
        END_IF;
    ELSE
        FFSteadyTicks := 0;
    END_IF;

    // Slow adaptation of RwRatioD on the relative speed error (2 s after the
    // target is reached, not at the 60 Hz limit, not during soft stop / jog)

    IF (FFSteadyTicks >= 500) AND NOT SoftStop AND NOT JogRun
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

// Rung 18 "Inverter speed reference"   NOT ManMode AND ControlVoltage AND StartMotor_Cmd -> ST:
InvRef := REAL_TO_INT((Vel_Max_mms - Vfd_SP_Modif ) / Output_Ratio);

// Rung 19 "Updating potentiometer value (ManMode)"   ManMode AND NOT I_Jog_PB -> ST:

IF SoftStop THEN
    InvRef := INT#0;                          // v6m: drive ramps down on its own
ELSIF SlowDown = FALSE THEN
    InvRef := Pot1_Work_Velocity;
ELSE
    InvRef := Pot2_Slow_Velocity;
END_IF;

// Rung 20 "Slow speed (ManMode)"   ManMode AND JogRun -> ST:
VelSet := JogSpd_SP;
VelSet_mms := VelSet * Mt_To_mm;
InvRef := REAL_TO_INT(VelSet_mms / Output_Ratio);
