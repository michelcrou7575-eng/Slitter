# V7 load plan: Sysmac Studio licence ends in 9 days (from 10/29/2026)

After the licence ends: no program change, no transfer, **no Watch tab, no Data Trace**. Only the HMI (and SoMove for the drive) remain. So everything must be loaded, tested and backed up before, and every setting needed later must be on the HMI.

## Day 1–2: load (send the PDF first, I check it)
Base print 1028_2. In this order, F7 = 0 errors after each:
1. **v6y** variables + Motor_Manager rungs 5/6/7/8 (`v6y/v6y_Changes.md`).
2. **V7** variables, new Motor_Manager rung after rung 14, rung 5 clamps, `V7/AutoStop_Control_V7.st` (contains v6y) (`V7/V7_Changes.md`).
3. Optional **v6q** S-curve start rung (after the V7 rung) + `SoftStartTime`.
4. Update the Initial Values of the Retain globals to the current settings (v6q part B list + `RwDist10V`, `RwAxisDist`).
5. Transfer. Upload the new PDF to GitHub.

## Day 3–6: tests on scrap rolls (Data Trace + SoMove scope while Sysmac still works)
- Auto slow-down + stop on a small roll (100 → 300 mm) and on a big roll: web decel ≈ `DecelWeb`, final speed reached just before the target.
- `RwRatioD` stays ≈ 2700–2900 (Watch).
- Rewinder AUTO limit 500 m/min, change while running → applied at the next stop.
- Soft stop from 400 / 500 m/min with VBUS on the scope; immediate stop from 400 / 500 m/min.
- Paper thickness: `ThickWin_mm` stable at low and high speed; NEW PAPER; GSM popup.
- Alarm 16: ALARM RESET clears it.

## Day 7: corrections (if any), new PDF, my check, transfer.

## Day 8: backups
- Sysmac: **save the project (.smc2)**, Export the global variables, **Tools → Backup → Variables backup** (Retain values) to a file.
- **SD-card backup of the controller** (Controller → SD Memory Card → backup) → full restore possible later **without** Sysmac Studio (NX1P2 SD backup / restore by DIP switch).
- SoMove: drive configuration .psx + export.
- EasyBuilder: project .emtp/.cmtp + downloaded copy.
- Copy everything to GitHub (except passwords).

## HMI: everything needed after the licence ends
Settings that must be on an HMI page (password):
`DecelWeb`, `AccelWeb`, `SoftStopDecel`, `SoftStopEndSpd`, `SpdDelta_Percent`, `AccelTrim`, `DecelTrim`, `RwAutoMaxSpd`, `RwTreact`, `RwMinLearnSpd`, `RwWinGrow_mm`, `RwWinLen_m`, `RwMatChangePct`, `RwSlowFallbackMm`, `RwThickMin_mm`, `RwThickMax_mm`, `RwSlowMargin_m`, `RwTrim`, `RwMaxDiam`, `RwMaxSlowFallback`, `RwDist0V`, `RwDist10V`.
Buttons: `RwLearnReset` (Set ON, "RESET DECEL LEARNING"), NEW PAPER (`RwMatReset`, momentary 3 s).
Displays (diagnosis without Sysmac): `RwRatioD`, `RwStopDecelK`, `RwSlowDecelK`, `RwThick_mm`, `GSM_Learned_OK`, `PulseRate`, `InvRef`, `AI_Diam_Rewinder`, `AI_Diam_Unwinder`.
Program locals (`StopFailCnt`, `LearnFailCnt`, `ThickWin_mm`, `Decel_Ramp`) cannot be shown on the HMI; alarm 16 + ALARM RESET replace them.
