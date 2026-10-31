# V10 package (10/31) — on top of the printed V9 (`Slitter_1030_V9_compressed.pdf`)

| # | Change | Why |
|---|---|---|
| 1 | General rung 11: delete the leftover `I_Start_PB` NC | START held while releasing JOG did not stop → run-up to work speed |
| 2 | **`JogRun`** = JOG really running (`I_Jog_PB AND NOT Slow_Inhibit AND NOT SoftStop`) instead of the raw button | Holding JOG during a normal run **bypassed the guards** (OUT4 → 23KA4, in parallel with key 5SA1 "SAFETY BYPASS"), switched the drive to its 2nd ramp, dropped the feed-forward, froze the pot |
| 3 | Thickness long baseline restarts if the encoder goes 2 m back | A short metre-counter reset (< 100 ms) could corrupt — and lock — the thickness |
| 4 | Sonar OFF popup (`SonarAsk` / `SonarAskYes`) | At power-up and after each stop while the sonar is OFF |
| 5 | Repo files renamed `I_LowSpd_OS` → `I_Jog_PB` (V9 + V10) | Match your program |

Rung numbers below = printed V9.

## 1. Variables
- **Global Variables + TaglMonoTRM Externals:** `V10_Globals_paste.txt` (`SonarAsk`, `SonarAskYes`).
- **TaglMonoTRM Internals:** `V10_Internals_paste.txt` (`SonarRunMem`, `SonarInit`, `JogRun`).

## 2. General
| Rung | Action |
|---|---|
| 7 "START blocked by JOG" (ST) | replace all with `General_rung7_startblock_V10.st` (adds the `JogRun` line at the end) |
| 11 "Main Motor stop", JOG-release branch `I_Jog_PB↓ — Slow_Inhibit(NC) — I_Start_PB(NC) — StartPB_OK(NC)` | **delete `I_Start_PB` (NC)** → `I_Jog_PB↓ — Slow_Inhibit(NC) — StartPB_OK(NC)` |
Not changed: rung 9 (JOG start branch keeps `I_Jog_PB`, `Slow_Inhibit` NC, `I_Start_PB` NC, `JogInhibit` NC),
rung 10 soft stop (`OR I_Jog_PB`: STOP with JOG held = immediate stop).

## 3. Motor_Manager
| Rung | Action |
|---|---|
| 8 "Updating potentiometer value" | contact `I_Jog_PB` (NC) → **`JogRun` (NC)** |
| 14 "Ratio drive counts…" (ST) | replace all with `MotorManager_rungA_V10.st` |
| 17 "Slow adaptation of RwRatioD…" (ST) | replace all with `MotorManager_rungB_V10.st` |
Not changed: rung 4 (paper-break stop, `I_Jog_PB` NC), rung 9 and 20 (jog speed: already `I_Jog_PB` + `Slow_Inhibit` NC), rung 19.

## 4. AutoStop_Control
- Rung 0: replace all with `AutoStop_Control_V10_part1_rung0.st` (477 lines).
- Rung 1: replace all with `AutoStop_Control_V10_part2_rung1.st` (542 lines, sonar popup after the `GsmAskYes` block).

## 5. Output_Manager
| Rung | Action |
|---|---|
| 12 "Second acc/dec ramp" | contact `I_Jog_PB` → **`JogRun`** (ManMode branch unchanged) |
| 13 "Front guard bypass" | TOF `T_ByPassProtOff` input contact `I_Jog_PB` → **`JogRun`** |
Not changed: rung 9 (unloaders, `I_Jog_PB` NC).

## 6. HMI
- Sonar popup window: Direct Window on bit **`SonarAsk`** (ON = open). NO button: `SonarAsk` Set OFF.
  YES button: `SonarAskYes` Set ON (PLC resets it). Text: "UNWINDER DIAMETER SENSOR – SONAR IS OFF! TURN IT ON?"

## 7. Build → 0 errors, download, tests
1. **JOG at standstill:** works as before; front guard bypass ON while JOG held (as before).
2. **JOG during a normal run (e.g. 200 m/min):** `JogRun` = 0, `O_FrontGuard_ByPass` stays **OFF**,
   `O_AccDec2` stays OFF, speed unchanged (feed-forward stays active).
3. **JOG during a soft stop:** `JogRun` = 0 (no bypass); STOP with JOG held still = immediate stop.
4. **Hold JOG, press and HOLD START, release JOG** → the motor **stops**.
5. **Sonar OFF** (button), stop the machine → popup; NO → closes, comes back after the next stop;
   YES → `Measure_ON` = 1. Never while running. Power-up with sonar OFF → popup.
6. Thickness: metre-counter reset during a rewind (machine stopped) → `LongThick_mm` restarts (no jump).

## Still open (not in V10)
- After STOP, `O_FrontGuard_ByPass` turns ON as soon as `StartMotor_Cmd` drops (machine builder logic),
  while the rewinder may still be ramping down. Option: bypass only below ~2 m/min. Ask if wanted.
- `RwLockDiam` 250 for 100 → 300 orders; initial values `RwMinLearnSpd` / `RwTreact` (see review).
- T-one password / PID; low-tension warning (extra NX input).
