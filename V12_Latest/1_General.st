(* =====================================================================
   SECTION: General  (V12_1110_6)  - ladder rungs written as equations,
   ST rungs verbatim.  Notation:  A AND NOT B -> ( C )  = coil,  (S)/(R) = set/reset
   ===================================================================== *)

// Rung 0  "1 s clock"            Get1sClk   -> ( Clock1s )
// Rung 1  "100 ms clock"         Get100msClk -> ( Clock_100ms )
// Rung 2  "10 ms clock"          Get10msClk -> ( Clock10ms )
// Rung 3  "Initializing ramp values"   NOT Init_Ramp -> ST:
SpdDelta_Percent := REAL#8;
AccelTrim := REAL#0.08;
DecelTrim := REAL#0.08;
AccelCoarse := REAL#1;
DecelCoarse := REAL#0.5;
Init_Ramp := TRUE;

// Rung 4  "Set analog scale resolution" (ST)

IF Analog_Res = INT#0 THEN
    Analog_Res := INT#4000;
END_IF;

// Rung 5  "m/min <-> mm/s" (ST)
Mt_To_mm := REAL#1000 / REAL#60;
Sec_to_Min := REAL#100 * REAL#60;

// Rung 6  "10 V DC source" (name kept; Fix10Vdc removed, AO Ch1 written by Tension_Manager)
//   T_PlcOn (TON 100 ms, In = TRUE);   T_PlcOn.Q AND I_ControlVoltage -> ( ControlVoltage )

// Rung 7  "START blocked by JOG" (ST)
T_JogStartBlk(In := I_Jog_PB, PT := T#2s);       // TOF: ON while held + 2 s
StartHeldBlk := (StartHeldBlk OR (I_Start_PB AND T_JogStartBlk.Q)) AND I_Start_PB;
StartPB_OK := I_Start_PB AND NOT T_JogStartBlk.Q AND NOT StartHeldBlk;

// Side door open (no key bypass): no JOG, and stop any JOG / run in progress
SideDoorOpen := NOT I_Side_Door_Closed AND NOT I_Prot_ByPass;

JogRun := I_Jog_PB AND NOT Slow_Inhibit AND NOT SoftStop AND NOT SideDoorOpen;

GuardStopOK := NOT StartMotor_Cmd;

// START refused: no paper (monitoring ON), front gate or side door open (no key bypass)
// JOG: allowed with the front gate open (guard bypass), NOT with the side door open
WebBreakNow := I_WebBreak_Monitor AND I_WebBreak_PH;
GuardOpen   := (NOT I_FrontGuard_Closed OR NOT I_Side_Door_Closed) AND NOT I_Prot_ByPass;
StartBlocked := WebBreakNow OR GuardOpen;

// Rung 8  "T-one Alarm 0: tension established" (ST)
T_TensOn(In := I_T_one_TensionOK, PT := T#500ms);        // stable 0.5 s
T_TensOff(In := NOT I_T_one_TensionOK, PT := T#2s);      // ignore short dips

IF T_TensOn.Q OR NOT TensCheckEnable THEN
    TensionOK := TRUE;
ELSIF T_TensOff.Q THEN
    TensionOK := FALSE;
END_IF;

IF NOT StartMotor_Cmd THEN
    TensionSeen := FALSE;
ELSIF TensionOK THEN
    TensionSeen := TRUE;
END_IF;
TensWait := StartMotor_Cmd AND NOT TensionSeen AND NOT JogRun;
TensLostWarn := StartMotor_Cmd AND TensionSeen AND NOT TensionOK;

// Rung 9  "Slow Inhibit"
//   ControlVoltage AND ((StartPB_OK AND NOT StartBlocked) OR Slow_Inhibit)
//     AND NOT I_Stop_PB AND NOT Stop                                   -> ( Slow_Inhibit )

// Rung 10 "Main Motor start"
//   [1] ControlVoltage AND NOT I_Stop_PB AND StartPB_OK AND NOT StartBlocked
//   [2] ControlVoltage AND NOT I_Stop_PB AND I_Jog_PB AND NOT Slow_Inhibit AND NOT I_Start_PB
//         AND NOT JogInhibit AND NOT SideDoorOpen -> T_StartLow (TON 100 ms) -> Up (rising edge)
//   ([1] OR [2]) AND NOT Stop AND I_Motor_Thermal AND I_FanTemp_Ok  -> (S) StartMotor_Cmd

// Rung 11 "Soft Stop Process" (ST)
// ==== V12: REPLACE the code of General rung 10 ("Soft Stop Process", printed V9).
// v6m: STOP button = soft stop. StopNow replaces I_Stop_PB in rung 9.
// V12: an end-of-roll stop (FinalStopRamp, AutoStop section 11b) also starts the
// soft stop, at FinalStopDecel (Motor_Manager rung 17); START cannot cancel it.

StopNow := FALSE;
T_StopLong(In := I_Stop_PB, PT := T#1s);

IF NOT StartMotor_Cmd THEN
    SoftStop := FALSE;
ELSIF I_Stop_PB AND NOT StopPB_Mem THEN             // STOP pressed (edge)

    IF SoftStop OR NOT SoftStopEnable OR I_Jog_PB
       OR (Velocity_M_min <= SoftStopEndSpd) THEN
        StopNow := TRUE;                            // 2nd press / jog / slow / disabled
    ELSE
        SoftStop := TRUE;                           // start soft stop
    END_IF;
END_IF;

StopPB_Mem := I_Stop_PB;

IF T_StopLong.Q THEN
    StopNow := TRUE;                                // held 1 s = immediate
END_IF;

// V12: end-of-roll stop ramp (FinalStopRamp set by AutoStop section 11b)

IF FinalStopRamp AND StartMotor_Cmd AND NOT SoftStop THEN
    SoftStop := TRUE;
END_IF;

// Side door opened while running (not JOG): soft stop, START cannot cancel it

IF SideDoorOpen AND StartMotor_Cmd AND NOT I_Jog_PB AND NOT SoftStop THEN
    SoftStop := TRUE;
END_IF;

IF SoftStop AND I_Start_PB AND NOT FinalStopRamp AND NOT SideDoorOpen THEN
    SoftStop := FALSE;                              // START cancels the soft stop
END_IF;

T_SoftStop(In := SoftStop, PT := T#120s);

IF SoftStop AND ((Velocity_M_min <= SoftStopEndSpd) OR T_SoftStop.Q) THEN
    StopNow := TRUE;                                // almost stopped (or timeout)
END_IF;

// Rung 12 "Main Motor stop"   any of:
//   NOT ControlVoltage
//   StopNow
//   FALLING(I_Jog_PB) AND NOT Slow_Inhibit AND NOT StartPB_OK
//   Stop
//   SideDoorOpen AND I_Jog_PB
//   NOT I_Motor_Thermal
//   NOT I_FanTemp_Ok                                                   -> (R) StartMotor_Cmd

// Rung 13 "Hub extraction clearance"
//   NOT I_Hub_Position AND NOT StartMotor_Cmd AND NOT I_FrontGuard_Closed -> ( HubExtractEnable )
// Rung 14 "Brake control"      NOT I_Start_PB AND StartMotor_Cmd        -> ( Brake_Cmd )
// Rung 15 "Cooling Fan control" StartMotor_Cmd -> T_StopVent (TOF, TimStopVen) -> ( MotorCooling )

// Rung 16 "UnWinder Diameter - Input" (ST)
In_UwDiameter := INT_TO_REAL(AI_Diam_Unwinder)/REAL#1;

// Rung 17 "UnWinder Diameter - Actual"
//   T_PlcOn.Q -> ScaleTrans(SclIn In_UwDiameter, X0 0, Y0 DeadZone, X1 4000, Y1 Reading_Max, SclOfs 0)
//                -> UwDiam_Measure ; ENO -> ST:
// P+F UC2000-L2-U-V15: DeadZone 60 mm, Reading_Max 2000 mm
// P+F OMD10M-R200-2EP-IO-V1-L: DeadZone 200 mm, Reading_Max 5000 mm
UwDiam_Act := ((UwCoreDistance - UwDiam_Measure) * REAL#2) + UwCoreDiameter;

// Rung 18 "UnWinder Slow By Diameter Compare"
//   I_ControlVoltage AND Measure_ON AND (UwDiam_Act <= UwSlowDiamAct)     -> ( SlowByDiam )
// Rung 19 "UnWinder Stop By Diameter Compare"
//   I_ControlVoltage AND Measure_ON AND (UwDiam_Act <= UwStop_at_D_Val)   -> ( UwStopByDiam )
