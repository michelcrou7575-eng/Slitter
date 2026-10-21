# v6l: previous value recorded before every TEACH CORE + UNDO

## Why
`RwAxisDist` and `UwCoreDistance` are Retain. A TEACH on a wrong core (or on a wound roll) used to overwrite them with no way back except the Watch tab and a written note.

## What it does
- **Before each teach**, the PLC copies the current value:
  `RwAxisDist_Prev := RwAxisDist` (rewinder), `UwCoreDist_Prev := UwCoreDistance` (unwinder). Both are **Retain**.
- **UNDO** (HMI button, machine stopped): **swaps** current ↔ previous. Pressing UNDO again goes back to the taught value.
- Status: **4 = RESTORED** (in `RwTeachState` / `UwTeachState`). Refused (3) if the motor runs or no previous value exists.
- **Initial values** of `_Prev` = today's values (`RwAxisDist` **675.3**, `UwCoreDistance` **785.56**), so UNDO is possible from the very first teach.

## Steps (on top of v6k)
1. Global Variables: paste `v6l_Globals_paste.txt`. Program Externals: paste `v6l_Externals_paste.txt`. Internals: paste `v6l_Locals_paste.txt` (`TeachSwap`).
2. Replace the ST with `AutoStop_Control_v6l.st` (= v6k + 2 lines that keep the previous value + section 14c UNDO).
3. F7 = 0 errors → transfer.
4. **Before the transfer:** check that `RwAxisDist` and `UwCoreDistance` in the PLC are still 675.3 / 785.56. If not, put the PLC values as the Initial Value of the two `_Prev` variables.

## HMI (screen 44)
| Object | Tag | Setting |
|---|---|---|
| Button "UNDO" next to each TEACH CORE | `UwTeachUndo` / `RwTeachUndo` | Set ON (the PLC resets it), visible only when `MotStop` |
| Display "PREVIOUS" (optional, technician) | `UwCoreDist_Prev` / `RwAxisDist_Prev` | ####.# mm, read only |
| Word Lamp status | `UwTeachState` / `RwTeachState` | add **state 4**: **RESTORED** / **RESTAURÉ** (blue). Number of states = **5** |
