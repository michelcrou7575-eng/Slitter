(* =====================================================================
   SECTION: Alarms  (V12_1110_6)
   A = alarm, W = warning (CASE in rung 0)
   ===================================================================== *)
// Rung 0 "Check present alarms" (ST)
// Alarms: buzzer pulses (Clock1s). ALARM RESET (panel or HMI) silences it 1 min;
//         a NEW alarm during the silence sounds again at once.
// Warnings: ONE 1 s beep each time a new warning appears.
// PrimaryTask 4 ms: 250 scans = 1 s, 15000 scans = 60 s.
AlarmOn := FALSE;
WarningOn := FALSE;
AlarmCnt := 0;
WarnCnt := 0;
FOR Index_A := 0 TO 32 DO

    IF Alarm_Array[Index_A] THEN
        CASE Index_A OF
            5, 13, 15, 16, 17, 18, 19, 20, 21:      // warnings
                WarningOn := TRUE;
                WarnCnt := WarnCnt + 1;

                IF NOT AlarmMem[Index_A] THEN
                    WarnBeepTicks := 250;           // NEW warning -> 1 s beep
                END_IF;
        ELSE                                        // alarms
            AlarmOn := TRUE;
            AlarmCnt := AlarmCnt + 1;
        END_CASE;
    END_IF;
    AlarmMem[Index_A] := Alarm_Array[Index_A];
END_FOR;
// ALARM RESET button (panel I_RsetAlarm or HMI Alarm_Reset): silence 1 min
RstEdge := (I_RsetAlarm OR Alarm_Reset) AND NOT RstMem;
RstMem := I_RsetAlarm OR Alarm_Reset;

IF RstEdge AND AlarmOn THEN
    SilenceTicks := 15000;
END_IF;

IF (AlarmCnt > AlarmCntMem) OR NOT AlarmOn THEN
    SilenceTicks := 0;                              // new alarm / no alarm: not silenced
END_IF;

IF SilenceTicks > 0 THEN
    SilenceTicks := SilenceTicks - 1;
END_IF;

IF WarnBeepTicks > 0 THEN
    WarnBeepTicks := WarnBeepTicks - 1;
END_IF;
AlarmCntMem := AlarmCnt;
WarnCntMem := WarnCnt;
AlarmSilenced := AlarmOn AND (SilenceTicks > 0);
BuzzerOn := ControlVoltage
            AND ((AlarmOn AND NOT AlarmSilenced AND Clock1s) OR (WarnBeepTicks > 0));

// Rung 1 (ST): sonar fault (alarm 14) + thickness not learned (warning 17)
T_UwSensFlt(In := (AI_Diam_Unwinder < UwRawMin) OR (AI_Diam_Unwinder > UwRawMax), PT := T#1s);
UwSensTest := T_UwSensFlt.Q;

IF ControlVoltage AND Measure_ON AND UwSensTest AND (UwStopEnable OR StartMotor_Cmd) THEN
    UwSensFault := TRUE;
ELSIF NOT UwSensTest AND (I_RsetAlarm OR Alarm_Reset) THEN
    UwSensFault := FALSE;
END_IF;
Thickness_Fault := ControlVoltage AND StartMotor_Cmd
                   AND (RwMat_K <= 0.0) AND (RwDiam > 300.0);

// Ladder rungs (equations). "latch" = OR Alarm_Array[n] AND NOT I_RsetAlarm AND NOT Alarm_Reset
// 2  [1]  A  ControlVoltage AND (NOT I_FanTemp_Ok OR latch)                      Motor fan thermal
// 3  [2]  A  ControlVoltage AND (NOT I_VFD_Alarm OR latch)                       Inverter fault
// 4  [3]  A  NOT ControlVoltage                                                  Emergency stop
// 5  [4]  A  ControlVoltage AND (NOT I_Motor_Thermal OR latch)                   Motor thermal
// 6  [5]  W  NOT I_FrontGuard_Closed AND NOT I_FrontGuard_Open                   Front guard moving
// 7  [6]  A  ControlVoltage AND ((StartMotor_Cmd AND NOT I_Jog_PB) OR latch OR I_Start_PB)
//              AND I_WebBreak_Monitor AND I_WebBreak_PH                          Web break / no paper
// 8  [7]  A  ControlVoltage AND NOT I_Vacuum_OK                                  Extractor fan thermal
// 9  [8]  A  ControlVoltage AND StartMotor_Cmd AND NOT ManMode AND (InvRef > 200)
//              AND (Velocity = 0) -> T_EncoderStill (TON 3 s)                    Encoder off
// 10 [9]  A  ControlVoltage AND I_Hub_Position AND NOT StartMotor_Cmd AND NOT I_Prot_ByPass
//              AND I_FrontGuard_Open                                             Hub not in position
// 11 [10] A  ControlVoltage AND RwSensFault AND (RwStopEnable OR StartMotor_Cmd) -> (S)  DT35 fault
// 12 [10]    NOT RwSensFault AND (I_RsetAlarm OR Alarm_Reset)                    -> (R)
// 13 [11] A  ControlVoltage AND RwMaxStop                                        -> (S)  Rewinder max diam
// 14 [11]    (I_RsetAlarm OR Alarm_Reset) AND NOT RwMaxStop                      -> (R)
// 15 [12] A  ControlVoltage AND I_Stop_PB -> T_PulStop (TON 2 s)                 E-stop by holding STOP
// 16 [13] W  ControlVoltage AND TensLostWarn                                     Web tension low / slack
// 17 [14] A  ControlVoltage AND UwSensFault                                      Unwinder sonar fault
// 18 [15] W  ControlVoltage AND Measure_ON AND UnWinder_Empty                    -> (S)  Unwinder empty
// 19 [15]    (I_RsetAlarm OR Alarm_Reset) AND NOT UnWinder_Empty                 -> (R)
// 20 [16] W  ControlVoltage AND GSM_LearnFault                                   -> (S)  GSM learning fault
// 21 [16]    (I_RsetAlarm OR Alarm_Reset) AND NOT GSM_LearnFault                 -> (R)
// 22 [17] W  ControlVoltage AND Thickness_Fault AND NOT Alarm_Array[16]          Thickness not learned
// 23 [18] W  ControlVoltage AND NOT I_Side_Door_Closed AND (I_Start_PB OR I_Jog_PB OR StartMotor_Cmd)
//              AND NOT I_Prot_ByPass                                             -> (S)  Side door opened
// 24 [18]    I_Side_Door_Closed AND (I_RsetAlarm OR Alarm_Reset)                 -> (R)
// 25 [19] W  NOT I_FrontGuard_Closed AND I_Start_PB AND NOT I_Prot_ByPass        -> (S)  Front gate not closed
// 26 [19]    I_RsetAlarm OR Alarm_Reset                                          -> (R)
// 27 [20] W  ControlVoltage AND AutoStopDone                                     AutoStop done
// 28 [21] W  AutoEnRefused                                                       AutoStop refused (HMI LW-200)
// 29  HMI display: ControlVoltage AND AlarmStrobe -> T_Display (TON 2 s) -> (R) AlarmStrobe;
//                  ControlVoltage AND FALLING(Alarm_Array[Index_B]) -> (R) AlarmStrobe
// 30  Alarm_Array[Index_B] AND NOT T_Display.Q -> (S) AlarmStrobe, MOVE Index_B -> Msg
// 31  NOT AlarmStrobe AND (Index_B < 33) -> Inc(Index_B)
// 32  (Index_B = 33) OR P_First_RunMode -> MOVE 0 -> Index_B
// 33  NOT AlarmOn AND NOT WarningOn -> MOVE 33 -> Msg
// OPEN: rung 29 - remove ControlVoltage so messages cycle during an E-stop.
