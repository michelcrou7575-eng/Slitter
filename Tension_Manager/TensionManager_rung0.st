// ===================== TENSION MANAGER (kg only) =====================
// Section "Tension_Manager" (was Tension_Helper), rung 0, ST, no contact.
// 1. Tension Helper: recommended tension (kg) from paper GSM, roll width, paper type
// 2. T-one remote set point (AO Ch1 -> isolator -> T-one pins 20/19, F.37 = 1):
//    helper x core boost x taper on the rewinder diameter + operator trim (+/-10 kg),
//    x JOG boost while threading (JOG ... START), rate-limited,
//    1..10 V = TensMin_kg..TensMax_kg (T-one F.38 / F.39)
// TensAOEnable = FALSE -> AO Ch1 = fixed 10 V (old Fix10Vdc, pots supply)

// ---- 1. Paper type: KRAFT / BLEACHED selects the factor (N/mm width per 100 g/m2)
IF (TensFactorBleached < REAL#0.1) OR (TensFactorBleached > REAL#2.0) THEN
    TensFactorBleached := REAL#0.54;
END_IF;
IF (TensFactorKraft < REAL#0.1) OR (TensFactorKraft > REAL#2.0) THEN
    TensFactorKraft := REAL#0.80;
END_IF;
IF PaperKraft THEN
    TensFactor := TensFactorKraft;
ELSE
    TensFactor := TensFactorBleached;
END_IF;

// ---- 2. Helper inputs (limits)
IF PaperGSM < REAL#10 THEN
    PaperGSM := REAL#10;
ELSIF PaperGSM > REAL#500 THEN
    PaperGSM := REAL#500;
END_IF;
IF WebWidth_mm < REAL#100 THEN
    WebWidth_mm := REAL#100;
ELSIF WebWidth_mm > REAL#3000 THEN
    WebWidth_mm := REAL#3000;
END_IF;

// ---- 3. Recommended tension (kg)
TensIdeal_N := PaperGSM / REAL#100 * WebWidth_mm * TensFactor;
TensIdeal_Disp := TensIdeal_N / REAL#9.81;

// ---- 4. Setup limits (maintenance popup)
IF TensTaper < REAL#0.0 THEN
    TensTaper := REAL#0.0;
ELSIF TensTaper > REAL#60.0 THEN
    TensTaper := REAL#60.0;
END_IF;
IF TensCoreBoost < REAL#0.0 THEN
    TensCoreBoost := REAL#0.0;
ELSIF TensCoreBoost > REAL#50.0 THEN
    TensCoreBoost := REAL#50.0;
END_IF;
IF TensJogBoost < REAL#0.0 THEN
    TensJogBoost := REAL#0.0;
ELSIF TensJogBoost > REAL#100.0 THEN
    TensJogBoost := REAL#100.0;
END_IF;
IF TensRate_kg_s < REAL#1.0 THEN
    TensRate_kg_s := REAL#1.0;
ELSIF TensRate_kg_s > REAL#20.0 THEN
    TensRate_kg_s := REAL#20.0;
END_IF;
IF TensMin_kg < REAL#0.0 THEN
    TensMin_kg := REAL#0.0;
END_IF;
IF TensMax_kg < TensMin_kg + REAL#5.0 THEN
    TensMax_kg := TensMin_kg + REAL#5.0;
END_IF;

// ---- 5. Operator trim (HMI up/down, +/-10 kg), back to 0 when the paper changes
IF TensTrim_kg < REAL#-10.0 THEN
    TensTrim_kg := REAL#-10.0;
ELSIF TensTrim_kg > REAL#10.0 THEN
    TensTrim_kg := REAL#10.0;
END_IF;
IF (PaperGSM <> TensGSMMem) OR (WebWidth_mm <> TensWidthMem) OR (PaperKraft <> TensKraftMem) THEN
    TensTrim_kg := REAL#0.0;
END_IF;
TensGSMMem := PaperGSM;
TensWidthMem := WebWidth_mm;
TensKraftMem := PaperKraft;

// ---- 6. Rewinder diameter fraction 0 (core) .. 1 (max diameter)
IF (RwMaxDiam > RwCoreDiameter + REAL#50.0) AND NOT RwSensFault THEN
    TensDiaFrac := (RwDiam - RwCoreDiameter) / (RwMaxDiam - RwCoreDiameter);
ELSE
    TensDiaFrac := REAL#0.0;                       // DT35 fault: no taper
END_IF;
IF TensDiaFrac < REAL#0.0 THEN
    TensDiaFrac := REAL#0.0;
ELSIF TensDiaFrac > REAL#1.0 THEN
    TensDiaFrac := REAL#1.0;
END_IF;

// ---- 7. Profile preview (HMI): core / mid / max
TensAtCore := TensIdeal_Disp * (REAL#1.0 + TensCoreBoost / REAL#100.0);
TensAtMid  := TensAtCore * (REAL#1.0 - TensTaper / REAL#100.0 * REAL#0.5);
TensAtMax  := TensAtCore * (REAL#1.0 - TensTaper / REAL#100.0);

// ---- 7b. Threading / knife adjustment preset: JOG raises the tension, START resumes normal
IF JogRun THEN
    TensJogLatch := TRUE;
END_IF;
IF StartPB_OK AND NOT StartBlocked THEN            // START accepted -> normal tension
    TensJogLatch := FALSE;
END_IF;

// ---- 8. Target: profile (taper) + trim, or manual; x JOG boost while threading
IF TensAuto THEN
    TensTarget := TensAtCore * (REAL#1.0 - TensTaper / REAL#100.0 * TensDiaFrac) + TensTrim_kg;
ELSE
    TensTarget := TensManual_kg;
END_IF;
IF TensJogLatch THEN
    TensTarget := TensTarget * (REAL#1.0 + TensJogBoost / REAL#100.0);
END_IF;
IF TensTarget < TensMin_kg THEN
    TensTarget := TensMin_kg;
ELSIF TensTarget > TensMax_kg THEN
    TensTarget := TensMax_kg;
END_IF;

// ---- 9. Rate limit (4 ms scan): smooth change of GSM / width / type / mode / trim / JOG boost
TensStep := TensRate_kg_s * REAL#0.004;
IF TensSet_kg < TensTarget - TensStep THEN
    TensSet_kg := TensSet_kg + TensStep;
ELSIF TensSet_kg > TensTarget + TensStep THEN
    TensSet_kg := TensSet_kg - TensStep;
ELSE
    TensSet_kg := TensTarget;
END_IF;

// ---- 10. Analog output Ch1
IF TensAOEnable THEN
    // 1..10 V (400..4000) = TensMin_kg..TensMax_kg ; 0 V = wire broken (below range)
    TensAOReal := REAL#400.0 + REAL#3600.0 * (TensSet_kg - TensMin_kg) / (TensMax_kg - TensMin_kg);
    IF TensAOReal < REAL#400.0 THEN
        TensAOReal := REAL#400.0;
    ELSIF TensAOReal > REAL#4000.0 THEN
        TensAOReal := REAL#4000.0;
    END_IF;
    AO_TOne_SetPoint := REAL_TO_INT(TensAOReal);
ELSE
    AO_TOne_SetPoint := INT#4000;                  // fixed 10 V (pots supply, as Fix10Vdc)
END_IF;
