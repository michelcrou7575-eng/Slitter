# Metre counter auto reset at the next START

Modes (HMI, `CntResetMode`): **0 MANUAL** (eraser only) · **1 WITH NEW ROLL** (new parent roll on the unwinder) ·
**2 AFTER AUTO-STOP**. The event (machine stopped) arms `CntResetPend` (lamp "RESET AT START"); the old metres stay
visible. The **next accepted START** saves the length in `LastRoll_m`, pulses `Encoder_Reset` 50 ms and the machine
starts in the same press. While pending, the metre AUTO STOP / slow-down / refusal ignore the old metres.

## Load (also add to the Tension Manager project before its download)
1. Globals: paste `Globals_paste.txt` (Retain, Publish Only) + Externals.
2. Internals: paste `Internals_paste.txt` (`T_CntResetPulse` = **TP**, the 2 others TON).
3. Motor_Manager: new ST rung **before rung 2** = `MotorManager_MetreReset_rung.st`.
4. Motor_Manager rung 2 ("Reset encoder counter"): add **`CntAutoReset` (NO) as its own parallel branch directly
   to the `Encoder_Reset` coil** — NOT through the `StartMotor_Cmd` NC contact (START has already set it).
5. AutoStop rung 1: the 3 edits of `AutoStop_edits.st` (add `AND NOT CntResetPend`).
6. Build → 0 errors → Transfer. Uses `UnWinder_Empty`, `Measure_ON`, `UwDiam_Act`, `StartPB_OK`, `StartBlocked`,
   `AutoStopDone`, `Current_Metre` (all existing).

## HMI (paper popup + main page)
| Object | Address |
|---|---|
| MANUAL / WITH NEW ROLL / AFTER AUTO-STOP | 3 × **Set Word** on `CntResetMode` = 0 / 1 / 2 (lamp = active one); delete LB-130..132 |
| Lamp RESET AT START | `CntResetPend` |
| Display LAST ROLL [m] | `LastRoll_m`, `#####.#` |

## Tests
1. Mode 2: AUTO STOP by metres → lamp ON, metres kept. START → runs at once, counter 0, LAST ROLL = old metres, no stop.
2. Mode 1: parent roll run to empty, load a new one, 3 s → lamp ON; START → same as 1.
3. Mode 0: nothing automatic, eraser as before.
4. START refused (gate open) → no reset; next accepted START → reset.
5. Lamp stays ON after a START → check `Encoder_Reset` / `Current_Metre` (pending is cleared 2 s after the pulse anyway).
