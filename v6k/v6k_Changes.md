# v6k: unwinder and rewinder TEACH CORE work the same way

## Before
| | Unwinder (General rung 15) | Rewinder (v6j, section 14) |
|---|---|---|
| Core diameter | `UwCoreDiameter` | `RwCoreOD` |
| Button | `Core_Measure` | `RwTeachCore` |
| Stores | `UwCoreDistance` := **one** sonar reading, immediately | `RwAxisDist` after **2 s stable** |
| Checks | none | motor stopped, web not moving, sensor OK |
| Status | none | `RwTeachState` |

## After (v6k)
The unwinder teach works like the rewinder one: **section 14b** in AutoStop_Control.
- Checks: motor stopped, web < 1 m/min, `UwCoreDiameter` > 0, sonar reading > 0. Otherwise **refused** (status 3) and nothing is changed.
- **2 s, 20 sonar samples averaged** (the sonar is not filtered) → `UwCoreDistance`.
- Status **`UwTeachState`**: 0 idle, 1 teaching, 2 done, 3 refused.
- HMI tags unchanged: `Core_Measure` (button), `UwCoreDistance`, `UwCoreDiameter`.

## Steps (on top of v6j)
1. Global Variables: paste `v6k_Globals_paste.txt` (`UwTeachState`). Program Externals: paste `v6k_Externals_paste.txt`.
2. Internals: paste `v6k_Locals_paste.txt` (`UwTeachTicks`, `UwTeachSum`).
3. Replace the ST with `AutoStop_Control_v6k.st` (= v6j + section 14b).
4. **General rung 15: DELETE it** (Core_Measure → MOVE → T_CoreMemDelay → Reset). Otherwise it would store a single reading and reset `Core_Measure` after 250 ms, before the averaged teach finishes.
   `T_CoreMemDelay` is then unused (it can be deleted).
5. F7 = 0 errors → transfer.

## HMI: normalised "CORE / ENCODER" page (password)
| Row | Input | Button | Display |
|---|---|---|---|
| PASSWORD | `Psw` | | |
| ENCODER PULSES / REVOLUTION | `Encoder_Pulse` (####) | | |
| ENCODER WHEEL DIAMETER [mm] | `EncoderWheel_Diam` (####.#) | | |
| **UNWINDER** CORE DIAMETER [mm] | `UwCoreDiameter` (###.#) | **TEACH CORE** → `Core_Measure` (Set ON) | `UwDiam_Act` (####.#) + status `UwTeachState` |
| **REWINDER** CORE DIAMETER [mm] | `RwCoreOD` (###.#) | **TEACH CORE** → `RwTeachCore` (Set ON) | `RwDiam` (####.#) + status `RwTeachState` |
| REWINDER PAPER THICKNESS [mm] (learned) | | | `RwThick_mm` (#.###) |

Status text (same for both, Word lamp / text on the INT):
0 = (blank), 1 = TEACHING…, 2 = DONE ✓, 3 = REFUSED: STOP MACHINE / CHECK SENSOR.
Optional, for the technician: `UwCoreDistance` and `RwAxisDist` (read only).

### Remarks on the current page (screenshot 10/20/2026)
- "UNWINDER CORE OUTSIDE **DISTANCE**" → should read **DIAMETER** (`UwCoreDiameter` is the core OD).
- "UNWINDER / REWINDER **MIN DIAMETER**" → better **CORE DIAMETER**, and put the input and the TEACH button on the same row (table above). The value next to TEACH is then the **actual diameter**, so the operator sees the core diameter right after the teach.
- "REWINDER LEARNED MATERIAL [K]" with ####.# would show **0.0**: `RwMat_K` is very small (about 0.006). Show **`RwThick_mm`** (learned paper thickness, #.### mm) instead, which is easy to check. Or show `RwMat_K` with #.###### if you prefer.
- The TEACH buttons: **visible only when `MotStop` = TRUE**.
