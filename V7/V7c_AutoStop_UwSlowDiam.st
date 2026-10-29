(* ==== V7c: paste in AutoStop_Control section 6, right AFTER the block     *)
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
                           + 2.0 * RwMat_K * UwSlowLen_Pls);
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
