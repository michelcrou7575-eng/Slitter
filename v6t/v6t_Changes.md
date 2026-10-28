# v6t: rewinder slow-down fallback while the paper thickness is not learned

## Problem (test 10/28/2026)
Rewinder AUTO stop at 300 mm, started at 270 mm, 200 m/min: no slow-down, stop from 200 m/min.
While `RwMat_K` = 0 (thickness not learned yet, or NEW PAPER), the PLC cannot convert the remaining diameter into metres → no anticipation → runs to the target and stops at full speed.

## Change (AutoStop_Control sections 6b and 7)
New global **`RwSlowFallbackMm`** (REAL, Retain, initial **30.0** mm, Publish Only).
While `RwMat_K` = 0 and `RwUseSlow`: `RwSlowReq` := TRUE at **`RwTargetDiam − RwSlowFallbackMm`** (not on a DT35 fault). "SLOW DOWN AT" shows that diameter.
As soon as the thickness is learned, the normal calculation takes over (the fallback is not used).
Same idea as `RwMaxSlowFallback` for the max-diameter protection.

## How much is enough?
The slow-down at 200 m/min needs ≈ 60–70 m at 300 mm (DecelCoarse 1.0). Diameter for 65 m of paper before a 300 mm target:
| Paper | ΔD |
|---|---|
| 0.10 mm | ≈ 14 mm |
| 0.20 mm | ≈ 30 mm |
| 0.30 mm | ≈ 45 mm |
30 mm covers most papers at 200 m/min. Higher speed or thicker paper → raise it (the fallback is only used until the thickness is learned, ≈ 10–20 s of winding).

## Steps
1. Global Variables: paste `v6t_Globals_paste.txt`. Externals: type `RwSlowFallbackMm`.
2. Replace the AutoStop_Control ST with `AutoStop_Control_v6t.st` (= v6s + this change).
3. F7 → transfer.

## Test
NEW PAPER (`RwMatReset`) → GSM OK off → AUTO run toward the target: "SLOW DOWN AT" = target − 30; the machine reaches the final speed before the target.
