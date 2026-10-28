# v6v: no web pull-back after a stop (trace 10/28/2026 15:00)

## Trace GSM20261028150049 (Traces/): soft stop from 400 m/min, rewinder ≈ 595 mm
| | |
|---|---|
| Soft stop | 13:31:38.15 → run command off 13:31:51.45 at 7.3 m/min: **13.3 s**, web decel ≈ **500 mm/s²** constant (SoftStopDecel 500, v6r) |
| Run-out | ≈ 44 m |
| Thickness windows at 400 m/min | 0.096 / 0.120 / 0.112 / 0.100 mm → learned 0.105 mm ✅ |
| Stop learning | start 8.6 m/min < RwMinLearnSpd → not learned, no fault ✅ |
| **After the stop** | **`Velocity_M_min` −5.5 … −6.6 m/min for ≈ 3 s: the web goes BACK ≈ 20 cm** (StopMeas 2051 pulses) |

**Cause:** after the run command drops, the drive ramps to 0 Hz and stops driving the rewinder. `BrakeHold` keeps the T-one in automatic tension until `RwSpeed` < 5 m/min, but `RwSpeed` is the **absolute** speed: the web pulled back by the unwinder tension at 6 m/min keeps it ON, and the T-one keeps pulling.

## Change (AutoStop_Control section 13, one line)
`BrakeHold` released on the **signed** web speed: `Velocity_M_min < 5.0` (instead of `RwSpeed < 5.0`). Forward stop: same as before. Web going back: released at once → T-one to "stop" (holding).

## Steps
Replace the ST with `AutoStop_Control_v6v.st` (= v6u + this line; base print 1027). No new variable. F7 → transfer.

## Test
Soft stop from 300–400 m/min: `Velocity_M_min` should stay ≥ 0 after the stop (maybe −1 m/min for a moment), no visible pull-back.
If it still pulls back: drive **ADC** (automatic DC injection at standstill) = Yes, SDC1 ≈ 50 % of NCR, TDC1 1–2 s, to hold the rewinder shaft for a moment.
