# D903 main screen — object table (cMT2108X2, 1024 x 600)

Source: mock-up `D903_Main_EN.png` / `D903_Main_FR.png` (same folder).
All positions in pixels, from the top-left corner of the screen: **X, Y, W, H**.
The English layout is the master: French texts go in the same boxes (texts too long for a box are shortened below).
Work on a COPY of the project. Put the PNG on the bottom layer as a template (Picture object 0, 0, 1024, 600), place the objects, then delete the picture.

## 1. Colours (EasyBuilder RGB)

| Name | Use | RGB | Hex |
|---|---|---|---|
| BG | screen background | 230, 236, 240 | #E6ECF0 |
| HEAD | header band | 255, 255, 255 | #FFFFFF |
| MEAS | measured value box | 213, 221, 227 | #D5DDE3 |
| MEAS_BORDER | measured box border | 140, 155, 166 | #8C9BA6 |
| SP | set point box | 255, 255, 255 | #FFFFFF |
| SP_BORDER | set point box border | 31, 90, 150 | #1F5A96 |
| SP_TEXT | set point digits | 31, 78, 121 | #1F4E79 |
| OFF_BOX | set point that is OFF | 238, 241, 243 | #EEF1F3 |
| OFF_TEXT | dash / text on OFF box | 91, 102, 112 | #5B6670 |
| ON | toggle ON | 30, 123, 54 | #1E7B36 (white text) |
| OFF | toggle OFF | 195, 203, 210 | #C3CBD2 (text 31, 42, 51) |
| AMBER | manual / active / warning | 242, 178, 0 | #F2B200 (text 31, 26, 0) |
| AMBER_LIGHT | manual set point box | 255, 246, 214 | #FFF6D6 |
| RED | alarm bar | 183, 28, 28 | #B71C1C (white text) |
| RED_DARK | alarm reset button | 127, 16, 16 | #7F1010 (white text) |
| NAV | navigation buttons | 244, 246, 248 | #F4F6F8 (border MEAS_BORDER) |
| LABEL | small labels | 59, 71, 82 | #3B4752 |
| TEXT | digits / dark text | 17, 26, 34 | #111A22 |
| BAR | bar graph fill | 31, 90, 150 | #1F5A96 |
| BAR_TRACK | bar track in MEAS box / in SP box | 185, 196, 204 / 213, 221, 227 | #B9C4CC / #D5DDE3 |

Fonts: labels 12 px semibold, LABEL colour. Big values 48 px bold (left panel, metres), 44 px (speeds, slow-down, tension), 30 px (trim / manual SP), 18 px (thickness).
Bar graphs: 7 px high, inside the value box, 10 px in from left/right, 8 px above the bottom edge, no frame.

## 2. Header (Y 0..64, HEAD background, 2 px bottom line OFF colour)

| # | Object | X, Y, W, H | Address / action | Details | EN | FR |
|---|---|---|---|---|---|---|
| H1 | Picture | 20, 7, 56, 48 | — | your LM logo | | |
| H2 | Text | 94, 14, 420, 36 | — | 28 px, italic, semibold, TEXT | La Meccanica Fumagalli D903 | same |
| H3 | Set Word + frame lamp | 868, 9, 64, 44 | `Language` = your EN value | active: 3 px SP_BORDER frame, white; inactive: NAV, grey text | EN | EN |
| H4 | Set Word + frame lamp | 940, 9, 64, 44 | `Language` = your FR value | same | FR | FR |

## 3. Left panel: unwinder / rewinder

| # | Object | X, Y, W, H | Address | Details | EN | FR |
|---|---|---|---|---|---|---|
| L1 | Text | 20, 78, 179, 28 | — | 18 px extra-bold, centred, 2 px TEXT line under it | UNWINDER | DÉROULEUR |
| L2 | Text | 219, 78, 179, 28 | — | same | REWINDER | ENROULEUR |
| L3 | Line | 418, 78 → 418, 486 | — | 3 px, SP_BORDER | | |
| L4 | Text | 20, 123, 179, 15 | — | label | DIAMETER [mm] | DIAMÈTRE ACTUEL [mm] |
| L5 | Numeric (read only) | 20, 144, 179, 92 | `UwDiam_Act` | MEAS, 0 decimals, 48 px, right-aligned | | |
| L6 | Bar Graph | 30, 221, 159, 7 | `UwDiam_Act` | 0 .. your max unwinder diameter; target mark = `UwStopDiam_Limit` (black) | | |
| L7 | Text | 20, 254, 179, 15 | — | label | STOP LENGTH [m] | ARRÊT À [m] |
| L8 | Bit Lamp (background) | 20, 275, 179, 92 | `UwStopLenShow` | state 0: OFF_BOX, dashed border, text "—" OFF_TEXT; state 1: SP box | | |
| L9 | Numeric (input) | 20, 275, 179, 92 | `UwStop_at_M_Val` | transparent background, SP_TEXT, 0 decimals, 48 px; Visibility: `UwStopLenShow` = 1 | | |
| L10 | Bar Graph | 30, 352, 159, 7 | `UwStop_at_M_Val` | 0 .. your max length; Visibility: `UwStopLenShow` = 1 | | |
| L11 | Toggle Switch | 20, 422, 179, 64 | `UwStopEnable` | state 0 OFF, state 1 ON, 15 px bold, 2 lines | AUTO STOP / UNWINDER OFF·ON | ARRÊT AUTO / DÉROULEUR OFF·ON |
| L12 | Text | 219, 123, 179, 15 | — | label | DIAMETER [mm] | DIAMÈTRE ACTUEL [mm] |
| L13 | Numeric (read only) | 219, 144, 179, 92 | `RwDiam` | MEAS, 0 decimals, 48 px | | |
| L14 | Bar Graph | 229, 221, 159, 7 | `RwDiam` | 0 .. `RwMaxDiam` (dynamic limit); marks when `RwStopEnable`: amber `RwSlow_at_D_Val`, black `RwTargetDiam` | | |
| L15 | Text | 219, 254, 179, 15 | — | label | STOP DIAMETER [mm] | ARRÊT AU DIAMÈTRE [mm] |
| L16 | Bit Lamp (background) | 219, 275, 179, 92 | `RwStopEnable` | as L8 | | |
| L17 | Numeric (input) | 219, 275, 179, 92 | `RwTargetDiam` | as L9; Visibility: `RwStopEnable` = 1 | | |
| L18 | Bar Graph | 229, 352, 159, 7 | `RwTargetDiam` | 0 .. `RwMaxDiam`; Visibility: `RwStopEnable` = 1 | | |
| L19 | Toggle Switch | 219, 422, 179, 64 | `RwStopEnable` | as L11 | AUTO STOP / REWINDER OFF·ON | ARRÊT AUTO / ENROULEUR OFF·ON |

## 4. Right panel: speeds (row 1)

| # | Object | X, Y, W, H | Address | Details | EN | FR |
|---|---|---|---|---|---|---|
| R1 | Text | 442, 78, 130, 15 | — | label | FINAL SPEED [m/min] | VIT. FINALE [m/min] |
| R2 | Numeric (read only) | 442, 97, 130, 76 | `LowSpd_Display` | SP style (pot set point), 0 decimals, 44 px | | |
| R3 | Bar Graph | 452, 158, 110, 7 | `LowSpd_Display` | 0 .. `FinalSpd_Max` | | |
| R4 | Text | 584, 78, 130, 15 | — | label | SPEED [m/min] | VITESSE [m/min] |
| R5 | Numeric (read only) | 584, 97, 130, 76 | `Speed_Display` | as R2 | | |
| R6 | Bar Graph | 594, 158, 110, 7 | `Speed_Display` | 0 .. `WorkSpd_Max` | | |
| R7 | your SOFT STOP button + Bit Lamp | 726, 97, 76, 76 | action unchanged; lamp `SoftStop` | state 0 NAV; state 1 AMBER + "ACTIVE" | SOFT / STOP | ARRÊT / DOUX |
| R8 | Text | 814, 78, 190, 15 | — | label | ACTUAL SPEED [m/min] | VITESSE ACTUELLE [m/min] |
| R9 | Numeric (read only) | 814, 97, 190, 76 | `Velocity_M_min` | MEAS, 0 decimals, 44 px | | |
| R10 | Bar Graph | 824, 158, 170, 7 | `Velocity_M_min` | 0 .. `VelMax`; target mark = `Speed_Display` | | |

## 5. Right panel: slow-down / JOG / tension (row 2)

| # | Object | X, Y, W, H | Address | Details | EN | FR |
|---|---|---|---|---|---|---|
| R11 | Word Lamp (text only) | 442, 221, 172, 15 | `SlowAtMode` | 0: AUTO STOP OFF, 1: SLOW DOWN AT [m], 2: SLOW DOWN AT [mm] | (states) | 0: ARRÊT AUTO OFF, 1: RALENTIT À [m], 2: RALENTIT À [mm] |
| R12 | Numeric (read only) | 442, 240, 172, 92 | `SlowAtDisp` | MEAS, 0 decimals, 44 px; Visibility: `SlowAtShow` = 1 | | |
| R13 | Bar Graph (metres) | 452, 317, 152, 7 | `SlowAtDisp` | 0 .. `UwStop_at_M_Val`; Visibility: `SlowAtMode` = 1 | | |
| R14 | Bar Graph (mm) | 452, 317, 152, 7 | `SlowAtDisp` | 0 .. `RwTargetDiam`; Visibility: `SlowAtMode` = 2 | | |
| R15 | your JOG BOOST button + Bit Lamp | 626, 240, 76, 92 | action unchanged; lamp `TensJogLatch` | state 0 NAV; state 1 AMBER + "ACTIVE" | JOG / BOOST | JOG / BOOST |
| R16 | Text | 714, 221, 118, 15 | — | label | TENSION SP [kg] | TENSION [kg] |
| R17 | Numeric (read only) | 714, 240, 118, 92 | `TensSet_kg` | MEAS, 0 decimals, 44 px | | |
| R18 | Bar Graph | 724, 317, 98, 7 | `TensSet_kg` | 0 .. `TensMax_kg` | | |
| R19 | Bit Lamp (text only) | 844, 206, 96, 30 | `TensAuto` | state 1: TRIM [kg] green bold; state 0: MANUAL SP [kg] amber-dark bold (2 lines allowed) | TRIM [kg] / MANUAL SP [kg] | AJUST. [kg] / CONSIGNE MANUELLE [kg] |
| R20 | Bit Lamp (background) | 844, 240, 96, 92 | `TensAuto` | state 1: SP box; state 0: AMBER_LIGHT, 2 px AMBER border | | |
| R21 | Bit Lamp "+" | 852, 266, 18, 36 | `TensTrimPos` | no shape; state 0 blank, state 1 "+"; 30 px bold SP_TEXT; Visibility `TensAuto` = 1 | | |
| R22 | Numeric (display) | 870, 256, 64, 56 | `TensTrim_kg` | Left of decimal 3, Right 1, LEFT-aligned, 30 px bold, transparent; Visibility `TensAuto` = 1 | | |
| R23 | Numeric (display) | 852, 256, 82, 56 | `TensManual_kg` | 1 decimal, right-aligned, 30 px bold; Visibility `TensAuto` = 0 | | |
| R24 | Bar Graph (trim) | 852, 317, 80, 7 | `TensTrim_kg` | −20 .. +20 from the centre (origin 0) if your version has it, else two bars (0..+20 right half, 0..−20 left half reversed); green; Visibility `TensAuto` = 1 | | |
| R25 | Bar Graph (manual) | 852, 317, 80, 7 | `TensManual_kg` | 0 .. 100, fill 122, 90, 0 on track 243, 227, 166; Visibility `TensAuto` = 0 | | |
| R26 | Function Key ▲ (macro `Tens_Up`) | 948, 240, 56, 43 | macro | two keys on the same spot: green (Visibility `TensAuto` = 1), amber (`TensAuto` = 0); white / dark arrow | | |
| R27 | Function Key ▼ (macro `Tens_Dn`) | 948, 289, 56, 43 | macro | as R26 | | |

## 6. Right panel: metres (row 3)

| # | Object | X, Y, W, H | Address | Details | EN | FR |
|---|---|---|---|---|---|---|
| R28 | Text | 442, 383, 200, 15 | — | label | ACTUAL METRES [m] | MÈTRES ACTUELS [m] |
| R29 | Numeric (read only) | 442, 402, 200, 84 | `Current_Metre` | MEAS, 1 decimal, 48 px, NO bar | | |
| R30 | Word Lamp (text only) | 661, 379, 83, 23 | `CntResetMode` | 10 px bold, 2 lines; 1: RESET AT START / NEW ROLL, 2: RESET AT START / AFTER AUTO STOP, 4: MANUAL RESET | (states) | 1: RAZ AU DÉPART / NOUV. BOBINE, 2: RAZ AU DÉPART / APRÈS ARRÊT AUTO, 4: REMISE À ZÉRO MANUELLE |
| R31 | your eraser button | 662, 406, 80, 80 | action unchanged (`Counter_Reset`) | NAV | | |
| R32 | Bit Lamp (frame, blink) | 662, 406, 80, 80 | `CntResetPend` | state 1: 3 px AMBER frame + AMBER_LIGHT fill, blinking; state 0: invisible; behind R31 | | |
| R33 | Text | 762, 402, 90, 28 | — | label 11 px | THICKNESS [mm] | ÉPAISSEUR [mm] |
| R34 | Numeric (read only) | 762, 434, 90, 52 | `RwThick_mm` | MEAS, 3 decimals, 18 px, NO bar | | |
| R35 | your GSM OK button | 864, 402, 64, 84 | action unchanged | NAV, 12 px bold | GSM / OK | GSM / OK |
| R36 | your NEW GSM button | 940, 402, 64, 84 | action unchanged | NAV, 12 px bold | NEW / GSM | NOUV. / GSM |

## 7. Mode row (Y 496, H 46)

| # | Object | X, Y, W, H | Address | Details | EN | FR |
|---|---|---|---|---|---|---|
| B1 | Bit Lamp (status, not a button) | 20, 496, 142, 46 | `I_AutoStop_OS` | white, 2 px OFF border; dot 32, 511, 16, 16: state 0 OFF grey, state 1 ON green; 12 px bold | AUTO STOP / SELECTOR ON·OFF | SÉLECTEUR / ARRÊT AUTO ON·OFF |
| B2 | Toggle Switch | 170, 496, 130, 46 | `FFEnable` | OFF / ON colours | AUTO SPEED / CONTROL OFF·ON | VITESSE / AUTO OFF·ON |
| B3 | Toggle Switch | 309, 496, 130, 46 | `Measure_ON` | OFF / ON | SONAR / OFF·ON | SONAR / OFF·ON |
| B4 | Toggle Switch | 447, 496, 130, 46 | `TensAuto` | state 0 AMBER "MANUAL", state 1 ON green "AUTO" | TENSION / MANUAL·AUTO | TENSION / MANUELLE·AUTO |
| B5 | your I/O STATUS button | 585, 496, 134, 46 | unchanged | NAV | I/O STATUS | ÉTAT E/S |
| B6 | your RUN SETUP button | 727, 496, 134, 46 | unchanged | NAV | RUN SETUP | RÉGLAGES / MARCHE |
| B7 | your STOP SETUP button | 870, 496, 134, 46 | unchanged | NAV | STOP SETUP | RÉGLAGES / ARRÊT |

## 8. Alarm / warning bar (Y 550, H 42)

| # | Object | X, Y, W, H | Address | Details |
|---|---|---|---|---|
| A1 | Bit Lamp (background, warning) | 20, 550, 804, 42 | `WarningOn` | state 1 AMBER, state 0 invisible |
| A2 | Bit Lamp (background, alarm) | 20, 550, 804, 42 | `AlarmOn` | state 1 RED, state 0 invisible; ABOVE A1 (alarm wins) |
| A3 | your message display | 64, 550, 680, 42 | `Msg` (as today) | NOT scrolling; 19 px extra-bold; text colour dark on amber / white on red (two copies with Visibility `AlarmOn` = 0 / 1 if the object has one colour) |
| A4 | your time display | 744, 550, 72, 42 | as today | 15 px, right-aligned |
| A5 | your ALARM RESET button | 832, 550, 172, 42 | `Alarm_Reset` (as today) | with `AlarmOn` = 1: RED_DARK, "ALARM RESET" / "RÉARMER ALARMES"; with `AlarmOn` = 0 and `WarningOn` = 1: white, 2 px AMBER frame, "WARNING" / "AVERTISSEMENT" |

Rule: the colour of the bar and of A5 follows `AlarmOn` / `WarningOn` only, never the language.

## 9. To check before building
- Max unwinder diameter (L6) and max stop length (L10): no PLC tag, give a constant.
- `Language` values for EN / FR (H3, H4).
- Bar Graph target mark (L6, L14, R10) and centre origin (R24): use them if EasyBuilder 6.10 offers them on the Bar Graph object; otherwise leave the marks out.
