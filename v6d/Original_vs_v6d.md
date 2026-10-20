# Original program vs modified (print 1019_1 + v6d)

- **Original:** `Slitter_Program_Original.pdf`, 33 pages, created 10/8/2026, Italian names.
- **Modified:** `Slitter_Program_1019_1.pdf` (47 pages, English names, AutoStop_Control v6c), with the corrections in `v6d/`.
- `Slitter_Program_1019_10.pdf` (a later version, 48 pages) is **not** covered here.

---

## 1. Logic that is identical (only names changed)
| Original section | Modified section | Result |
|---|---|---|
| Generale rungs 0–15 | General 0–15 | Identical. Start/stop latch of `CmdStartMotore` → `StartMotor_Cmd` (rungs 8/9) unchanged |
| GestioneMotore 0–2, 5–18 | Motor_Manager 0–2, 5–18 | Identical (speed loop, ramps, InvRef) |
| Pressore 0–5 | Under_Rider 0–5 | Identical |
| Pannello 0–2, 4–6 | Console 0–2, 4–6 | Identical |
| Allarmi 0–12, 14–20 | Alarms 0–11, 16–19, 22–25 | Identical |
| GestioneUscite 0–10, 12 | Output_Manager 0–10, 12 | Identical |

## 2. Logic that is different
| Where | Original | Modified (1019_1 / v6d) | Origin |
|---|---|---|---|
| General 16 | `VascaOffDiam` (tub off by diameter, `DiamVasvaOff`) | **Removed** (it was not used anywhere) | Your mod |
| Motor_Manager 3, slow-down | `I_RallEnd·I_FtRall` OR `MisuraOn·RallentaDiam` OR **`I_StopMetri · (mt ≥ MtRal)`**, a fixed metre point | Third branch → **`AutoSlowCmd`** (speed-compensated, rewinder diameter, max diameter) | Your mod |
| Motor_Manager 4, stop | paper break OR `MisuraOn·ArrestoDiam` OR **`I_StopMetri · (mt ≥ MtTot)`** | Third branch → **`AutoStopCmd`** | Your mod |
| Console 3, reset request | `I_StopMetri · (mt ≥ MtTot)` | `I_AutoStop_OS · UwStopEnable · (Current_Metre ≥ UwStop_At_Meter)` | Your mod |
| Alarms 13 | [11] tub-off photocell `I_FtVascaOff` (no I/O, never active) | [10] DT35 fault, [11] max diameter (rungs 12–15) | Your mod |
| Alarms 20–21 | — | [15] unwinder empty | Your mod |
| Alarms 10, encoder stopped | disabled by `P_Off` | **v6d C5: re-enabled** (NOT ManMode, InvRef > 200, 3 s) | v6d |
| Alarms, new | — | **v6d C2:** [16] learning fault. **C1:** [10] also while running. **C3:** [15] on `Measure_ON` | v6d |
| Alarms 0 / Output 7, buzzer and lamp | alarms 1–8 | **v6d C4:** + 10, 11, 15, 16 | v6d |
| Output 11, horn | guard open (blinking) OR **`Rallenta`** | guard open OR **`StartMotor_Cmd · SlowDown · NOT Stop`** | Machine builder 12/19/2024 |
| Output 13, guard bypass | `I_RipaClose` OR NOT `CmdStartMotore` OR **`I_ProtEsc`** OR `I_PuSlow` | NOT `StartMotor_Cmd` OR **TOF 100 ms(`I_LowSpd_OS`)**. The `I_FrontGuard_Closed` and `I_Prot_ByPass` branches are gone | Machine builder 12/19/2024 |
| AutoStop_Control | — | New section (v6d) | Your mod |

> ⚠ **Output rungs 11 and 13:** this "Original" print does **not** contain the machine builder's 12/19/2024 change (handover §3). So it is the older project file, **not** what is running in the PLC. The reference for the Offline Comparison must stay the **"Mono Canada II from PLC"** project.

### Behaviour changes the operators will notice
1. **Meter stop:** before, the 12SA5 selector (`I_StopMetri`) alone stopped the machine at `MtTot`. Now the HMI button **`UwStopEnable` must also be ON**, and its initial value is False. After the transfer, **the meter stop is OFF until someone turns it on on the HMI.**
2. **Slow-down by metres:** `MtRal` was an **absolute** metre count where the slow-down started. It is renamed `UwSlowMargin_m` and now means **metres at slow speed before the stop**. The PLC calculates the start point itself (`UwSlow_at_Metre`). The HMI label must change, and the old value (2) means something else now. Set it to 10.
3. **Horn:** it no longer sounds for a photocell slow-down while the machine is stopped, only while running and not stopping (machine builder).
4. **Rewinder diameter stop and max-diameter protection:** new.
5. **Alarm lamp and buzzer:** they now also react to alarms 10, 11, 15 and 16 (v6d).

---

## 3. Retained values lost by the rename
A retained variable that is renamed **comes up at its initial value** after the transfer. Read these in the **old project online** before the transfer, then enter them as initial values or set them online afterwards.

| Original (PLC) | Modified | Covered by v6d A2? |
|---|---|---|
| ImpEnc | Encoder_Pulse | ✓ 1000 |
| DiaRuota | EncoderWheel_Diam | ✓ 400 |
| MisuraNocciolo | UwCoreDistance | ✓ 785.56 |
| DiamAlbero | UwCoreDiameter | ✓ 101 |
| DiamRall | UwSlowDown_Diam | ✓ 200 |
| DiamStop | UwDiamStop | ✓ 110 |
| MtTot | UwStop_At_Meter | ✓ 5020 |
| MtRal | UwSlowMargin_m | ✓ 10 (new meaning) |
| TimStopVenP | Fan_Timeout | ✓ 0.5 |
| TimPosPresOnP / OffP | OverRider_TimeON / OFF | ✓ 0.05 / 0 |
| VelSetMan | JogSpd_SP | ✓ 10 |
| MisuraOn | Measure_ON | ✓ True |
| MemNocciolo | Core_Measure | ✓ False |
| ZM / FineR (locals) | DeadZone / Reading_Max | ✓ 60 / 2000 |
| **Aumenta / Diminuisci / AumentaH / DiminuisciH / PercDiff** | AccelTrim / DecelTrim / AccelCoarse / DecelCoarse / SpdDelta_Percent | ⚠ **No.** `IniRampe` → `Init_Ramp` is also renamed, so it restarts at False and rewrites the **defaults** (0.08 / 0.08 / 1 / 0.5 / 8). If the PLC holds tuned values, **record them** and re-enter them after the transfer. |
| **SetVelMan** | Speed_Man_SP | ⚠ No. Record it (HMI "% speed in manual") |
| **Lingua** | Language | ⚠ No (the HMI restores the language from RW-0, so this is probably harmless) |
| AnalRes | Analog_Res | OK, auto-set to 4000 |
| VelMax, ManMode, Psw | unchanged names | Value kept |

---

## 4. Published globals: rename map for the HMI (EasyBuilder Find/Replace Addr)
Every HMI address that uses a name in the left column must be changed **in the same session as the PLC transfer**.

| Original | Modified |
|---|---|
| Pot1_Lav | Pot1_Work_Velocity |
| Pot2_Fin | Pot2_Slow_Velocity |
| H_Range / L_Range | OverSpeed / UnderSpeed |
| PercDiff | SpdDelta_Percent |
| EncPos / EncOn / EncRset | Encoder_Pos / Encoder_On / Encoder_Reset |
| PagPann | HMI_Screen |
| Vel_mtmin | Velocity_M_min |
| mt | Current_Metre |
| VelVis / VelVisR | Speed_Display / LowSpd_Display |
| I_AuxOn | I_ControlVoltage |
| I_Marcia / I_Arresto | I_Start_PB / I_Stop_PB |
| I_PastTerm | I_Motor_Thermal |
| I_ProtEsc | I_Prot_ByPass |
| I_MozzoInPos | I_Hub_Position |
| I_RipaClose / I_RipaOpen | I_FrontGuard_Closed / I_FrontGuard_Open |
| I_PuSlow | I_LowSpd_OS |
| I_InvAll | I_VFD_Alarm |
| I_PorteClose | I_SafeGuard_Closed |
| I_DiamBob | I_OverRider_PH |
| I_PosPress / I_PresPress | I_OR_Position_Sens / I_OR_Pressure_Sens |
| I_PressAuto / I_PressCont | I_OR_Auto_OS / I_OR_Cont_OS |
| I_ThVentOk | I_FanTemp_Ok |
| I_StopMetri | I_AutoStop_OS |
| I_RallEnd | I_RollEnd_SlowDown |
| I_RotturaOn / I_FtRotto | I_WebBreak_Monitor / I_WebBreak_PH |
| I_ThAspira | I_Vacuum_OK |
| I_FtRall | I_SlowSens_PH |
| I_RotoloOk / I_FtEndBob | I_Roll_OK / I_RollEnd_PH |
| O_Motore | O_MotorStart |
| O_Allarme | O_Alarm_Array |
| O_ProtEscluse | O_Prot_ByPass_Lamp |
| O_L_MotOn | O_Motor_Lamp |
| O_OkScaricatori / O_OkScarIn | O_RwUnload / RwUnload_Enable |
| O_ByPassF | O_FrontGuard_ByPass |
| O_Freno | O_Brake |
| O_PressAuCo / O_PressUp / O_BlockPres | O_OR_Auto_Lamp / O_OverRider_Up / O_OverRider_Hold |
| O_Ventole | O_CoolingFan |
| O_SegnAcustico | O_AcousticSignal |
| TimStopVenP | Fan_Timeout |
| TimPosPresOnP / TimPosPresOffP | OverRider_TimeON / OverRider_TimeOFF |
| AllarmeOn | AlarmOn |
| Indice | Index_B |
| MotOnH | Run_Normal_Spd |
| SetVelMan / SetVelManR | Speed_Man_SP / LowSpd_Man_SP |
| H_RsetCnt | Counter_Reset |
| VelSetMan | JogSpd_SP |
| Aumenta / Diminuisci | AccelTrim / DecelTrim |
| AumentaH / DiminuisciH | AccelCoarse / DecelCoarse |
| MtTot / MtRal | UwStop_At_Meter / UwSlowMargin_m |
| ImpEnc | Encoder_Pulse |
| RicRsetCnt | CountReset_Req |
| Lingua | Language |
| DiaRuota | EncoderWheel_Diam |
| ProtEscH / RipaCloseH | SafeGuard_ByPass / FrontGuard_Closed |
| Misurato | UwDiam_Measure |
| DiamAlbero | UwCoreDiameter |
| MemNocciolo | Core_Measure |
| MisuraNocciolo | UwCoreDistance |
| AI_Misura | AI_Diam_Unwinder |
| MisuraOn | Measure_ON |
| DiamBobMis | UwDiam_Act |
| DiamRall / DiamStop | UwSlowDown_Diam / UwDiamStop |
| H_RsetAlarm | Alarm_Reset |

Unchanged: InvRef, Fix10Vdc, Fix10Vdc_1, VelMax, VelSet, PulseRate, I_RsetCnt, I_RsetAlarm, BuzzerOn, Msg, MotStop, Clock1s, ManMode, O_AccDec2, Psw, Psw22, Psw44, AlarmCodeSV, Anal3, Anal4.

### Removed from the global table (not in 1019_1)
`PulsPerOn`, `PulsPerRset`, `I_BarOk`, `O_PorteOpen`, `MotOnL`, `DiamVasvaOff`, `I_FtVascaOff`.
None of them is used in the logic. **But if any HMI object still points at one of them, the panel shows "Device No Response".** Search the `.cmtp` for each name and delete or re-point the object.
