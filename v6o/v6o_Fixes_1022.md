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

## Check
`UwCoreDiameter` initial value = **100** in Globals. If the real unwinder core OD is 101 mm, enter it (Retain, Watch tab or HMI page 44).

---

## Order
1. Fix 1 + 2 + 3 (+ 4) → F7 = 0 errors.
2. Before the transfer: record the Retain values (`Pre_Transfer_Values.md`). No variable is new or renamed, so a normal transfer keeps them.
3. Transfer → tests.

## Tests
1. **AUTO**, Work pot at maximum → `Velocity_M_min` ≈ **400** (not 800), and the speed holds (closed loop).
2. Auto slow-down → final speed ≤ 40 m/min.
3. STOP once at 200 m/min (auto) → smooth soft stop, as in the v6m test.
4. **MANUAL**: STOP once → `InvRef` = 0, the drive decelerates on its ramp; the % display = 100 % at full pot.
5. Immediate stop at speed (STOP held 1 s): `O_Brake` stays ON until < 5 m/min (or 15 s) → the web stays tight.
6. Unwinder TEACH CORE (machine stopped): TEACHING about 2 s → DONE; `UwCoreDist_Prev` = old value; UNDO → RESTORED.
