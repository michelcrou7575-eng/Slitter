// ==== AutoStop_Control rung 1 (part 2), section 6c: REPLACE from
// ====   IF UwSlowDiamLatch AND (UwDiam_Act > UwSlowDiamAct + 30.0) THEN
// ==== down to the END_IF that closes  IF NOT UwSlowDiamLatch THEN ... (the 2 latch blocks)
// FIX 11/11: latch could never release when the point was frozen near 1510
// (release needed a roll > 1540 mm) -> machine stuck at final speed.
// Release now: a new roll bigger than the diameter where it latched, or machine
// stopped with the roll clearly above the live point. Latch only while running.
IF UwSlowDiamLatch AND ((UwDiam_Act > UwDiamAtLatch + 30.0)
   OR (NOT StartMotor_Cmd AND (UwDiam_Act > UwSlowDiamCalc + 30.0))) THEN
    UwSlowDiamLatch := FALSE;                       (* new roll / point moved *)
END_IF;
IF NOT UwSlowDiamLatch THEN
    UwSlowDiamAct := UwSlowDiamCalc;                (* live point, HMI *)
    IF Measure_ON AND StartMotor_Cmd AND (UwDiam_Act > 0.0)
       AND (UwDiam_Act <= UwSlowDiamCalc) THEN
        UwSlowDiamLatch := TRUE;
        UwDiamAtLatch := UwDiam_Act;                (* diameter when latched *)
        UwSlowDiamAct := UwSlowDiamCalc + 10.0;     (* frozen + hysteresis *)
    END_IF;
END_IF;
