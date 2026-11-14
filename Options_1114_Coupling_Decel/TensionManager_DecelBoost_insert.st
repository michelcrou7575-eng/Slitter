// ==== OPTION A: Tension_Manager rung 0 - "decel boost"
// ==== (a) Section 8: ADD right AFTER the JOG boost block
// ====     (IF TensJogLatch THEN ... END_IF;) and BEFORE the TensMin/TensMax clamp.

// Decel boost: more unwinder brake while the line slows down, so the web keeps
// the rewind coupling loaded (no knock) and the unwinder does not overrun.
// TOneDecel (Motor_Manager rung 17): ramping down / soft stop / end-of-roll ramp.
// BrakeHold: T-one kept in AUTO after the stop until < 5 m/min.
IF TensDecBoost < REAL#0.0 THEN
    TensDecBoost := REAL#0.0;
ELSIF TensDecBoost > REAL#60.0 THEN
    TensDecBoost := REAL#60.0;
END_IF;

TensDecActive := TOneDecel OR (BrakeHold AND NOT StartMotor_Cmd);

IF TensDecActive THEN
    TensTarget := TensTarget * (REAL#1.0 + TensDecBoost / REAL#100.0);
END_IF;


// ==== (b) Section 9: REPLACE the line
// ====     TensStep := TensRate_kg_s * REAL#0.004;
// ==== with:

IF TensDecRate_kg_s < REAL#5.0 THEN
    TensDecRate_kg_s := REAL#5.0;
ELSIF TensDecRate_kg_s > REAL#100.0 THEN
    TensDecRate_kg_s := REAL#100.0;
END_IF;

IF TensDecActive THEN
    TensStep := TensDecRate_kg_s * REAL#0.004;      // fast while decelerating
ELSE
    TensStep := TensRate_kg_s * REAL#0.004;
END_IF;
