# v6g: deceleration proportional to the rewinder diameter

## Field data (10/20/2026, v6f)
`RwSlowDecelLrn` went from **24 mm/s² at 120 mm to 90 mm/s² at 600 mm** over 8 auto stops.

## Cause
The ATV930 ramps (dEC, and the stop ramp) are in **Hz/s**, which is the angular deceleration of the **rewind shaft**.
Web deceleration = shaft deceleration × radius → **it grows with the rewinder diameter.**
A single learned value is wrong for most of the roll. With 90 mm/s² learned at the end of a roll, the next roll (120 mm core, real value about 24) would start the slow-down far too late and stop at speed.
The same applies to the stop deceleration (`RwStopDecel`).

## Fix
Learn **K = deceleration / diameter** (mm/s² per mm), then use **K × current diameter**:

| Learned (Retain) | Live (calculated every scan) |
|---|---|
| `RwSlowDecelK` (initial **0.15**, from the field data) | `RwSlowDecelLrn` = K × `DecelDiam` [mm/s²] |
| `RwStopDecelK` (seeded once from the current `RwStopDecel`) | `RwStopDecel` = K × `DecelDiam` [pulses/s²] |

- `DecelDiam` = `RwDiam` (on a DT35 fault, the last valid diameter), at least 100 mm.
- Each measurement uses the **average diameter** between the start and the end of the slow-down or stop.
- Filters: slow 0.5, stop 0.3 (unchanged).
- The order in section 6 is unchanged: `RwSlowDecel` (manual) > learned > DecelCoarse model.

## Steps (on top of the v6f in the PLC)
1. Global Variables: paste `v6g_Globals_paste.txt` (`RwSlowDecelK` 0.15, `RwStopDecelK` 0).
2. Program Externals: paste `v6g_Externals_paste.txt`.
3. Internals: paste `v6g_Locals_paste.txt` (4 rows).
4. Replace the ST with `AutoStop_Control_v6g.st`.
5. F7 = 0 errors → transfer.
   **Best done with a partly wound rewinder roll**, not a fresh core, because the one-time seed of `RwStopDecelK` = `RwStopDecel` / current diameter is then more accurate.
6. `RwSlowDecel` (manual) must be **0** so the learned value is used.

## HMI (DT35 / LEARNING page)
- Display: `RwSlowDecelK`, `RwStopDecelK` (#.###), `RwSlowDecelLrn` [mm/s²].
- Reset-learning button: write 0 to `RwSlowDecelK`, `RwStopDecelK` **and** `RwStopDecel`. If only `RwStopDecelK` is reset, it is re-seeded from `RwStopDecel`.

## Check
Over one roll (small → large diameter), `RwSlowDecelK` and `RwStopDecelK` must stay **roughly constant (± 15 %)** while `RwSlowDecelLrn` grows with the diameter.
If K still clearly rises or falls with the diameter, the model needs an offset term (a = c0 + c1 × D). Send me the K values at 3 or 4 diameters.
