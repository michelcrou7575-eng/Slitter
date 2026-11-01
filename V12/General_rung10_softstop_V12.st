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

IF SoftStop AND I_Start_PB AND NOT FinalStopRamp THEN
    SoftStop := FALSE;                              // START cancels the soft stop
END_IF;

T_SoftStop(In := SoftStop, PT := T#120s);

IF SoftStop AND ((Velocity_M_min <= SoftStopEndSpd) OR T_SoftStop.Q) THEN
    StopNow := TRUE;                                // almost stopped (or timeout)
END_IF;
