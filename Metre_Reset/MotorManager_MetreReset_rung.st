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
