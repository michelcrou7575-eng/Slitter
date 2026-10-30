// ==== V9: REPLACE Motor_Manager rungs 11 ("Read the current value of the encoder", MOVE on
// ==== Clock100ms rising edge) and 12 ("Speed calculation", Clock100ms falling edge) by ONE
// ==== ST rung with this code (no contact in front). Comment: "V9: speed over exactly 100 ms".
// Old: window = time between the rising and falling edge of Clock100ms, assumed 50 ms,
// but with the 4 ms PrimaryTask it is 12 or 13 scans (48 / 52 ms) -> the speed jumps
// -4 % / +4 % (418 set: display 397 / 431).
// New: exactly 25 scans = 100 ms (same as AutoStop SpdAct_Pps), updated 10 times/s.
SpdScanCnt := SpdScanCnt + 1;
IF SpdScanCnt >= 25 THEN
    SpdScanCnt := 0;
    DeltaPulse := Encoder_Pos - MemPos;
    MemPos := Encoder_Pos;
    IF ABS(DeltaPulse) > 100000 THEN                 // counter reset (Encoder_Reset)
        DeltaPulse := 0;
    END_IF;
    Velocity := DINT_TO_REAL(DeltaPulse) * EncoderPulse_to_mm * REAL#10;   // mm/s
    Velocity_M_min := Velocity / Mt_To_mm;
END_IF;
