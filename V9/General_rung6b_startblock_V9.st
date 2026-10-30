// ==== V9: NEW General rung, INSERT between rung 6 ("10 V DC source") and rung 7
// ==== ("Slow_Inhibit"). ST rung, no contact in front. Comment: "V9: START blocked by JOG".
// START push-button is ignored while the JOG (slow speed) button is held and for
// 2 s after it is released. A START held during the block must be released and
// pressed again (no start by itself when the 2 s are over).
// Without this: START pressed during a jog sets Slow_Inhibit -> releasing the jog
// no longer stops (General rung 10) and VelSet jumps to the work speed.
T_JogStartBlk(In := I_LowSpd_OS, PT := T#2s);       // TOF: ON while held + 2 s
StartHeldBlk := (StartHeldBlk OR (I_Start_PB AND T_JogStartBlk.Q)) AND I_Start_PB;
StartPB_OK := I_Start_PB AND NOT T_JogStartBlk.Q AND NOT StartHeldBlk;
