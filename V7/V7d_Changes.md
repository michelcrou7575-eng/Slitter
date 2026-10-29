# V7d: no jog on a big rewinder roll (10/29)

Jog (slow start button `I_LowSpd_OS`) is not useful on a big rewind roll and runs badly
(breakaway / stick-slip, see `Traces/GSM20261029155900_00001_V7b_JOG.csv`).
It is now blocked when the rewinder diameter is above `RwJogMaxDiam` (default 400 mm).

1. Globals: paste `V7d_Globals_paste.txt` (`RwJogMaxDiam` 400 Retain, `JogInhibit`).
2. Motor_Manager rung 5: add `V7d_MotorManager_rung5_jog.st` at the end.
3. **General rung 8** ("Main Motor start"), slow branch
   `I_LowSpd_OS — Slow_Inhibit(NC) — I_Start_PB(NC) — T_StartLow`:
   add a **NC contact `JogInhibit`** in series (after `I_Start_PB`, before `T_StartLow`).
   Only the start is blocked; a jog already running stops on release as before (rung 10).
   Blocks the jog in AUTO and in ManMode (same start rung).
4. HMI: `RwJogMaxDiam` "JOG MAX Ø (mm)" (0 = no limit, Format limits 0 / 150–1450),
   lamp `JogInhibit` "JOG BLOCKED – ROLL TOO BIG".

Notes
- DT35 fault (`RwSensFault`) -> jog allowed (diameter unknown, needed to thread).
- START (normal run) is not affected.
- Test: RwJogMaxDiam above the roll -> jog works; set it below the roll diameter ->
  jog does nothing, lamp ON; set 0 -> jog always allowed.
