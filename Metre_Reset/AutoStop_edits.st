// ==== AutoStop_Control rung 1 (part 2): 3 small edits (add "AND NOT CntResetPend")

// (a) Section 6 (unwinder metre slow-down request), the IF that sets UwSlow_at_M_Req:
IF (UwStop_at_M_Val > 0.0) AND (Current_Metre >= UwSlow_at_M_Val) AND NOT CntResetPend THEN
    UwSlow_at_M_Req := TRUE;

// (b) Section 9, AutoStopCmd metre term:
AutoStopCmd := I_AutoStop_OS AND
               ((UwStopEnable AND (UwStop_at_M_Val > 0.0)
                 AND (Current_Metre >= UwStop_at_M_Val) AND NOT CntResetPend)
                OR (RwStopEnable AND RwStop_at_D_Req));

// (c) Section 8, unwinder AUTO STOP refusal:
IF I_AutoStop_OS AND UwStopEnable AND NOT UwArmMem AND NOT CntResetPend
   AND (UwStop_at_M_Val > REAL#0.0) AND (Current_Metre >= UwStop_at_M_Val) THEN

// (AutoStopWhy bit "unwinder metres" in 11c: unchanged)
