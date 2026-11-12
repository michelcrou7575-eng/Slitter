(* =====================================================================
   SECTION: Console  (V12_1110_6)
   ===================================================================== *)
// Rung 0 "Variables of type TIME" (ST)
TimStopVen := NanoSecToTime(REAL_TO_LINT(Fan_Timeout * REAL#60000000000));
TimPosPresOn := NanoSecToTime(REAL_TO_LINT(OverRider_TimeON * REAL#1000000000));
TimPosPresOff := NanoSecToTime(REAL_TO_LINT(OverRider_TimeOFF * REAL#1000000000));

// Rung 1 "Convert the pulses into mm and m" (ST)
Current_mm := DINT_TO_REAL(Encoder_Pos) * EncoderPulse_to_mm;
Current_Metre := Current_mm / REAL#1000;

// Rung 2 "Motor Stop"      NOT StartMotor_Cmd -> ( MotStop )
// Rung 3 "Request to reset the meter counter"
//   I_AutoStop_OS AND UwStopEnable AND (Current_Metre >= UwStop_at_M_Val) -> ( CountReset_Req )
// Rung 4 "Password check"  (P_On)
//   Psw = 22 -> ( Psw22 ), rising: HMI_Screen[0] := 22
//   Psw = 33 -> ( Psw33 ), rising: HMI_Screen[0] := 33
//   Psw = 40 -> ( Psw40 ), rising: HMI_Screen[0] := 40
//   Psw = 44 -> ( Psw44 ), rising: HMI_Screen[0] := 44
//   Psw = 48 -> ( Psw48 ), rising: HMI_Screen[0] := 48
//   Psw not 22/33/40/44/48 and Psw <> 0, rising: Psw := 0, HMI_Screen[0] := 10
// Rung 5 "Password Reset"
//   P_First_RunMode OR T_Screen_Delay.Q (TON 1 ms, In = HMI_Screen[0] = 10) -> Psw := 0
// Rung 6 "HMI coding"  (P_On)
//   MOVE Alarm_Array -> AlarmCodeSV
//   I_Prot_ByPass        -> ( SafeGuard_ByPass )
//   I_FrontGuard_Closed  -> ( FrontGuard_Closed )
