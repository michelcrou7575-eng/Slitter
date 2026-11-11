// ==== AutoStop_Control rung 0 (part 1), section 5b: REPLACE the line
// ====   IF (SlowDecelMeas_mm >= RwDecelMin_mm)
// ==== by the 2 lines below (the rest of 5b unchanged)
// FIX 11/11: a slow ramp (e.g. end-of-roll / soft stop) could teach a very low
// slow-down decel -> huge slow-down length -> UwSlowDiamCalc clamped at 1500.
// Only learn a decel of at least RwSlowLearnMin_mm (default 50 mm/s2).
            IF (SlowDecelMeas_mm >= RwDecelMin_mm)
               AND (SlowDecelMeas_mm >= RwSlowLearnMin_mm)
