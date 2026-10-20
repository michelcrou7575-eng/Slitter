# v6j: TEACH CORE button (rewinder DT35 offset)

## How the DT35 is set up (user, 10/20/2026)
- DT35 analog range taught with **30 mm margins**:
  **0 V** = nearest point before the reading stalls **+ 30 mm** (reads about 14 counts),
  **10 V** = a little **beyond the shaft centre, + 30 mm** (reads about 3,900 counts).
- So the sensor always works in its linear zone, and outside these points `RwSensFault` is set (`RwRawMin` 10 / `RwRawMax` 3900).

Consequence for the PLC:
- **Scale:** `RwDist10V − RwDist0V` must be the **real distance between the two taught points** (mm). `RwDist0V` can stay at 0.
- **Offset:** `RwAxisDist` is set by **TEACH CORE** (below), so it no longer has to be calculated by hand.
- If the span is not known: two-point method in `DT35_Calibration.md` (core + large roll measured with a tape).

## TEACH CORE
1. Machine **stopped**, an **empty core** on the rewinder.
2. HMI: check **CORE DIAMETER** (`RwCoreOD`, 100 mm by default; caliper value).
3. Press **TEACH CORE**. The status shows **TEACHING** for 2 s (filter settling), then **DONE**.
4. `RwDiam` now reads the core diameter.

The PLC sets `RwAxisDist := RwDist + RwCoreOD / 2`.
**Refused** (status 3) if the motor runs, the web moves (> 1 m/min), the DT35 is in fault, or `RwCoreOD` = 0. Nothing is changed then.

## Steps (on top of v6i)
1. Global Variables: paste `v6j_Globals_paste.txt` (`RwCoreOD` 100, `RwTeachCore`, `RwTeachState`).
2. Program Externals: paste `v6j_Externals_paste.txt`.
3. Internals: paste `v6j_Locals_paste.txt` (`TeachTicks`).
4. Replace the ST with `AutoStop_Control_v6j.st` (= v6i + section 14 at the end).
5. F7 = 0 errors → transfer.

## HMI (DT35 / LEARNING page, behind the password)
| Object | Tag | Setting |
|---|---|---|
| Numeric input "CORE DIAMETER" | `RwCoreOD` | ###.# mm, limits 50–200 |
| Button "TEACH CORE" | `RwTeachCore` | **Set ON** (the PLC resets it) |
| Status text | `RwTeachState` | 0 = (blank), 1 = TEACHING…, 2 = DONE ✓, 3 = REFUSED: STOP MACHINE / CHECK DT35 |
| Display "DIAMETER" | `RwDiam` | ####.# mm, to check the result |
| Display "AXIS DISTANCE" | `RwAxisDist` | ###.# mm (read only) |

Suggestion: show the "TEACH CORE" button only when `MotStop` = TRUE (visibility).

## Tip
Note `RwAxisDist` before the first TEACH (Retain). If a teach is done by mistake on a wound roll, put the old value back, or teach again on an empty core.
