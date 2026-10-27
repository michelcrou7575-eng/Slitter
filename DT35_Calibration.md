# Rewinder DT35: fine-tuning the diameter reading

```
RwDist = RwDist0V + AI_Diam_Rewinder / 4000 × (RwDist10V − RwDist0V)   (filtered, mm)
RwDiam = 2 × (RwAxisDist − RwDist)
```
| Setting | Role | Today |
|---|---|---|
| `RwAxisDist` | **offset**: DT35 → shaft centre (mm) | 675.3 |
| `RwDist10V` | **scale**: DT35 distance at 10 V (mm) | 750.0 |
| `RwDist0V` | distance at 0 V | 0.0 |

Read the values in the Sysmac Watch tab (or on the HMI DT35 page when it exists), **machine stopped**, and wait 2–3 s for the filter (`RwFilter_K` 0.2 per 100 ms).

## DT35 analog range as set on this machine
0 V = nearest point before the reading stalls + 30 mm (≈ 14 counts); 10 V = a little beyond the shaft centre + 30 mm (≈ 3,900 counts). Linear zone only.
→ `RwDist10V − RwDist0V` = real distance between these two points. The offset is done by **TEACH CORE** (v6j).

## Step 1: offset, with the empty core (always do this first)
**With v6j: just press TEACH CORE on the HMI** (empty core, machine stopped). The manual method:
1. Load an empty core of known outside diameter **D_core** (100 mm; measure it with a caliper).
2. Read **`RwDist`**.
3. Set **`RwAxisDist` = `RwDist` + D_core / 2**.
   Example: RwDist = 626.1 → RwAxisDist = 626.1 + 50 = **676.1**.
4. Check: `RwDiam` ≈ D_core (± 1 mm).

This fixes the zero. Small errors in mounting distance or sensor tolerance are removed.

## Step 2: scale, with a large roll (only if a full roll reads wrong)
1. Machine stopped, rewinder roll as large as possible (> 800 mm).
2. Measure its **real diameter**: a tape around the roll gives the circumference C → **D_real = C / π** (more precise than a ruler across).
3. Read `RwDiam` (= D_read).
4. If D_read and D_real differ by more than about 3 mm, the scale is wrong. Correct the span:
   ```
   k             = (D_real − D_core) / (D_read − D_core)
   RwDist10V_new = RwDist0V + (RwDist10V − RwDist0V) × k     ... with RwDist0V = 0: RwDist10V × k
   ```
   (reading too small → k > 1 → larger span). Then **repeat Step 1** (TEACH CORE), because the offset changes with the scale.
   *(Correction 10/27/2026: an earlier version of this sheet divided by k, which is wrong.)*

### Case 10/27/2026 (sensor relocated)
TEACH with core 100 → `RwAxisDist` 697.82. Full roll radius 720 mm (D_real 1440) reads **1380**.
k = (1440 − 100) / (1380 − 100) = 1340 / 1280 = **1.0469** → `RwDist10V` = 750 × 1.0469 = **785.2** (`RwDist0V` stays 0).
Then TEACH CORE again: expected `RwAxisDist` ≈ 728.2, and the full roll then reads ≈ 1440.
⚠ `RwMaxDiam` (1340) and `RwMaxSlowFallback` (1310) are below 1440: raise them to the new real maximum, otherwise the max-diameter protection stops the machine first.
⚠ At 1440 the DT35 raw value is only ≈ 40 counts (`RwRawMin` = 10): about 12 mm of diameter margin before a sensor fault.

## Good practice
- **Aiming:** the DT35 beam must point **at the shaft centre**, perpendicular to the roll surface. An off-centre beam gives an error that changes with the diameter. No setting can fix that, so correct the bracket first.
- **Surface:** shiny or very dark paper can disturb the reading. Watch `AI_Diam_Rewinder` for jumps. If it is noisy, lower `RwFilter_K` (for example 0.1).
- **DT35 settings** (its own buttons / teach): the analog range must stay 0 V = near … 10 V = 750 mm, the same as `RwDist0V` / `RwDist10V`. If the DT35 analog range is changed, change these two PLC values the same way.
- After changing the calibration, the learned values that depend on the diameter re-learn by themselves (`RwMat_K`, `RwSlowDecelK`, `RwStopDecelK`). For a clean start, write 0 to them.
- The values are **Retain**. Note the old values before changing them.
