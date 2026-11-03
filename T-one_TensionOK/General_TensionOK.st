// ==== General: NEW ST rung (no contact), directly BELOW rung 7 (JogRun / GuardStopOK)
// ==== Comment: "T-one Alarm 0: tension established"
// T-one: F.9 = 0 (alarm when tension ABOVE threshold), F.10 = threshold (kg), F.11 = full scale
// Relay pins 15-16 (Alarm 0): +24 V -> pin 15, pin 16 -> Inline IB IL 24 DI 8 IN05, pin 1.3
// I_T_one_TensionOK = node#[1,0] _IN05 (Pin 1.3) (was I_SlowSens_PH, used in no rung)
// Relay closed = tension > F.10 (not latched). Broken wire / T-one off = "no tension" (fail-safe).

T_TensOn(In := I_T_one_TensionOK, PT := T#500ms);        // stable 0.5 s
T_TensOff(In := NOT I_T_one_TensionOK, PT := T#2s);      // ignore short dips (splice, wave, chatter)
IF T_TensOn.Q OR NOT TensCheckEnable THEN                // HMI switch OFF = old behaviour
    TensionOK := TRUE;
ELSIF T_TensOff.Q THEN
    TensionOK := FALSE;
END_IF;
// Latch: tension reached once since START
IF NOT StartMotor_Cmd THEN
    TensSeen := FALSE;
ELSIF TensionOK THEN
    TensSeen := TRUE;
END_IF;
// After START: hold at TensWaitSpd until the tension is there (JOG not affected)
TensWait := StartMotor_Cmd AND NOT TensSeen AND NOT JogRun;
// Tension lost later while running -> warning only (no slow-down)
TensLostWarn := StartMotor_Cmd AND TensSeen AND NOT TensionOK;
