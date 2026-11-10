# Tension Manager (on top of V12_1106_6) — T-one remote set point from the PLC

The PLC computes the T-one tension set point from **paper GSM × roll width × paper type (kraft / bleached)**,
with a **core boost** and a **taper** on the rewinder diameter, and sends it on **AO Ch1** (0–10 V) to the T-one
remote set point input. AO Ch1 was `Fix10Vdc` (fixed 10 V, supply of the speed potentiometers).

## 0. Order of work (important)
1. Load the PLC part with **`TensAOEnable` = FALSE**: AO Ch1 stays at a fixed 10 V (as before) → nothing changes on the machine.
2. Wire an **external regulated 10 V** (24 V → 10 V DIN module, ±0.5 %) to the two speed pots; its **0 V to the PLC analog input common**.
   Check: `Pot1_Work_Velocity` / `Pot2_Slow_Velocity` ≈ 4000 at full scale, speeds as before.
3. Disconnect the pots from AO Ch1. Wire **AO Ch1 → 0–10 V signal isolator → T-one pin 20 (+) / 19 (−)**.
4. T-one (password): **F.37 = 1**, **F.38** with 1 V (PLC: `TensManual_kg` = `TensMin_kg`, AUTO OFF, `TensAOEnable` ON),
   **F.39** with 10 V (`TensManual_kg` = `TensMax_kg`). Manual p. 13 / 26. ΔV must be > 3 V (here 9 V).
5. Tests (§5), then `TensAuto` ON.

## 1. Variables
- **Rename global** `Fix10Vdc` → **`AO_TOne_SetPoint`** (INT, same AT `BuiltInIO://opt/#0/Ch1_Analog_Output_Value`).
- **Global Variables:** paste `TensionManager_Globals_paste.txt` (19 lines, Publish Only; settings Retain).
- **TaglMonoTRM Externals:** add the new globals + `AO_TOne_SetPoint`, `RwDiam`, `RwCoreDiameter`, `RwMaxDiam`, `RwSensFault` if missing.
- **TaglMonoTRM Internals:** paste `TensionManager_Internals_paste.txt` (`TensTarget`, `TensStep`, `TensAOReal`, `TensGSMMem`, `TensWidthMem`, `TensKraftMem`).
  Already existing: `TensIdeal_N`; globals `PaperGSM`, `WebWidth_mm`, `TensFactor`, `TensIdeal_Disp` (now always kg).
  **kg only:** `TensUnit`, `TensUnitPB`, `TensUnitMem`, `TensShowKg/Lb/N` are no longer used → delete them (and the HMI UNITS button) after Cross Reference.
  Also uses `JogRun`, `StartPB_OK`, `StartBlocked` (General rung 7).

## 2. Program
| Step | Where | Action |
|---|---|---|
| 2a | Section `Tension_Helper` | rename to **`Tension_Manager`** |
| 2b | Tension_Manager rung 0 | **replace all the code** with `TensionManager_rung0.st` |
| 2c | General rung 6 ("10 V DC source") | **delete** the line `Fix10Vdc := INT#4000;` (Tension Manager writes AO Ch1 now) |

Build → 0 errors.

## 3. HMI
**Tension Helper popup (operator):** add a two-state switch **KRAFT / BLEACHED** on `PaperKraft` (OFF = BLEACHED),
and a display **T-one SET POINT** (`TensSet_kg`, #.#) + a button **TENSION SETUP** (visible / enabled with the
maintenance password bit, e.g. `Psw44`) that opens the new popup.

**New popup "TENSION SETUP" (maintenance only):**
| Object | Address | Range / format |
|---|---|---|
| Toggle AUTO TENSION | `TensAuto` | |
| Toggle AO → T-one ENABLE | `TensAOEnable` | maintenance only, see §0 |
| Slide switch TAPER % | `TensTaper` | 0–60, step 5 |
| Slide switch CORE BOOST % | `TensCoreBoost` | 0–50, step 5 |
| Slide switch MANUAL kg | `TensManual_kg` | 10–100, step 1 (interlock: active when `TensAuto` OFF) |
| Slide switch RATE kg/s | `TensRate_kg_s` | 1–20, step 1 |
| Numeric input FACTOR BLEACHED / KRAFT | `TensFactorBleached` / `TensFactorKraft` | 0.30–1.20, #.## |
| Numeric input MIN kg / MAX kg | `TensMin_kg` / `TensMax_kg` | keypad (= T-one F.38 / F.39) |
| Displays | `TensSet_kg`, `TensIdeal_Disp`, `RwDiam`, `TensAtCore`, `TensAtMid`, `TensAtMax` | #.# |
| Bar graph | `TensDiaFrac` | 0–1 |
If the EBPro Slide Switch does not offer 32-bit Float, use numeric inputs instead (or ask for INT versions of these tags).

## 4. Behaviour
- Set point = Helper kg × (1 + CoreBoost %) × (1 − Taper % × diameter fraction), limited to `TensMin_kg`..`TensMax_kg`.
- Changes (GSM, width, paper type, AUTO / manual) ramp at `TensRate_kg_s` (default 5 kg/s): no tension jump while running.
- DT35 fault → no taper (core value). AUTO OFF → `TensManual_kg`.
- AO: 1 V = `TensMin_kg`, 10 V = `TensMax_kg`; a broken wire (0 V) is below the calibrated range.
- Example 100 g/m², 680 mm, bleached (Helper ≈ 37 kg), boost 15 %, taper 30 %: core 43 kg → 500 mm 39 kg → 1000 mm 35 kg → max 30 kg.
- Kraft factor 0.80 is a starting value: tune on roll quality.

## 5. Tests
1. `TensAOEnable` OFF: AO Ch1 = 4000 (10 V), pots / speeds unchanged; Helper value as before (bleached).
2. KRAFT ON: Helper value × 0.80/0.54.
3. After the hardware change, `TensAOEnable` ON, AUTO OFF, `TensManual_kg` 40 → meter on AO Ch1:
   1 + 9 × (40 − 10)/(100 − 10) = **4.0 V**; T-one set point 40 kg.
4. `TensManual_kg` 40 → 60: the T-one set point ramps at 5 kg/s.
5. AO wire disconnected: note what the T-one does (should hold its minimum).
6. AUTO ON on a real roll: set point follows diameter; check the coupling knocking (core boost) and the roll quality.

## 6. Operator trim and threading preset (main page)
| Object | Address | Note |
|---|---|---|
| Display TENSION SP | `TensSet_kg` | `###.#` — value sent to the T-one (taper, trim, JOG boost included) |
| ▲ / ▼ | Function Keys → macros `Tens_Up` / `Tens_Dn` (`HMI_Macros_Tens_Up_Dn.md`) | AUTO: trim ±1 kg (max ±10, back to 0 when GSM / width / paper type changes); MANUAL: `TensManual_kg` ±1 |
| Lamp JOG BOOST | `TensJogLatch` | ON from the first JOG until START is accepted |
| Paper popup: JOG TENSION BOOST % | `TensJogBoost` | default 30 % |

- JOG → set point × (1 + `TensJogBoost` %), taper still active; START accepted → back to normal, ramped at `TensRate_kg_s`.
- At **standstill** the T-one is in STOP (pin 13 = `O_Brake` off) and applies **F.1** (torque when stationary), not the set point:
  for knife adjustment with the machine stopped, raise F.1 if the web is too slack.

Tests: JOG → lamp ON, TENSION SP +30 %; START → lamp OFF, SP ramps down; ▲ ×3 in AUTO → +3 kg; change GSM → trim back to 0.
