(* ==========================================================================
   AutoStop_Control  V10  -  PART 1 of 2 (rung 0): sections 1 - 5c
   Project : 04820KA001 Mono Canada II  (NX1P2, PrimaryTask 4 ms)
   Rewinder (Rw) : SICK DT35 0-10 V -> AI_Diam_Rewinder (AD2603 Ch2)
   Unwinder (Uw) : meter counter mode + sonar diameter (UwDiam_Act)

   NAMING  Uw_ = unwinder   Rw_ = rewinder
           _mm = millimeters   _m = meters
           _Pls = encoder pulses (counts)   _Pps = pulses per second
           _Pps2 = pulses per second squared

   V10: JogRun (jog really running) instead of the raw jog button (5, 5b);
          long baseline also restarted if the encoder goes 2 m back (4b).
   V9 : RwDiamRev = DT35 averaged over exactly one revolution (2b), used by
          the thickness learning (removes the out-of-round wave), RwWave_mm.
        GSM popup: once per real new roll (empty 3 s, then > stop + 100 mm
          for 3 s); NEW PAPER closes it (section 10).
        paper thickness: long-baseline learning (D^2 growth / length) from the
          start point, LOCKED at RwLockDiam (300 mm): no more change, no
          paper-change detection, until NEW PAPER / GSM popup YES (4b).
   V8 : = V7 + V7c unwinder DIAMETER slow-down follows the speed (6c),
          V7e ManMode slow-down model as before V7 (section 6),
          V7f S-curve extra length in the slow-down (section 6)
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

(* ---- 2b. V9: diameter averaged over exactly ONE revolution -------------- *)
(* The out-of-round roll gives a wave at the rotation frequency (seen in   *)
(* the 10/29 traces: 2.4 Hz at 444 m/min / 973 mm). Averaging the raw     *)
(* DT35 distance over exactly one revolution cancels it (and all its      *)
(* harmonics), whatever the phase -> no shaft position sensor needed:     *)
(* one revolution = PI x D of web on the encoder. Each scan is weighted   *)
(* by its encoder pulses = by roll ANGLE, so ramps and standstill do not  *)
(* bias it (stopped: nothing added). Used only by the thickness learning. *)
(* RwWave_mm = peak-peak diameter wave in the last revolution (HMI).      *)
RevDP := ABS(Encoder_Pos - RevPrevPos);
RevPrevPos := Encoder_Pos;
IF RwSensFault OR (MmPerPulse <= 0.0) OR (RwDiam < 50.0) OR (RevDP > 100000) THEN
    RevW := 0.0;
    RevSum := 0.0;
    RwDiamRevOk := RwDiamRevOk AND NOT RwSensFault;
ELSIF RevDP > 0 THEN
    IF RevW <= 0.0 THEN
        RevMin := RwDistRaw_mm;
        RevMax := RwDistRaw_mm;
    END_IF;
    RevSum := RevSum + RwDistRaw_mm * DINT_TO_REAL(RevDP);
    RevW := RevW + DINT_TO_REAL(RevDP);
    IF RwDistRaw_mm < RevMin THEN
        RevMin := RwDistRaw_mm;
    END_IF;
    IF RwDistRaw_mm > RevMax THEN
        RevMax := RwDistRaw_mm;
    END_IF;
    IF RevW >= 3.14159 * RwDiam / MmPerPulse THEN
        RwDiamRev := 2.0 * (RwAxisDist - RevSum / RevW);
        RwWave_mm := 2.0 * (RevMax - RevMin);
        RwDiamRevOk := TRUE;
        RevW := 0.0;
        RevSum := 0.0;
    END_IF;
END_IF;

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
    RwMatLocked := FALSE;                           (* V9 *)
    LongActive := FALSE;
    GsmAsk := FALSE;                                (* V9: NEW PAPER answers the popup *)
    GsmArmed := FALSE;
    RwMatReset := FALSE;
END_IF;

(* ---- 4b. V9: long-baseline thickness learning + LOCK ------------------- *)
(* From the start point (first run after NEW PAPER / GSM YES / power-on    *)
(* while not locked): K = (D^2 - D0^2) / (2 x pulses). The waving of the   *)
(* roll (+/-0.4 mm) only matters at the two ends, so the error falls with  *)
(* the growth (50 mm growth: ~1 %). After 20 mm growth it replaces the     *)
(* 30 m windows. At RwLockDiam (and >= RwLockMinGrow_mm growth) the value *)
(* is LOCKED (Retain): windows and paper-change detection stop.            *)
(* RwLockDiam = 0 -> never locked (windows + long baseline as learning).   *)
IF Tick AND NOT RwMatLocked THEN
    IF LongActive AND (RwDiamRev < LongStartD - 30.0) AND RwDiamRevOk THEN
        LongActive := FALSE;                        (* new core: restart *)
    END_IF;
    IF Encoder_Reset OR (Encoder_Pos < LongStartPos - 20000) THEN
        LongActive := FALSE;                        (* metre counter reset / 2 m back *)
    END_IF;
    IF NOT LongActive AND O_MotorStart AND RwDiamRevOk
       AND (RwDiamRev > 0.0) THEN
        LongStartPos := Encoder_Pos;
        LongStartD := RwDiamRev;
        LongActive := TRUE;
    END_IF;
    LongValid := FALSE;
    IF LongActive AND RwDiamRevOk AND (MmPerPulse > 0.0) THEN
        LongGrow_mm := RwDiamRev - LongStartD;
        LongPls := DINT_TO_REAL(ABS(Encoder_Pos - LongStartPos));
        IF (LongGrow_mm >= 20.0) AND (LongPls > 0.0) THEN
            LongK := (RwDiamRev * RwDiamRev - LongStartD * LongStartD) / (2.0 * LongPls);
            LongThick_mm := LongK * 3.14159 / (2.0 * MmPerPulse);
            IF (LongThick_mm >= RwThickMin_mm) AND (LongThick_mm <= RwThickMax_mm) THEN
                LongValid := TRUE;
                RwMat_K := LongK;
                MatChangeCnt := 0;
                LearnFailCnt := 0;
                IF (RwLockDiam > 0.0) AND (RwDiamRev >= RwLockDiam)
                   AND (LongGrow_mm >= RwLockMinGrow_mm) THEN
                    RwMatLocked := TRUE;            (* solid from now on *)
                    LongActive := FALSE;
                END_IF;
            END_IF;
        END_IF;
    END_IF;
END_IF;
IF RwMatLocked THEN
    LongValid := FALSE;
    LearnFailCnt := 0;                              (* no thickness alarm *)
END_IF;

(* ---- 4. Learn material factor  K = dDiam/dPulse * Diam ----------------- *)
IF Tick THEN
    LearnWinTicks := LearnWinTicks + 1;
    IF NOT LearnInit THEN
        LearnWinStartPos := Encoder_Pos;  LearnWinStartDiam := RwDiamRev;  (* V9 *)
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
            LearnWinDiamDelta := RwDiamRev - LearnWinStartDiam;  (* V9 *)
            (* A window SHOULD learn: ran all the time, enough length,  *)
            (* DT35 OK. Then it must give a plausible paper thickness. *)
            IF LearnWinRunning AND (LearnWin_Pls >= RwMinPulses)
               AND NOT RwSensFault
               AND NOT RwMatLocked AND NOT LongValid      (* V9 *)
               AND RwDiamRevOk AND (LearnWinStartDiam > 0.0) THEN
                LearnWinOk := FALSE;
                IF (LearnWinDiamDelta > 0.0) AND (MmPerPulse > 0.0) THEN
                    MatK_Window := (LearnWinDiamDelta / DINT_TO_REAL(LearnWin_Pls))
                                   * ((RwDiamRev + LearnWinStartDiam) / 2.0);
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
            LearnWinStartPos := Encoder_Pos;  LearnWinStartDiam := RwDiamRev;  (* V9 *)
            LearnWinTicks := 0;
            LearnWinRunning := O_MotorStart;
        END_IF;
    END_IF;
END_IF;

(* ---- 5. Learn real stop deceleration on every stop --------------------- *)
(* v6d: a run with jog / manual / slow button uses the 2nd ramp (O_AccDec2) *)
(*      -> its stop must not be learned. Latched for the whole run because  *)
(*      the jog button is already released on the stop edge.                  *)
IF O_MotorStart AND NOT MotorRunMem THEN            (* start edge *)
    RunWasJog := FALSE;
END_IF;
IF O_MotorStart AND (ManMode OR JogRun) THEN
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
   AND NOT ManMode AND NOT JogRun
   AND (SpdAct_Pps > SpdFinal_Pps + SpdBand_Pps) THEN
    SlowMeasActive := TRUE;
    SlowStartPos := Encoder_Pos;
    SlowStartSpd_Pps := SpdAct_Pps;
    SlowStartDiam := DecelDiam;
END_IF;
SlowMem := SlowDown;

IF SlowMeasActive THEN
    IF NOT SlowDown OR ManMode OR JogRun THEN
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

