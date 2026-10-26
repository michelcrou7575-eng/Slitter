# Slow-down distance without the drive parameters

## Formula (already in AutoStop_Control, sections 5b / 5c / 6, v6f + v6g)
The ATV930 ramp is in Hz/s on the **rewind shaft**, so the web deceleration grows with the rewinder diameter:

    a  [mm/s²] = K × D                    (D = rewinder diameter, mm)
    d  [m]     = ( v0² − vf² ) / (2 × a) / 1000  + RwSlowMargin_m      (v in mm/s; m/min ÷ 0.06)
    t  [s]     = ( v0 − vf ) / a

K is **learned on every auto slow-down** (`RwSlowDecelK`, Retain; initial 0.15).
Field data 10/20/2026: 24 mm/s² at 120 mm → K ≈ 0.20; 90 mm/s² at 600 mm → K ≈ 0.15.

## Table, K = 0.15, final speed 20 m/min (margin not included)
Slow-down distance [m]:

| v0 \ D (mm) | 150 | 300 | 600 | 900 | 1200 |
|---|---|---|---|---|---|
| 100 m/min | 59 | 30 | 15 | 10 | 7 |
| 200 m/min | 244 | 122 | 61 | 41 | 31 |
| 300 m/min | 553 | 277 | 138 | 92 | 69 |
| 400 m/min | 985 | 493 | 246 | 164 | 123 |

Slow-down time [s]:

| v0 \ D (mm) | 150 | 300 | 600 | 900 | 1200 |
|---|---|---|---|---|---|
| 100 m/min | 59 | 30 | 15 | 10 | 7 |
| 200 m/min | 133 | 67 | 33 | 22 | 17 |
| 300 m/min | 207 | 104 | 52 | 35 | 26 |
| 400 m/min | 281 | 141 | 70 | 47 | 35 |

## Check in the Watch tab / Diagnoser
`RwSlowDecelK`, `RwStopDecelK`, `RwSlowDecelLrn` (= K × D now), `RwSlowLen_m`, `RwSlowAtDiam`, `SlowAtDisp`.
Manual override: `RwSlowDecel` > 0 (mm/s²) replaces the learned value.
