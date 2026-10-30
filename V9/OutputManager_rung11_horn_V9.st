// ==== V9: REPLACE Output_Manager rung 11 ("Horn / acoustic signal.", ladder) by ONE ST rung
// ==== with this code (no contact in front). Comment: "V9: horn, beeps set on the HMI".
// Old: horn blinking with Clock1s (0.5 s ON / 0.5 s OFF) during the whole slow-down
//      and the crawl at final speed -> very annoying.
// New, slow-down / final speed (StartMotor_Cmd AND SlowDown AND NOT Stop):
//      HornStartBeep_s beep when it starts (1 s),
//      then a HornBeepLen_s beep (0.2 s) every HornBeepPeriod (5 s),
//      then ONE HornStopBeep_s beep (3 s) when the machine has stopped (< 2 m/min).
//      Each setting 0 = that beep OFF. Front guard moving: unchanged (Clock1s blinking).
// PrimaryTask 4 ms: 250 scans = 1 s.

// HMI limits
IF HornStartBeep_s < REAL#0 THEN
    HornStartBeep_s := REAL#0;
ELSIF HornStartBeep_s > REAL#5 THEN
    HornStartBeep_s := REAL#5;
END_IF;
IF HornBeepLen_s < REAL#0 THEN
    HornBeepLen_s := REAL#0;
ELSIF HornBeepLen_s > REAL#2 THEN
    HornBeepLen_s := REAL#2;
END_IF;
IF HornBeepPeriod < REAL#0 THEN
    HornBeepPeriod := REAL#0;
ELSIF (HornBeepPeriod > REAL#0) AND (HornBeepPeriod < HornBeepLen_s + REAL#0.5) THEN
    HornBeepPeriod := HornBeepLen_s + REAL#0.5;     // always a pause between beeps
ELSIF HornBeepPeriod > REAL#30 THEN
    HornBeepPeriod := REAL#30;
END_IF;
IF HornStopBeep_s < REAL#0 THEN
    HornStopBeep_s := REAL#0;
ELSIF HornStopBeep_s > REAL#10 THEN
    HornStopBeep_s := REAL#10;
END_IF;
HornStartScans := REAL_TO_INT(HornStartBeep_s * REAL#250);
HornLenScans   := REAL_TO_INT(HornBeepLen_s * REAL#250);
HornPer        := REAL_TO_INT(HornBeepPeriod * REAL#250);

// Slow-down / final speed beeps
HornRun := StartMotor_Cmd AND SlowDown AND NOT Stop;
IF HornRun THEN
    IF NOT HornRunMem THEN
        HornTicks := 0;                             // slow-down starts
    END_IF;
    IF HornTicks < 30000 THEN
        HornTicks := HornTicks + 1;
    END_IF;
    IF HornTicks <= HornStartScans THEN
        HornSlowBeep := TRUE;                       // start beep
        HornCnt := 0;
    ELSIF (HornPer > 0) AND (HornLenScans > 0) THEN
        HornCnt := HornCnt + 1;
        IF HornCnt >= HornPer THEN
            HornCnt := 0;
        END_IF;
        HornSlowBeep := (HornCnt >= HornPer - HornLenScans);   // beep at the end of each period
    ELSE
        HornSlowBeep := FALSE;                      // periodic beeps OFF
    END_IF;
ELSE
    HornTicks := 0;
    HornCnt := 0;
    HornSlowBeep := FALSE;
END_IF;

// End of a slow-down by a stop (auto stop, STOP button): one beep at standstill
// (Stop is set in Motor_Manager before StartMotor_Cmd drops on the next scan)
IF HornRunMem AND NOT HornRun AND (Stop OR NOT StartMotor_Cmd) THEN
    HornStopPend := TRUE;
END_IF;
IF StartMotor_Cmd AND NOT HornStartMem THEN
    HornStopPend := FALSE;                          // restarted: no stop beep
    HornStopTicks := 0;
END_IF;
HornStartMem := StartMotor_Cmd;
IF HornStopPend AND (Velocity_M_min < REAL#2) THEN
    HornStopPend := FALSE;
    HornStopTicks := REAL_TO_INT(HornStopBeep_s * REAL#250);
END_IF;
IF HornStopTicks > 0 THEN
    HornStopTicks := HornStopTicks - 1;
END_IF;
HornRunMem := HornRun;

// HMI test button: horn while pressed (machine stopped only)
O_AcousticSignal := (NOT I_FrontGuard_Closed AND NOT I_FrontGuard_Open AND Clock1s)
                    OR HornSlowBeep OR (HornStopTicks > 0)
                    OR (HornTest AND NOT StartMotor_Cmd);
