(* ==========================================================================
   AutoStop_Control  V9   -  PART 2 of 2 (rung 1): sections 6 - 14c
   (Sysmac: an inline ST rung holds max 1000 rows -> split in 2 rungs.
    Rung 0 = part 1 runs first, then this rung, every scan.)
   ========================================================================== *)

(* ---- 6. Lengths in pulses: stop, slow-down, remaining ------------------ *)
(* Stop length uses the ACTUAL speed (precision)                           *)
IF RwStopDecel > 0.0 THEN
    StopLen_Pls := SpdAct_Pps * RwTreact
                   + (SpdAct_Pps * SpdAct_Pps) / (2.0 * RwStopDecel);
ELSE
    StopLen_Pls := SpdAct_Pps * (RwTreact + RwTstopDef / 2.0);
END_IF;
StopLen_Pls := StopLen_Pls * RwTrim;

(* Slow-down uses SpdRef = MAX(actual, work-speed setpoint):               *)
(* stable value, shown to the operator even before start                   *)
SlowLenBase_Pls := 0.0;  RwSlowLen_Pls := 0.0;  UwSlowLen_Pls := 0.0;
IF MmPerPulse > 0.0 THEN
    (* v6f: manual > learned > PLC ramp model                           *)
    (* V7: manual > feed-forward (one ramp at DecelWeb, real web mm/s2)  *)
    (*     > old loop with web ramps (coarse DecelWeb + trim tail)       *)
    (*     > learned > old PLC ramp model                                *)
    IF RwSlowDecel > 0.0 THEN
        SlowDecel_Pps2 := RwSlowDecel / MmPerPulse;
        SlowOneRamp := TRUE;
    ELSIF FFEnable AND (DecelWeb > 0.0) AND (WebRatio > 0.0) AND NOT ManMode THEN
        SlowDecel_Pps2 := DecelWeb / MmPerPulse;
        SlowOneRamp := TRUE;
    ELSIF (DecelWeb > 0.0) AND (WebRatio > 0.0) AND NOT ManMode THEN  (* V7e *)
        SlowDecel_Pps2 := DecelWeb / MmPerPulse;
        SlowOneRamp := FALSE;
    ELSIF RwSlowDecelLrn > 0.0 THEN
        SlowDecel_Pps2 := RwSlowDecelLrn / MmPerPulse;  (* real, incl. trim tail *)
        SlowOneRamp := TRUE;
    ELSE
        SlowDecel_Pps2 := DecelCoarse * 250.0 / MmPerPulse; (* 1 = 250 mm/s2 *)
        SlowOneRamp := FALSE;
    END_IF;
    (* v6d: DecelTrim ramp used inside the +/- SpdDelta_Percent band *)
    IF (DecelTrim > 0.0) AND (WebRatio > 0.0) AND (Vel_Max_mms > 0.0) THEN
        (* V7: trim ramp (reference units) converted to the real web decel *)
        TrimDecel_Pps2 := DecelTrim * 1000000.0 / (0.06 * WebRatio * Vel_Max_mms)
                          / MmPerPulse;
    ELSIF DecelTrim > 0.0 THEN
        TrimDecel_Pps2 := DecelTrim * 250.0 / MmPerPulse;
    ELSE
        TrimDecel_Pps2 := SlowDecel_Pps2;
    END_IF;
    SpdBand_Pps := SpdDelta_Percent * 1000.0 / 60.0 / MmPerPulse;

    (* v6d: speeds from the potentiometers, valid in auto AND ManMode     *)
    (*      (m/min = Pot / Input_Ratio, same as Motor_Manager rung 8)     *)
    IF (Input_Ratio > 0.0) AND ManMode THEN
        (* v6i: ManMode drives the inverter with the raw pots (rung 17) *)
        SpdFinal_Pps := INT_TO_REAL(Pot2_Slow_Velocity) / Input_Ratio * 1000.0 / 60.0 / MmPerPulse;
        SpdWork_Pps  := INT_TO_REAL(Pot1_Work_Velocity) / Input_Ratio * 1000.0 / 60.0 / MmPerPulse;
    ELSIF Input_Ratio > 0.0 THEN
        SpdFinal_Pps := INT_TO_REAL(Pot2_Mem) / Input_Ratio * 1000.0 / 60.0 / MmPerPulse;
        SpdWork_Pps  := INT_TO_REAL(Pot1_Mem) / Input_Ratio * 1000.0 / 60.0 / MmPerPulse;
    ELSE
        SpdFinal_Pps := LowSpd_Display * 1000.0 / 60.0 / MmPerPulse;
        SpdWork_Pps  := Speed_Display  * 1000.0 / 60.0 / MmPerPulse;
    END_IF;
    (* v6y: rewinder AUTO stop -> work speed limited to RwAutoMaxSpdAct *)
    (* (limit + value taken over only at standstill, Motor_Manager rung 5) *)
    IF RwAutoLimAct AND NOT ManMode
       AND (SpdWork_Pps > RwAutoMaxSpdAct * 1000.0 / 60.0 / MmPerPulse) THEN
        SpdWork_Pps := RwAutoMaxSpdAct * 1000.0 / 60.0 / MmPerPulse;
    END_IF;
    SpdRef_Pps := MAX(SpdAct_Pps, SpdWork_Pps);

    IF RwStopDecel > 0.0 THEN
        StopLenFinal_Pls := SpdFinal_Pps * RwTreact
                            + (SpdFinal_Pps * SpdFinal_Pps) / (2.0 * RwStopDecel);
    ELSE
        StopLenFinal_Pls := SpdFinal_Pps * (RwTreact + RwTstopDef / 2.0);
    END_IF;

    SlowLenBase_Pls := StopLenFinal_Pls * RwTrim;
    IF (SpdRef_Pps > SpdFinal_Pps) AND (SlowDecel_Pps2 > 0.0) THEN
        IF SlowOneRamp OR (TrimDecel_Pps2 <= 0.0) THEN
            (* manual or learned decel: one constant ramp *)
            SlowLenBase_Pls := SlowLenBase_Pls
                + (SpdRef_Pps * SpdRef_Pps - SpdFinal_Pps * SpdFinal_Pps)
                  / (2.0 * SlowDecel_Pps2);
        ELSE
            (* auto: coarse ramp down to the band, trim ramp inside it *)
            SpdKnee_Pps := SpdFinal_Pps + SpdBand_Pps;
            IF SpdRef_Pps > SpdKnee_Pps THEN
                SlowLenBase_Pls := SlowLenBase_Pls
                    + (SpdRef_Pps * SpdRef_Pps - SpdKnee_Pps * SpdKnee_Pps)
                      / (2.0 * SlowDecel_Pps2)
                    + (SpdKnee_Pps * SpdKnee_Pps - SpdFinal_Pps * SpdFinal_Pps)
                      / (2.0 * TrimDecel_Pps2);
            ELSE
                SlowLenBase_Pls := SlowLenBase_Pls
                    + (SpdRef_Pps * SpdRef_Pps - SpdFinal_Pps * SpdFinal_Pps)
                      / (2.0 * TrimDecel_Pps2);
            END_IF;
        END_IF;
    END_IF;

    (* V7f: S-curve rounding: the slow-down ends SCurveTime later ->      *)
    (*      extra length = (SpdRef - SpdFinal) / 2 x SCurveTime            *)
    IF FFEnable AND NOT ManMode AND (RwSlowDecel <= 0.0) AND (DecelWeb > 0.0)
       AND (WebRatio > 0.0) AND (SCurveTime > 0.0)
       AND (SpdRef_Pps > SpdFinal_Pps) THEN
        SlowLenBase_Pls := SlowLenBase_Pls
                           + (SpdRef_Pps - SpdFinal_Pps) * 0.5 * SCurveTime;
    END_IF;

    RwSlowLen_Pls := SlowLenBase_Pls + RwSlowMargin_m * 1000.0 / MmPerPulse;

    IF UwSlowMargin_m > 0.0 THEN
        UwMarginUsed_m := UwSlowMargin_m;
    ELSE
        UwMarginUsed_m := RwSlowMargin_m;
    END_IF;
    UwSlowLen_Pls := SlowLenBase_Pls + UwMarginUsed_m * 1000.0 / MmPerPulse;
END_IF;

IF RwDiam >= RwTargetDiam THEN
    RwRemain_Pls := 0.0;
ELSIF RwMat_K > 0.0 THEN
    RwRemain_Pls := (RwTargetDiam * RwTargetDiam - RwDiam * RwDiam)
                    / (2.0 * RwMat_K);
ELSE
    RwRemain_Pls := 1.0E9;                          (* K not learned: plain target *)
END_IF;

RwRemain_m  := RwRemain_Pls  * MmPerPulse / 1000.0;
RwStopLen_m := StopLen_Pls   * MmPerPulse / 1000.0;
RwSlowLen_m := RwSlowLen_Pls * MmPerPulse / 1000.0;

(* ---- 6b. Live operator displays ---------------------------------------- *)
(* Rewinder: diameter where slow-down / stop command will happen           *)
IF RwMat_K > 0.0 THEN
    SqrtArg := RwTargetDiam * RwTargetDiam - 2.0 * RwMat_K * RwSlowLen_Pls;
    IF SqrtArg > 0.0 THEN
        RwSlowAtDiam := SQRT(SqrtArg);
    ELSE
        RwSlowAtDiam := 0.0;
    END_IF;
    SqrtArg := RwTargetDiam * RwTargetDiam - 2.0 * RwMat_K * StopLen_Pls;
    IF SqrtArg > 0.0 THEN
        RwStopAtDiam := SQRT(SqrtArg);
    ELSE
        RwStopAtDiam := 0.0;
    END_IF;
ELSE
    (* v6t: thickness not learned: fixed slow-down point before the target *)
    IF RwUseSlow AND (RwSlowFallbackMm > 0.0) THEN
        RwSlowAtDiam := RwTargetDiam - RwSlowFallbackMm;
    ELSE
        RwSlowAtDiam := RwTargetDiam;
    END_IF;
    RwStopAtDiam := RwTargetDiam;
END_IF;

(* Unwinder: meter count where the slow-down will start                   *)
IF MmPerPulse > 0.0 THEN
    UwSlow_at_Metre := UwStop_At_Meter - UwSlowLen_Pls * MmPerPulse / 1000.0;
ELSE
    UwSlow_at_Metre := UwStop_At_Meter;
END_IF;
IF UwSlow_at_Metre < 0.0 THEN
    UwSlow_at_Metre := 0.0;
END_IF;

(* Unwinder slow-down request, latched                                     *)
IF (Current_Metre < UwSlow_at_Metre - 50.0) OR (UwStop_At_Meter <= 0.0) THEN
    UwSlowReq := FALSE;                             (* counter reset / longer roll *)
END_IF;
IF (UwStop_At_Meter > 0.0) AND (Current_Metre >= UwSlow_at_Metre) THEN
    UwSlowReq := TRUE;
END_IF;

(* ==== "Unwinder slow-down request, latched" (the 2 IF ... UwSlowReq).      *)
(* ---- 6c. V7c: unwinder DIAMETER slow-down follows the speed ----------- *)
(* Works without AutoStop (only Measure_ON, like General rung 16).         *)
(* Paper left above the stop diameter, in pulses:                          *)
(*     (UwDiam_Act^2 - UwDiamStop^2) / (2 x RwMat_K)                        *)
(* (same paper as the rewinder -> same learned K). Slow down when it is    *)
(* shorter than UwSlowLen_Pls = decel from the speed (DecelWeb) + final    *)
(* stop + UwSlowMargin_m. Solved for the diameter:                         *)
(*     UwSlowDiamCalc = SQRT(UwDiamStop^2 + 2 x RwMat_K x UwSlowLen_Pls)    *)
(* K not learned / UwSlowDiamAuto OFF -> fixed UwSlowDown_Diam as before.  *)
(* Latched: once slowed down, the point is frozen (+10 mm hysteresis), so  *)
(* the lower speed does not move it back and speed up again. Released by   *)
(* a new roll (diameter 30 mm above the frozen point).                     *)
IF UwSlowDiamAuto AND (RwMat_K > 0.0) AND (UwDiamStop > 0.0)
   AND (UwSlowLen_Pls > 0.0) THEN
    UwSlowDiamCalc := SQRT(UwDiamStop * UwDiamStop
                           + REAL#2.0 * RwMat_K * UwSlowLen_Pls);
ELSE
    UwSlowDiamCalc := UwSlowDown_Diam;
END_IF;
IF UwSlowDiamCalc < UwDiamStop + 10.0 THEN
    UwSlowDiamCalc := UwDiamStop + 10.0;
ELSIF UwSlowDiamCalc > 1500.0 THEN
    UwSlowDiamCalc := 1500.0;
END_IF;

IF UwSlowDiamLatch AND (UwDiam_Act > UwSlowDiamAct + 30.0) THEN
    UwSlowDiamLatch := FALSE;                       (* new roll *)
END_IF;
IF NOT UwSlowDiamLatch THEN
    UwSlowDiamAct := UwSlowDiamCalc;                (* live point, HMI *)
    IF Measure_ON AND (UwDiam_Act > 0.0) AND (UwDiam_Act <= UwSlowDiamCalc) THEN
        UwSlowDiamLatch := TRUE;
        UwSlowDiamAct := UwSlowDiamCalc + 10.0;     (* frozen + hysteresis *)
    END_IF;
END_IF;

(* ---- 7. Rewinder requests: latched, reset when a new core is loaded ---- *)
IF NOT RwStopEnable
   OR ((RwDiam < RwTargetDiam - RwResetHyst) AND NOT RwSensFault) THEN
    RwStopReq := FALSE;
    RwSlowReq := FALSE;
END_IF;

IF RwStopEnable THEN
    IF (RwRemain_Pls <= StopLen_Pls) OR (RwSensFault AND RwStopOnFault) THEN
        RwStopReq := TRUE;
    END_IF;
    IF RwUseSlow AND (RwRemain_Pls <= RwSlowLen_Pls) THEN
        RwSlowReq := TRUE;
    END_IF;
    (* v6t: thickness not learned (RwMat_K = 0): slow down at a fixed      *)
    (* distance before the target instead of stopping from full speed.    *)
    IF RwUseSlow AND (RwMat_K <= 0.0) AND (RwSlowFallbackMm > 0.0)
       AND NOT RwSensFault
       AND (RwDiam >= RwTargetDiam - RwSlowFallbackMm) THEN
        RwSlowReq := TRUE;
    END_IF;
END_IF;

(* ---- 8. One AUTO at a time + single "SLOW DOWN AT" display ------------- *)
IF UwStopEnable AND NOT UwEnMem THEN                (* unwinder AUTO switched ON *)
    RwStopEnable := FALSE;
END_IF;
IF RwStopEnable AND NOT RwEnMem THEN                (* rewinder AUTO switched ON *)
    UwStopEnable := FALSE;
END_IF;
UwEnMem := UwStopEnable;
RwEnMem := RwStopEnable;

IF RwStopEnable THEN
    SlowAtDisp := RwSlowAtDiam;                     (* mm *)
    SlowAtMode := 2;
ELSIF UwStopEnable THEN
    SlowAtDisp := UwSlow_at_Metre;                  (* m  *)
    SlowAtMode := 1;
ELSE
    SlowAtDisp := 0.0;
    SlowAtMode := 0;                                (* hide display *)
END_IF;
SlowAtShow := (SlowAtMode <> 0);

(* V9: HMI main page, unwinder column, same place:                         *)
(*   UwShowStopLen  -> "STOP LENGTH [m]" (UwStop_At_Meter): AUTO STOP      *)
(*                     UNWINDER active (selector 12SA5 + unwinder AUTO).   *)
(*   UwShowSlowDiam -> "SLOW AT Ø [mm]" (UwSlowDiamAct): normal operation, *)
(*                     sonar ON (diameter slow-down, General rung 16).     *)
UwShowStopLen  := I_AutoStop_OS AND UwStopEnable;
UwShowSlowDiam := NOT UwShowStopLen AND Measure_ON;

(* ---- 9. Automatic stop master = selector 12SA5 (I_AutoStop_OS) -------- *)
AutoSlowCmd := I_AutoStop_OS AND
               ((UwStopEnable AND UwSlowReq) OR (RwStopEnable AND RwSlowReq));

AutoStopCmd := I_AutoStop_OS AND
               ((UwStopEnable AND (UwStop_At_Meter > 0.0)
                 AND (Current_Metre >= UwStop_At_Meter))
                OR (RwStopEnable AND RwStopReq));

(* ---- 10. Unwinder roll empty (for alarm 15) ---------------------------- *)
IF UwDiam_Act > (UwDiamStop + UwEmptyHyst) THEN
    UnWinder_Empty := FALSE;                        (* new roll loaded *)
END_IF;
IF (UwDiam_Act > 0.0) AND (UwDiam_Act <= UwDiamStop) THEN
    UnWinder_Empty := TRUE;                         (* roll empty *)
END_IF;

(* v6x: new parent roll loaded (empty -> not empty) -> HMI popup         *)
(* "DID YOU CHANGE THE PAPER (GSM)?". YES = forget the learned thickness *)
(* (same as NEW PAPER), NO = the HMI resets GsmAsk.                      *)
(* V9: ask only ONCE per REAL new roll: the roll must have been empty for *)
(* 3 s (arms the question), then the new roll must read more than        *)
(* UwDiamStop + 100 mm for 3 s. The sonar bouncing around UwDiamStop     *)
(* (empty core, hands, arms) no longer re-opens the popup.               *)
IF Tick THEN
    IF UnWinder_Empty THEN
        IF UwEmptyTicks < 1000 THEN
            UwEmptyTicks := UwEmptyTicks + 1;
        END_IF;
        IF UwEmptyTicks >= 30 THEN
            GsmArmed := TRUE;
        END_IF;
        UwFullTicks := 0;
    ELSE
        UwEmptyTicks := 0;
        IF GsmArmed AND Measure_ON AND (UwDiam_Act > UwDiamStop + 100.0) THEN
            UwFullTicks := UwFullTicks + 1;
            IF UwFullTicks >= 30 THEN
                GsmAsk := TRUE;
                GsmArmed := FALSE;
                UwFullTicks := 0;
            END_IF;
        ELSE
            UwFullTicks := 0;
        END_IF;
    END_IF;
END_IF;
UwEmptyMem := UnWinder_Empty;
IF GsmAskYes THEN
    RwMat_K := 0.0;
    RwMatLocked := FALSE;                           (* V9 *)
    LongActive := FALSE;
    LearnFailCnt := 0;
    MatChangeCnt := 0;
    GsmAskYes := FALSE;
    GsmAsk := FALSE;
END_IF;

(* ---- 11. Rewinder max diameter protection - ALWAYS active ------------- *)
(* Independent of selector 12SA5 and of the AUTO buttons.                  *)
(* Mechanical limit 680 mm radius = 1360 mm                                *)
IF NOT RwSensFault THEN
    RwLastValidDiam := RwDiam;
END_IF;

IF RwDiam >= RwMaxDiam THEN
    RwRemainMax_Pls := 0.0;
ELSIF RwMat_K > 0.0 THEN
    RwRemainMax_Pls := (RwMaxDiam * RwMaxDiam - RwDiam * RwDiam)
                       / (2.0 * RwMat_K);
ELSE
    RwRemainMax_Pls := 1.0E9;                       (* K not learned: plain limit *)
END_IF;

(* Display: diameter where the max-protection slow-down will start         *)
IF RwMat_K > 0.0 THEN
    SqrtArg := RwMaxDiam * RwMaxDiam - 2.0 * RwMat_K * RwSlowLen_Pls;
    IF SqrtArg > 0.0 THEN
        RwMaxSlowAtDiam := SQRT(SqrtArg);
    ELSE
        RwMaxSlowAtDiam := 0.0;
    END_IF;
ELSIF RwMaxSlowFallback > 0.0 THEN
    RwMaxSlowAtDiam := RwMaxSlowFallback;           (* fallback in use *)
ELSE
    RwMaxSlowAtDiam := RwMaxDiam;
END_IF;

(* Reset only after the roll is removed (diameter well below the limit)    *)
IF (RwDiam < RwMaxDiam - RwResetHyst) AND NOT RwSensFault THEN
    RwMaxStop := FALSE;
    RwMaxSlow := FALSE;
END_IF;

IF NOT RwSensFault THEN
    IF RwRemainMax_Pls <= StopLen_Pls THEN
        RwMaxStop := TRUE;                          (* speed-compensated stop *)
    END_IF;
    IF RwRemainMax_Pls <= RwSlowLen_Pls THEN
        RwMaxSlow := TRUE;                          (* warning slow-down + horn *)
    END_IF;
    IF (RwMat_K <= 0.0) AND (RwMaxSlowFallback > 0.0)
       AND (RwDiam >= RwMaxSlowFallback) THEN
        RwMaxSlow := TRUE;                          (* fallback while K not learned *)
    END_IF;
ELSIF (AI_Diam_Rewinder < RwRawMin) AND (RwLastValidDiam > RwMaxDiam - 100.0) THEN
    RwMaxStop := TRUE;                              (* roll grew into the DT35 near zone *)
END_IF;

(* Max diameter protection added OUTSIDE the 12SA5 master (section 9)      *)
AutoSlowCmd := AutoSlowCmd OR RwMaxSlow;
AutoStopCmd := AutoStopCmd OR RwMaxStop;

(* ---- 12. Learning supervision -> alarm 16 (section Alarms) ------------ *)
(* Learned paper thickness, for display / plausibility check               *)
IF MmPerPulse > 0.0 THEN
    RwThick_mm := RwMat_K * 3.14159 / (2.0 * MmPerPulse);
ELSE
    RwThick_mm := 0.0;
END_IF;

(* Fault: too many consecutive windows / stops that should have            *)
(* learned but did not. Clears by itself on the next good result.          *)
(* v6w: ALARM RESET (panel button or HMI) also clears the fail counters, *)
(* so alarm 16 resets in one press. It comes back only if the learning  *)
(* fails again RwLearnFailMax / RwStopFailMax times in a row.           *)
IF I_RsetAlarm OR Alarm_Reset THEN
    LearnFailCnt := 0;
    StopFailCnt := 0;
END_IF;
GSM_LearnFault := (LearnFailCnt >= RwLearnFailMax)
              OR (StopFailCnt >= RwStopFailMax);       (* -> alarm 16 *)

(* v6e: learning status for the HMI. FALSE until learned.                   *)
GSM_Learned_OK := (RwMat_K > 0.0)
                AND ((RwStopDecel > 0.0) OR NOT RwLearnStop)
                AND NOT GSM_LearnFault;

(* ---- 13. v6h: keep T-one in automatic tension control during the stop - *)
(* While running: BrakeHold = Brake_Cmd (no change in running behaviour).  *)
(* After the stop: stays ON until the web is below 5 m/min, after 15 s,   *)
(* or on E-stop. Already TRUE on the stop scan (Output_Manager runs before *)
(* this section), so O_Brake never drops for one scan.                     *)
(* Output_Manager rung 2:  O_Brake := Brake_Cmd OR BrakeHold               *)
IF O_MotorStart THEN
    BrakeHold := Brake_Cmd AND ControlVoltage;
    BrakeHoldTicks := 0;
ELSIF BrakeHold THEN
    IF Tick THEN
        BrakeHoldTicks := BrakeHoldTicks + 1;
    END_IF;
    (* v6v: signed web speed: a web pulled BACK (negative speed) also     *)
    (* releases the T-one (trace 10/28 15:00: -6.6 m/min, about 20 cm).  *)
    IF NOT ControlVoltage OR (Velocity_M_min < 5.0) OR (BrakeHoldTicks >= 150) THEN
        BrakeHold := FALSE;
    END_IF;
END_IF;

(* ---- 14. v6j: TEACH CORE - automatic offset with an empty core -------- *)
(* HMI: set RwTeachCore (button, Set ON). Conditions: motor stopped, web  *)
(* not moving, DT35 OK. After 2 s stable (filter settled):                 *)
(*     RwAxisDist := RwDist + RwCoreDiameter / 2   -> RwDiam = RwCoreDiameter          *)
(* RwTeachState: 0 idle, 1 teaching (wait 2 s), 2 done OK,                *)
(*               3 refused (motor running / web moving / DT35 fault).     *)
(* Only the offset is taught: the scale is RwDist10V - RwDist0V           *)
(* (= real distance between the two DT35 taught points).                  *)
IF RwTeachCore THEN
    IF O_MotorStart OR (RwSpeed > 1.0) OR RwSensFault
       OR NOT RwFiltInit OR (RwCoreDiameter <= 0.0) THEN
        RwTeachState := 3;                          (* refused *)
        RwTeachCore := FALSE;
        TeachTicks := 0;
    ELSE
        RwTeachState := 1;                          (* teaching *)
        IF Tick THEN
            TeachTicks := TeachTicks + 1;
        END_IF;
        IF TeachTicks >= 20 THEN                    (* 2 s stable *)
            RwAxisDist_Prev := RwAxisDist;          (* v6l: keep previous *)
            RwAxisDist := RwDist + RwCoreDiameter / 2.0;
            RwTeachState := 2;                      (* done *)
            RwTeachCore := FALSE;
            TeachTicks := 0;
        END_IF;
    END_IF;
ELSE
    TeachTicks := 0;
    IF O_MotorStart THEN
        RwTeachState := 0;                          (* clear status on next run *)
    END_IF;
END_IF;

(* ---- 14b. v6k: unwinder TEACH CORE (HMI button Core_Measure) ---------- *)
(* Same behaviour as section 14. Sonar is not filtered, so the 2 s are   *)
(* averaged:  UwCoreDistance := average(UwDiam_Measure)  (sonar -> core   *)
(* surface). UwDiam_Act = (UwCoreDistance - UwDiam_Measure) * 2           *)
(*                        + UwCoreDiameter   (General rung 14, unchanged). *)
(* UwTeachState: 0 idle, 1 teaching, 2 done OK, 3 refused.                 *)
IF Core_Measure THEN
    IF O_MotorStart OR (RwSpeed > 1.0) OR (UwCoreDiameter <= 0.0)
       OR (UwDiam_Measure <= 0.0) THEN
        UwTeachState := 3;                          (* refused *)
        Core_Measure := FALSE;
        UwTeachTicks := 0;
        UwTeachSum := 0.0;
    ELSE
        UwTeachState := 1;                          (* teaching *)
        IF Tick THEN
            UwTeachTicks := UwTeachTicks + 1;
            UwTeachSum := UwTeachSum + UwDiam_Measure;
        END_IF;
        IF UwTeachTicks >= 20 THEN                  (* 2 s, 20 samples *)
            UwCoreDist_Prev := UwCoreDistance;      (* v6l: keep previous *)
            UwCoreDistance := UwTeachSum / INT_TO_REAL(UwTeachTicks);
            UwTeachState := 2;                      (* done *)
            Core_Measure := FALSE;
            UwTeachTicks := 0;
            UwTeachSum := 0.0;
        END_IF;
    END_IF;
ELSE
    UwTeachTicks := 0;
    UwTeachSum := 0.0;
    IF O_MotorStart THEN
        UwTeachState := 0;                          (* clear status on next run *)
    END_IF;
END_IF;

(* ---- 14c. v6l: UNDO teach = swap current <-> previous (machine stopped) *)
(* Pressing UNDO twice goes back to the taught value. State 4 = RESTORED. *)
IF RwTeachUndo THEN
    IF NOT O_MotorStart AND (RwAxisDist_Prev > 0.0) THEN
        TeachSwap := RwAxisDist;
        RwAxisDist := RwAxisDist_Prev;
        RwAxisDist_Prev := TeachSwap;
        RwTeachState := 4;                          (* restored *)
    ELSE
        RwTeachState := 3;                          (* refused *)
    END_IF;
    RwTeachUndo := FALSE;
END_IF;
IF UwTeachUndo THEN
    IF NOT O_MotorStart AND (UwCoreDist_Prev > 0.0) THEN
        TeachSwap := UwCoreDistance;
        UwCoreDistance := UwCoreDist_Prev;
        UwCoreDist_Prev := TeachSwap;
        UwTeachState := 4;                          (* restored *)
    ELSE
        UwTeachState := 3;                          (* refused *)
    END_IF;
    UwTeachUndo := FALSE;
END_IF;
