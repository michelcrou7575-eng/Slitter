// ==== Alarms: NEW ST rung (no contact) after rung 20 "Rewinder learning fault - Reset"
// ==== Comment: "Alarm 17: unwinder sonar fault / Alarm 21: thickness not learned (warning)"

// ---- Alarm 17 (ALARM): unwinder sonar (NX-AD2603 Ch1, P+F UC2000) fault ----
// Raw value out of range for 1 s (no echo / broken wire / sensor off).
// Set when the measurement is used (unwinder AutoStop ON or motor running),
// latched, RESET only once the sensor is OK again (same as alarm 10, DT35).
T_UwSensFlt(In := (AI_Diam_Unwinder < UwRawMin) OR (AI_Diam_Unwinder > UwRawMax), PT := T#1s);
UwSensFault := T_UwSensFlt.Q;
IF ControlVoltage AND Measure_ON AND UwSensFault AND (UwAutoStopEnable OR StartMotor_Cmd) THEN
    Alarm_Array[17] := TRUE;
ELSIF NOT UwSensFault AND (I_RsetAlarm OR Alarm_Reset) THEN
    Alarm_Array[17] := FALSE;
END_IF;

// ---- Alarm 21 (WARNING): AutoStop ON but paper thickness not learned ----
// RwMat_K = 0 -> diameter / stop-length targets use the fixed fallback.
// Only above 300 mm rewinder diameter (learning needs ~20 mm growth after NEW PAPER),
// so it does not beep at every new roll. Not latched.
Alarm_Array[21] := ControlVoltage AND StartMotor_Cmd AND (UwAutoStopEnable OR RwStopEnable)
                   AND (RwMat_K <= 0.0) AND (RwDiam > 300.0);
