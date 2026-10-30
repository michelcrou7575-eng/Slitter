// ---- V8 (V7d): add at the END of Motor_Manager rung 5, after the V7 clamps
// ---- (last lines now: RwMaxSlowFallback clamp), before Output_Ratio / Input_Ratio.
// V7d: jog / slow start button blocked on a big rewinder roll.
// RwJogMaxDiam (mm, HMI, Retain): 0 = no limit, else min 150.
// DT35 fault -> jog allowed (needed to thread / clear the machine).
IF (RwJogMaxDiam > REAL#0) AND (RwJogMaxDiam < REAL#150) THEN
    RwJogMaxDiam := REAL#150;
END_IF;
JogInhibit := (RwJogMaxDiam > REAL#0) AND (RwDiam > RwJogMaxDiam) AND NOT RwSensFault;
