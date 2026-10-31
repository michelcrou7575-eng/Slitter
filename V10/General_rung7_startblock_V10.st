// ==== V10: REPLACE the code of General rung 7 ("START blocked by JOG", printed V9).
// START push-button is ignored while the JOG (slow speed) button is held and for
// 2 s after it is released. A START held during the block must be released and
// pressed again (no start by itself when the 2 s are over).
// Without this: START pressed during a jog sets Slow_Inhibit -> releasing the jog
// no longer stops (General rung 11) and VelSet jumps to the work speed.
T_JogStartBlk(In := I_Jog_PB, PT := T#2s);       // TOF: ON while held + 2 s
StartHeldBlk := (StartHeldBlk OR (I_Start_PB AND T_JogStartBlk.Q)) AND I_Start_PB;
StartPB_OK := I_Start_PB AND NOT T_JogStartBlk.Q AND NOT StartHeldBlk;

// V10: JogRun = a JOG really running: JOG button held, NOT a normal START run
// (Slow_Inhibit = normal run, set by START) and NOT a soft stop. Used instead of
// the raw I_Jog_PB for: guard bypass (Output 13), 2nd drive ramp (Output 12),
// pot reading (Motor_Manager 8), feed-forward (Motor_Manager 14/17), AutoStop learning.
// Without it, holding JOG during a 500 m/min run bypassed the front gate / lateral
// doors safety (23KA4 // 5SA1) and switched the drive to its 2nd ramp.
JogRun := I_Jog_PB AND NOT Slow_Inhibit AND NOT SoftStop;
