(* ==========================================================================
   AutoStop_Control  V7   -  Automatic slow-down / stop
   Project : 04820KA001 Mono Canada II  (NX1P2, PrimaryTask 4 ms)
   Rewinder (Rw) : SICK DT35 0-10 V -> AI_Diam_Rewinder (AD2603 Ch2)
   Unwinder (Uw) : meter counter mode + sonar diameter (UwDiam_Act)

   NAMING  Uw_ = unwinder   Rw_ = rewinder
           _mm = millimeters   _m = meters
           _Pls = encoder pulses (counts)   _Pps = pulses per second
           _Pps2 = pulses per second squared

   V7 : FEED-FORWARD speed loop (Motor_Manager rung B): reference = set speed
        x RwRatioD / diameter along a ramp in real web mm/s2 (DecelWeb /
        AccelWeb), RwRatioD adapted slowly -> no hunting on big rolls.
        Section 6: slow-down length = one ramp at DecelWeb (FFEnable), else
        web coarse ramp + trim tail; learning only as fallback.
   v6y: rewinder AUTO stop (RwStopEnable) limits the work speed to
        RwAutoMaxSpd (500 m/min), taken over at standstill only; section 6
        uses the limited speed.
   v6x: new parent roll on the unwinder -> GsmAsk (HMI popup "did you change
        the paper?"); GsmAskYes forgets the learned thickness.
   v6w: paper thickness window is LENGTH-based instead of 10 s, modulated by
        the diameter (RwWinGrow_mm 2.5 mm of growth, 4 m .. RwWinLen_m 30 m):
        same accuracy at every speed and roll size; stopped window = dropped.
        ALARM RESET also clears LearnFailCnt / StopFailCnt (alarm 16).
   v6v: BrakeHold released on the SIGNED web speed (Velocity_M_min < 5),
        so a web pulled back after the stop releases the T-one at once.
   v6u: stop learning: a stop shorter than the reaction distance or faster
        than RwDecelMax_mm is ignored (not a fault). Only a too slow stop
        (< RwDecelMin_mm) counts toward alarm 16.
   v6t: rewinder slow-down fallback while the paper thickness is not
        learned: RwSlowReq at RwTargetDiam - RwSlowFallbackMm (30 mm).
   v6s: paper change: a learning window more than RwMatChangePct (25 %) away
        from RwMat_K is ignored once, taken directly the 2nd time in a row
        (automatic). RwMatReset (HMI "NEW PAPER") forgets RwMat_K.
   v6p: section 5c: RwLearnReset clears RwStopDecelK, RwStopDecel and
        RwSlowDecelK (the v6f seed that refilled RwStopDecelK is removed).
   v6l: previous value saved before every TEACH CORE (RwAxisDist_Prev,
          UwCoreDist_Prev, Retain) + UNDO buttons (RwTeachUndo,
          UwTeachUndo): swap current <-> previous. State 4 = RESTORED.
   v6k: unwinder TEACH CORE (Core_Measure) works like the rewinder one:
          same checks, 2 s stable with sonar AVERAGE, status UwTeachState.
          Replaces General rung 15 (one immediate sonar reading).
   v6j: TEACH CORE (section 14): HMI button RwTeachCore, empty core on the
          rewinder, machine stopped -> after 2 s stable:
          RwAxisDist := RwDist + RwCoreDiameter / 2. Status in RwTeachState.
   v6i: auto: pots scaled to WorkSpd_Max / FinalSpd_Max (Motor_Manager rung 6,
          Pot1_Mem / Pot2_Mem). ManMode keeps the raw pots (percent),
          so section 6 uses the raw pots in ManMode.
   v6h: BrakeHold keeps O_Brake (T-one "reel brake automatic") ON during a
          normal stop until the web is almost stopped (< 5 m/min, max 15 s).
          Before: T-one switched to "stop" with the run command, while the
          rewinder was decelerating hard -> unwinder overran, web on the
          floor (field 10/20/2026). Used in Output_Manager rung 2.
   v6g: slow-down AND stop decel proportional to the rewinder diameter.
          The ATV930 ramp is in Hz/s (motor = rewind shaft), so the web
          decel [mm/s2] = shaft decel x radius. Field data 10/20/2026:
          24 mm/s2 at 120 mm -> 90 mm/s2 at 600 mm.
          Learned: RwSlowDecelK, RwStopDecelK [mm/s2 per mm of diameter].
          Live:    RwSlowDecelLrn [mm/s2], RwStopDecel [pulses/s2] = K x DecelDiam.
   v6f: learn the REAL slow-down deceleration (section 5b) -> RwSlowDecelLrn
          (mm/s2). The ATV930 stretches its ramp with a heavy roll (no
          braking resistor), so the PLC ramp (DecelCoarse) was too
          optimistic: the stop came before final speed was reached.
          Priority in section 6: RwSlowDecel (manual) > RwSlowDecelLrn
          (learned) > DecelCoarse/DecelTrim model.
   v6e: GSM_Learned_OK (replaces global RwLearnFault): TRUE only when
          RwMat_K is learned, RwStopDecel is learned (if RwLearnStop) and
          there is no learning fault. Alarm 16 uses GSM_LearnFault.
   v6d: exact 100 ms tick (25 x 4 ms scan counter, the self-resetting
          TON ran ~104-108 ms -> speed ~4-8 % too high)
        standstill = <= 2 counts / 100 ms (encoder jitter)
        stop learning skipped after jog / manual / slow-button runs and
          when the auxiliaries drop (E-stop): RunWasJog, StopLearnValid
        work / final speed from the potentiometers in BOTH modes
          (Speed_Display / LowSpd_Display are not m/min in ManMode)
        slow-down length includes the DecelTrim tail inside the
          SpdDelta_Percent band (Motor_Manager rungs 14/15)
   v6c: learning supervision -> RwLearnFault (alarm 16), learned paper
          thickness RwThick_mm, plausibility limits for K and stop decel
   v6b: RwMaxSlowAtDiam display + RwMaxSlowFallback (slow-down warning
          while RwMat_K is not learned yet)
   v6 : consistent internal names, units in names.
        Globals renamed: RwRemain_m, RwStopLen_m, RwSlowLen_m,
                         RwSlowMargin_m, UwSlowMargin_m
   v5 : max diameter protection (always active), sensor plausibility,
        12SA5 master (section 9), alarms in section Alarms (ladder)
   v4b: AUTO interlock + single HMI display (SlowAtDisp / SlowAtMode)
   ========================================================================== *)

(* ---- 1. 100 ms tick, mm per encoder pulse ------------------------------ *)
(* v6d: 25 scans x 4 ms PrimaryTask = exactly 100 ms.                       *)
(*      Change 25 if the PrimaryTask period is changed.                    *)
TickCnt := TickCnt + 1;
IF TickCnt >= 25 THEN
    TickCnt := 0;
    Tick := TRUE;
ELSE
    Tick := FALSE;
END_IF;

IF (Encoder_Pulse > 0) AND (EncoderWheel_Diam > 0.0) THEN
    MmPerPulse := EncoderWheel_Diam / (INT_TO_REAL(Encoder_Pulse) * 4.0);
ELSE
    MmPerPulse := 0.0;
END_IF;

(* ---- 2. Rewinder DT35 -> filtered distance -> diameter ----------------- *)
RwDistRaw_mm := RwDist0V + (INT_TO_REAL(AI_Diam_Rewinder) / 4000.0)
                * (RwDist10V - RwDist0V);

IF Tick THEN
    IF NOT RwFiltInit THEN
        RwDist := RwDistRaw_mm;
        RwFiltInit := TRUE;
    ELSE
        RwDist := RwDist + RwFilter_K * (RwDistRaw_mm - RwDist);
    END_IF;
END_IF;

RwSensFault := (AI_Diam_Rewinder < RwRawMin) OR (AI_Diam_Rewinder > RwRawMax)
               OR (RwDist > RwAxisDist);

RwDiam := 2.0 * (RwAxisDist - RwDist);
IF RwDiam < 0.0 THEN
    RwDiam := 0.0;
END_IF;
(* RwAxisDist = DT35 reference to rewind shaft centre (mm), set manually *)

(* v6g: diameter used by the decel model (last valid on sensor fault)      *)
IF NOT RwSensFault THEN
    DecelDiam := RwDiam;
ELSE
    DecelDiam := RwLastValidDiam;
END_IF;
IF DecelDiam < 100.0 THEN
    DecelDiam := 100.0;                             (* core *)
END_IF;

(* ---- 3. Actual speed from encoder, 100 ms window ----------------------- *)
IF Tick THEN
    IF NOT SpdInit THEN
        EncPrev := Encoder_Pos;
        SpdInit := TRUE;
    END_IF;
    SpdAct_Pps := DINT_TO_REAL(ABS(Encoder_Pos - EncPrev)) * 10.0;
    EncPrev := Encoder_Pos;
END_IF;
RwSpeed := SpdAct_Pps * MmPerPulse * 0.06;          (* m/min *)

(* ---- 4a. v6s: NEW PAPER button: forget the learned thickness ----------- *)
(* RwMat_K = 0 -> the first valid 10 s window sets it directly.            *)
(* HMI momentary button: must be HELD 3 s, then the reset is done once and *)
(* the PLC clears the bit (HMI lamp goes off = done).                      *)
T_MatReset(In := RwMatReset, PT := T#3s);
IF T_MatReset.Q THEN
    RwMat_K := 0.0;
    LearnFailCnt := 0;
    MatChangeCnt := 0;
    RwMatReset := FALSE;
END_IF;

(* ---- 4. Learn material factor  K = dDiam/dPulse * Diam ----------------- *)
IF Tick THEN
    LearnWinTicks := LearnWinTicks + 1;
    IF NOT LearnInit THEN
        LearnWinStartPos := Encoder_Pos;  LearnWinStartDiam := RwDiam;
        LearnWinTicks := 0;
        LearnWinRunning := O_MotorStart;
        LearnInit := TRUE;
    ELSE
        LearnWinRunning := LearnWinRunning AND O_MotorStart;
        (* v6w: LENGTH-based window, modulated by the diameter: closes    *)
        (* when the roll should have grown RwWinGrow_mm (2.5 mm), so the  *)
        (* accuracy vs DT35 noise is the same at every speed and size.    *)
        (* Pulses = growth x diameter / K (K = learned RwMat_K).          *)
        (* Limits: min 4 m, max RwWinLen_m (30 m). K not learned: max.    *)
        (* Motor stopped during the window -> window dropped (no fault).  *)
        IF MmPerPulse > 0.0 THEN
            IF (RwMat_K > 0.0) AND (RwWinGrow_mm > 0.0) THEN
                LearnWinLen_Pls := RwWinGrow_mm * MAX(RwDiam, REAL#100.0) / RwMat_K;
            ELSE
                LearnWinLen_Pls := RwWinLen_m * 1000.0 / MmPerPulse;
            END_IF;
            IF LearnWinLen_Pls < 4000.0 / MmPerPulse THEN
                LearnWinLen_Pls := 4000.0 / MmPerPulse;              (* 4 m *)
            END_IF;
            IF (RwWinLen_m > 0.0)
               AND (LearnWinLen_Pls > RwWinLen_m * 1000.0 / MmPerPulse) THEN
                LearnWinLen_Pls := RwWinLen_m * 1000.0 / MmPerPulse;
            END_IF;
        ELSE
            LearnWinLen_Pls := 300000.0;
        END_IF;
        IF (DINT_TO_REAL(ABS(Encoder_Pos - LearnWinStartPos)) >= LearnWinLen_Pls)
           OR NOT LearnWinRunning THEN
            LearnWin_Pls := ABS(Encoder_Pos - LearnWinStartPos);
            LearnWinDiamDelta := RwDiam - LearnWinStartDiam;
            (* A window SHOULD learn: ran all the time, enough length,  *)
            (* DT35 OK. Then it must give a plausible paper thickness. *)
            IF LearnWinRunning AND (LearnWin_Pls >= RwMinPulses)
               AND NOT RwSensFault THEN
                LearnWinOk := FALSE;
                IF (LearnWinDiamDelta > 0.0) AND (MmPerPulse > 0.0) THEN
                    MatK_Window := (LearnWinDiamDelta / DINT_TO_REAL(LearnWin_Pls))
                                   * ((RwDiam + LearnWinStartDiam) / 2.0);
                    (* K = 2 * thickness * mm-per-pulse / PI          *)
                    ThickWin_mm := MatK_Window * 3.14159 / (2.0 * MmPerPulse);
                    IF (ThickWin_mm >= RwThickMin_mm)
                       AND (ThickWin_mm <= RwThickMax_mm) THEN
                        LearnWinOk := TRUE;
                        IF RwMat_K <= 0.0 THEN
                            RwMat_K := MatK_Window;
                            MatChangeCnt := 0;
                        ELSIF (RwMatChangePct > 0.0)
                              AND (ABS(MatK_Window - RwMat_K)
                                   > RwMat_K * RwMatChangePct / 100.0) THEN
                            (* v6s: far from the learned value: 1 window = ignored *)
                            (* (outlier), 2 in a row = paper changed -> take it.  *)
                            MatChangeCnt := MatChangeCnt + 1;
                            IF MatChangeCnt >= 2 THEN
                                RwMat_K := MatK_Window;
                                MatChangeCnt := 0;
                            END_IF;
                        ELSE
                            MatChangeCnt := 0;
                            RwMat_K := RwMat_K + RwLearn_K * (MatK_Window - RwMat_K);
                        END_IF;
                    END_IF;
                END_IF;
                IF LearnWinOk THEN
                    LearnFailCnt := 0;
                ELSIF LearnFailCnt < 1000 THEN
                    LearnFailCnt := LearnFailCnt + 1;  (* no growth / implausible *)
                END_IF;
            END_IF;
            LearnWinStartPos := Encoder_Pos;  LearnWinStartDiam := RwDiam;
            LearnWinTicks := 0;
            LearnWinRunning := O_MotorStart;
        END_IF;
    END_IF;
END_IF;

(* ---- 5. Learn real stop deceleration on every stop --------------------- *)
(* v6d: a run with jog / manual / slow button uses the 2nd ramp (O_AccDec2) *)
(*      -> its stop must not be learned. Latched for the whole run because  *)
(*      I_LowSpd_OS is already released on the stop edge.                  *)
IF O_MotorStart AND NOT MotorRunMem THEN            (* start edge *)
    RunWasJog := FALSE;
END_IF;
IF O_MotorStart AND (ManMode OR I_LowSpd_OS) THEN
    RunWasJog := TRUE;
END_IF;

IF MotorRunMem AND NOT O_MotorStart THEN            (* stop command edge *)
    StopMeasActive := TRUE;
    StopStartPos := Encoder_Pos;
    StopStartSpd_Pps := SpdAct_Pps;
    StopStartDiam := DecelDiam;
    StandstillTicks := 0;
    (* STOP button and automatic stop take the same path (drive DI1 and    *)
    (* O_Brake -> T-one drop together, electrical plan sheets 1/9/15),     *)
    (* so both are learned.                                                *)
    StopLearnValid := ControlVoltage AND NOT RunWasJog AND NOT ManMode;
END_IF;
MotorRunMem := O_MotorStart;

IF O_MotorStart THEN
    StopMeasActive := FALSE;                        (* restarted: abort *)
ELSIF StopMeasActive AND Tick THEN
    IF NOT ControlVoltage THEN
        StopLearnValid := FALSE;                    (* E-stop during the stop *)
    END_IF;
    IF SpdAct_Pps <= 20.0 THEN                      (* <= 2 counts / 100 ms *)
        StandstillTicks := StandstillTicks + 1;
    ELSE
        StandstillTicks := 0;
    END_IF;
    IF StandstillTicks >= 3 THEN                    (* standstill 300 ms *)
        StopMeasActive := FALSE;
        StopMeas_Pls := DINT_TO_REAL(ABS(Encoder_Pos - StopStartPos));
        IF RwLearnStop AND StopLearnValid
           AND (StopStartSpd_Pps * MmPerPulse * 0.06 >= RwMinLearnSpd) THEN
            (* This stop SHOULD learn: result must be plausible       *)
            (* v6u: a stop shorter than the reaction distance, or     *)
            (* faster than RwDecelMax_mm, is NOT a fault: the web      *)
            (* stopped within a few mm, nothing to learn (trace        *)
            (* 10/28/2026: 23 m/min -> stopped in 102 pulses = 10 mm). *)
            (* Only a too SLOW stop (< RwDecelMin_mm) counts as fail.  *)
            StopLearnOk := FALSE;
            IF StopMeas_Pls > StopStartSpd_Pps * RwTreact THEN
                StopDecelMeas := (StopStartSpd_Pps * StopStartSpd_Pps)
                                 / (2.0 * (StopMeas_Pls - StopStartSpd_Pps * RwTreact));
                StopDecelMeas_mm := StopDecelMeas * MmPerPulse;  (* mm/s2 *)
                IF (StopDecelMeas_mm >= RwDecelMin_mm)
                   AND (StopDecelMeas_mm <= RwDecelMax_mm) THEN
                    StopLearnOk := TRUE;
                    (* v6g: learn per mm of diameter *)
                    DecelK_Meas := StopDecelMeas_mm / ((StopStartDiam + DecelDiam) / 2.0);
                    IF RwStopDecelK <= 0.0 THEN
                        RwStopDecelK := DecelK_Meas;
                    ELSE
                        RwStopDecelK := RwStopDecelK + 0.3 * (DecelK_Meas - RwStopDecelK);
                    END_IF;
                    StopFailCnt := 0;
                ELSIF StopDecelMeas_mm < RwDecelMin_mm THEN
                    IF StopFailCnt < 1000 THEN
                        StopFailCnt := StopFailCnt + 1;    (* stop too long *)
                    END_IF;
                END_IF;                                    (* too fast: ignored *)
            END_IF;                                        (* too short: ignored *)
        END_IF;
    END_IF;
END_IF;

(* ---- 5b. v6f: learn real slow-down deceleration ----------------------- *)
(* From the SlowDown edge (at speed) until final speed is reached, or     *)
(* until the stop comes first. a = (v0^2 - v1^2) / (2 * distance).         *)
(* Not learned in jog / manual / slow button (2nd ramp).                   *)
IF SlowDown AND NOT SlowMem AND O_MotorStart
   AND NOT ManMode AND NOT I_LowSpd_OS
   AND (SpdAct_Pps > SpdFinal_Pps + SpdBand_Pps) THEN
    SlowMeasActive := TRUE;
    SlowStartPos := Encoder_Pos;
    SlowStartSpd_Pps := SpdAct_Pps;
    SlowStartDiam := DecelDiam;
END_IF;
SlowMem := SlowDown;

IF SlowMeasActive THEN
    IF NOT SlowDown OR ManMode OR I_LowSpd_OS THEN
        SlowMeasActive := FALSE;                    (* aborted *)
    ELSIF Tick AND ((SpdAct_Pps <= SpdFinal_Pps + 0.25 * SpdBand_Pps)
                    OR NOT O_MotorStart) THEN       (* final reached or stopped *)
        SlowMeasActive := FALSE;
        SlowMeas_Pls := DINT_TO_REAL(ABS(Encoder_Pos - SlowStartPos));
        IF (SlowMeas_Pls > 0.0) AND (MmPerPulse > 0.0)
           AND ((SlowStartSpd_Pps - SpdAct_Pps) * MmPerPulse * 0.06 >= 10.0) THEN
            SlowDecelMeas_mm := (SlowStartSpd_Pps * SlowStartSpd_Pps
                                 - SpdAct_Pps * SpdAct_Pps)
                                / (2.0 * SlowMeas_Pls) * MmPerPulse;  (* mm/s2 *)
            IF (SlowDecelMeas_mm >= RwDecelMin_mm)
               AND (SlowDecelMeas_mm <= RwDecelMax_mm) THEN
                (* v6g: learn per mm of diameter *)
                DecelK_Meas := SlowDecelMeas_mm / ((SlowStartDiam + DecelDiam) / 2.0);
                IF RwSlowDecelK <= 0.0 THEN
                    RwSlowDecelK := DecelK_Meas;
                ELSE
                    RwSlowDecelK := RwSlowDecelK + 0.5 * (DecelK_Meas - RwSlowDecelK);
                END_IF;
            END_IF;
        END_IF;
    END_IF;
END_IF;

(* ---- 5c. v6g: live decels = learned K x current diameter -------------- *)
(* v6p: the one-time v6f seed is removed (it re-filled RwStopDecelK from    *)
(* RwStopDecel, so the learning could never be reset).                     *)
(* RwLearnReset (HMI / Watch tab, PLC resets it): clear the learned decels. *)
(* Both are re-learned at the next auto slow-down / stop >= RwMinLearnSpd.  *)
IF RwLearnReset THEN
    RwStopDecelK := 0.0;
    RwStopDecel := 0.0;
    RwSlowDecelK := 0.0;
    StopFailCnt := 0;
    RwLearnReset := FALSE;
END_IF;
IF (RwStopDecelK > 0.0) AND (MmPerPulse > 0.0) THEN
    RwStopDecel := RwStopDecelK * DecelDiam / MmPerPulse;      (* pulses/s2 *)
END_IF;
IF RwSlowDecelK > 0.0 THEN
    RwSlowDecelLrn := RwSlowDecelK * DecelDiam;                (* mm/s2 *)
ELSE
    RwSlowDecelLrn := 0.0;
END_IF;

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
IF UwEmptyMem AND NOT UnWinder_Empty AND Measure_ON THEN
    GsmAsk := TRUE;
END_IF;
UwEmptyMem := UnWinder_Empty;
IF GsmAskYes THEN
    RwMat_K := 0.0;
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
