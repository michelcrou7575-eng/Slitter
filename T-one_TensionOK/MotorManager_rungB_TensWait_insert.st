// ==== Motor_Manager rung B ("V7: feed-forward speed loop"): INSERT these lines
// ==== AFTER the FFTarget clamp (... ELSIF FFTarget < 0.0 THEN FFTarget := 0.0; END_IF;)
// ==== and BEFORE the V9 block "IF SpdHold THEN".

    // Tension: hold at TensWaitSpd until the T-one reports tension (I_T_one_TensionOK)
    IF TensWait AND (VelSet > TensWaitSpd) THEN
        FFTarget := TensWaitSpd * WebRatio * Output_Ratio;
    END_IF;
