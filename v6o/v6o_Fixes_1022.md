# v6o: corrections after reviewing print 1022 (project "Mod 1021_1")

## Status of print 1022
| Item | Status |
|---|---|
| AutoStop_Control = v6l (sections 5b, 5c, 13, 14, 14b, 14c) | OK |
| v6m General rung 9 (soft stop ST) + rung 10 `StopNow` | OK |
| v6m Motor_Manager rung 8 (`VelSet := 0` on SoftStop) + rung 15 (SoftStopDecel) | OK |
| v6n Motor_Manager rung 6 (`_Set` → active only when stopped) | OK |
| Globals v6i–v6n (initial values, Retain, Publish Only) | OK |
| Output_Manager rung 7 alarm lamp (alarms 10, 11, 15, 16) | OK (fixed since 1019_10) |
| **Motor_Manager rung 17: auto speed loop output overwritten** | **❌ CRITICAL: fix 1** |
| **Motor_Manager rung 18 (ManMode): no soft stop** | ❌ fix 1 |
| **Output_Manager rung 2: `BrakeHold` missing** | ❌ fix 2 |
| **General rung 16 (old single-reading core teach) still present** | ❌ fix 3 |
| Motor_Manager rung 7 ELSE (ManMode % display) still on Pot_Mem | ⚠ fix 4 |
| PLC decel ramp faster than the drive → reference wind-up / undershoot | ➕ fix 5 (new) |
| `UwCoreDiameter` initial value 100 (field value 101?) | ⚠ check |
| Local `TESTBOOL` (NC contact in Console rung 4) | ℹ harmless while FALSE, can be deleted |

---

## Fix 1 (CRITICAL): Motor_Manager rungs 17 and 18
**Cause:** the v6m sheet said "rung 17 (ManMode)", which was the numbering in print 1019_10. Inserting the new rung 15 (SoftStopDecel) moved every later rung down by one. The ST therefore went into the **auto** rung (contact `ManMode` **NC**) instead of the manual rung.

**Effect in AUTO:** the closed loop (`Vfd_SP_Modif`) no longer drives the drive. `InvRef` = **raw** pot:
- Work pot at maximum = **800 m/min** (`WorkSpd_Max` 400 ignored).
- After slow-down: raw Final pot = up to **800 m/min** instead of 0–40.
- Auto slow-down / stop lengths are computed for a speed that is not the real one.

→ **Do not run in AUTO with 1021_1 until this is fixed.**

### Rung 17 ("Management of the inverter speed reference…", contact `ManMode` NC): restore the original
```
//InvRef2 := REAL_TO_UINT((Vel_Max_mms - Vfd_SP_Modif ) / Output_Ratio);
//InvRefWW := UINT_TO_WORD(InvRef2);
//InvRefSW :=Swap(UINT_TO_WORD(InvRef2));
//InvRef := WORD_TO_UINT(InvRefSW);
InvRef := REAL_TO_INT((Vel_Max_mms - Vfd_SP_Modif ) / Output_Ratio);
```
(Soft stop in auto needs nothing here: rung 8 sets `VelSet := 0` and the speed loop brings the speed down.)

### Rung 18 ("Updating potentiometer value", contact `ManMode` **NO**, `I_LowSpd_OS` NC): soft stop goes here
```
IF SoftStop THEN
    InvRef := INT#0;                                // v6m: drive ramps down on its own
ELSIF SlowDown = FALSE THEN
    InvRef := Pot1_Work_Velocity;
ELSE
    InvRef := Pot2_Slow_Velocity;
END_IF;
```

## Fix 2: Output_Manager rung 2 (v6h BrakeHold)
Section 13 calculates `BrakeHold`, but rung 2 is still `Brake_Cmd → O_Brake`. So on every immediate stop (2nd STOP press, STOP held 1 s, auto stop, paper break) the T-one still goes to "stop" with the run command. The web then falls on the floor as before.

Add a **NO contact `BrakeHold` in parallel** with `Brake_Cmd`:
```
 Brake_Cmd                     O_Brake
──┤ ├──┬──────────────────────( )──
 BrakeHold │
──┤ ├──┘
```

## Fix 3: General rung 16: DELETE it
`Core_Measure → MOVE UwDiam_Measure → UwCoreDistance → T_CoreMemDelay 250 ms → Reset Core_Measure`
(it was rung 15 in the v6k sheet; it became 16 after the v6m insertion).

While it remains:
- TEACH stores **one** sonar reading immediately.
- `Core_Measure` is reset after 250 ms, so section 14b never reaches 20 samples. `UwTeachState` stays at 1 (TEACHING), and `UwCoreDist_Prev` is not saved, so UNDO does not restore the right value.

`T_CoreMemDelay` can then be deleted from the internals.

## Fix 4 (display only): Motor_Manager rung 7, ELSE branch (ManMode)
With v6i, `Pot1_Mem` / `Pot2_Mem` are scaled. In manual the % display is therefore wrong: full pot shows 50 % (Work) and 5 % (Final). Use the raw pots:
```
ELSE;
    Speed_Display := Pot1_Work_Velocity / (Analog_Res / UINT#40); // v6i: raw pot, %
    LowSpd_Display := Pot2_Slow_Velocity / (Analog_Res / UINT#40);
```

## Fix 5 (new): PLC decel ramp limited to what the drive can really do (anti wind-up)
**Why:** `DecelCoarse` 0.5 = 125 mm/s². With a small rewinder roll the drive (Hz/s ramp, no braking resistor) only gives about K × D (≈ 22 mm/s² at 150 mm, 90 at 600 mm). The PLC keeps lowering `Vfd_SP_Modif` every 4 ms, so the reference runs far below the real web speed, sometimes down to 0. When the speed reaches the ±8 m/min band, the web undershoots the final speed and the loop has to accelerate again. Stops can also come "too early".

**Where:** new inline-ST rung **between "Optional faster decel" (v6m soft stop decel) and "Speed correction factor calculation"**. That is rung 15/16 in print 1022, so the new rung becomes 16 and "Speed correction…" becomes 17. Rungs are named here by their **comment**, because the numbers shift every time a rung is inserted.

Comment: `v6o: decel ramp limited to the learned drive decel`
```
// v6o: never ask more decel than the drive can give (anti wind-up).
// RwSlowDecelLrn = RwSlowDecelK x rewinder diameter (mm/s2), AutoStop section 5c.
// 1.25 margin: the measured decel can still grow, so the learning never only ratchets down.
IF RwSlowDecelLrn > 0.0 THEN
    IF Decel_Ramp > RwSlowDecelLrn * 1.25 / 250.0 THEN
        Decel_Ramp := RwSlowDecelLrn * 1.25 / 250.0;   // 1 = 250 mm/s2 (4 ms task)
    END_IF;
END_IF;
```
- Variables: none new (`RwSlowDecelLrn` is already in the Externals, `Decel_Ramp` is local).
- `RwSlowDecelLrn` = 0 (not learned) → no limit, same as before.
- It applies in AUTO only (the speed loop rungs). Manual mode drives the inverter directly.
- It also limits `SoftStopDecel` and `DecelTrim`, which is correct: the drive can't do more anyway.
- **Why × 1.25:** with an exact limit, a measured slow-down could never be faster than the learned value, so K could only go down. With 25 % headroom the learning can still climb to the real drive value.

**Expected result:** smooth slow-down down to final speed with no dip below it, a slow-down length closer to the calculated one, and more stable learning of `RwSlowDecelK` / `RwStopDecelK`.


## Fix 5b (10/27/2026): soft stop not limited by fix 5
**Field:** normal AUTO run at 50 m/min, STOP → `VelSet` = 0, but the decel takes very long.
**Cause:** fix 5 limits **every** PLC decel in AUTO to `RwSlowDecelLrn` × 1.25 (K × diameter). On a small roll that is 20–30 mm/s² → 50 → 5 m/min takes 30–40 s.
For a soft stop the target is **0**: there is no final speed to undershoot, so the wind-up protection is not needed.

Motor_Manager, rung "v6o: Decel ramp limited to the learned drive decel": add `AND NOT SoftStop` to the first IF:
```
IF (RwSlowDecelLrn > 0.0) AND NOT SoftStop THEN
    IF Decel_Ramp > RwSlowDecelLrn * 1.25 / 250.0 THEN
        Decel_Ramp := RwSlowDecelLrn * 1.25 / 250.0;
    END_IF;
END_IF;
```
Soft stop then decelerates with `DecelCoarse` (125 mm/s² → 50 → 5 m/min in about 8 s), or `SoftStopDecel` if > 0, limited only by the drive. To make it gentler: `SoftStopDecel` = e.g. 60 mm/s².

## Check
`UwCoreDiameter` initial value = **100** in Globals. If the real unwinder core OD is 101 mm, enter it (Retain, Watch tab or HMI page 44).

---

## Order
1. Fix 1 + 2 + 3 + 5 (+ 4) → F7 = 0 errors.
2. Before the transfer: record the Retain values (`Pre_Transfer_Values.md`). No variable is new or renamed, so a normal transfer keeps them.
3. Transfer → tests.

## Tests
1. **AUTO**, Work pot at maximum → `Velocity_M_min` ≈ **400** (not 800), and the speed holds (closed loop).
2. Auto slow-down → final speed ≤ 40 m/min.
3. STOP once at 200 m/min (auto) → smooth soft stop, as in the v6m test.
4. **MANUAL**: STOP once → `InvRef` = 0, the drive decelerates on its ramp; the % display = 100 % at full pot.
5. Immediate stop at speed (STOP held 1 s): `O_Brake` stays ON until < 5 m/min (or 15 s) → the web stays tight.
6. Unwinder TEACH CORE (machine stopped): TEACHING about 2 s → DONE; `UwCoreDist_Prev` = old value; UNDO → RESTORED.
7. **Fix 5:** auto slow-down on a small roll (< 400 mm), Watch `Velocity_M_min` and `Decel_Ramp`: `Decel_Ramp` ≈ `RwSlowDecelLrn` × 1.25 / 250 during the slow-down, and the speed settles at the final speed **without dipping below it**. After 2–3 slow-downs `RwSlowDecelK` stays stable (does not keep falling).

---
## Check of print 1026 (10/26/2026)
| Fix | Status |
|---|---|
| 1. Motor_Manager rung 18 (auto) closed loop restored, rung 19 (ManMode) soft stop | ✅ |
| 2. Output_Manager rung 2 `Brake_Cmd` OR `BrakeHold` | ✅ |
| 3. General old core-teach rung deleted | ✅ |
| 4. Motor_Manager rung 7 ManMode display on raw pots | ✅ |
| 5. Motor_Manager rung 16 decel limited to `RwSlowDecelLrn` × 1.25 | ✅ |
| Console rung 4: wrong code → `DINT#10` | ✅ |
| `Psw` Retain = False | ✅ |
| Console rung 5 `HMI_Screen[0] = 10` branch | still there, harmless (no Change window control on the HMI) |
| `UwCoreDiameter` initial 100 | unchanged, check the real core OD |
→ Program OK for the tests above (AUTO allowed again).

## Drive scope 10/27/2026 → fix 5 WITHDRAWN
SoMove scope (FRH reference, RFR motor frequency, LCR current, VBUS):
- Stop from 50 m/min (7.3 Hz), SoftStopDecel 0: FRH falls ≈ 0.45 Hz/s, **RFR follows FRH exactly** → 16 s.
- Stop from ≈ 20 Hz, **SoftStopDecel 500**: FRH ≈ 2.3 Hz/s, RFR follows, current ≈ 10 A (motor 46 A), **VBUS 665–672 V, no rise** → ≈ 9 s.

→ The drive is **not** the limit at these speeds: no DC bus rise, brA never acts. The slow decel was the **PLC ramp**: `DecelCoarse` 0.5 = 125 "mm/s²" on the reference scale (10 V = VelMax 800 m/min) ≈ 0.56 Hz/s. Because the motor drives the rewinder, a fixed Hz/s gives a web decel proportional to the diameter: the "K × D" measured since v6f is the PLC ramp itself.
→ Fix 5's premise (drive slower than the PLC ramp) is wrong: the cap only limits the PLC to its own past value. **Delete the fix 5 rung** ("v6o: Decel ramp limited to the learned drive decel"); fix 5b goes with it.

### Settings
| Setting | Value | Note |
|---|---|---|
| `SoftStopDecel` | 500 (keep, adjust to taste) | soft stop ≈ 2.25 Hz/s |
| `SoftStopEndSpd` | 8 | |
| `DecelCoarse` | 0.5 → **1.0** (optional) | auto slow-downs / pot reductions twice as fast; test web tension |
| `RwSlowDecelK`, `RwStopDecelK`, `RwStopDecel` | **0** after changing DecelCoarse | re-learned on the next auto slow-down / stop |
Next: scope at 300–400 m/min on a large roll, watch VBUS (no braking resistor) before going higher than DecelCoarse 1.0.
