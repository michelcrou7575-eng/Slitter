# Braking resistor for the ATV930D30N4 (1AZ1)

Sources: ATV930/950 Installation Manual NHA80932-11, p. 90–91 ("Minimum Resistor Values"); ATV900 Programming Manual NHA80757-14, p. 578 (Braking Resistor mon); electrical plan 04820SE001 sheet 1 (PA/+ and PB not connected today).

## 1. Resistance
| | Value |
|---|---|
| **Minimum allowed (manual)** | **10 Ω**. Never go below this, or the drive's braking transistor is destroyed |
| **Recommended** | **12–15 Ω** |

Peak braking power ≈ U_DC² / R, with U_DC ≈ 780 V (braking threshold of a 400 V drive, approximate):

| R | Peak braking power | Comment |
|---|---|---|
| 10 Ω | ≈ 61 kW | Maximum braking, no margin on the transistor |
| **12 Ω** | **≈ 51 kW** | Good margin, strong braking |
| **15 Ω** | **≈ 41 kW** | ≈ 1.4 × the motor power, enough here |
| 20 Ω | ≈ 30 kW | ≈ motor power, can be just enough |

## 2. Energy and power: sized for this machine
Data (10/20/2026): roll **1,500 mm wide, max 1,200 kg**, full diameter 1,330 mm, core about 100 mm, max speed 800 m/min.

| | Value |
|---|---|
| Inertia of the full roll J = m·(R²+r²)/2 | ≈ 267 kg·m² |
| Roll speed at 800 m/min | 20 rad/s |
| **Energy of the full roll** ½·J·ω² | **≈ 54 kJ** |
| + motor / gearbox (estimate) | ≈ 12 kJ |
| **Energy per stop, worst case** | **≈ 66 kJ** |

The unwinder brake (T-one) pulls on the web during the stop and takes part of this energy, so the real figure is lower. The values are on the safe side.

| Stop duration (from 800 m/min) | Peak braking power | Needed R (≤ 780²/P) |
|---|---|---|
| 3 s | ≈ 44 kW | ≤ 13.8 Ω → **12 Ω** |
| 5 s | ≈ 26 kW | ≤ 23 Ω → **15 Ω** OK |
| 10 s | ≈ 13 kW | 15 Ω OK |

Average power: 10 to 30 stops or slow-downs per hour → **0.2–0.6 kW**.

### Choice
- **R = 15 Ω** (12 Ω if stops shorter than 4 s from full speed are wanted). Never below 10 Ω.
- **Continuous power ≥ 1.5 kW** (2 kW gives margin for jogging and frequent stops).
- **Pulse energy ≥ 100 kJ** in about 10 s (the full-roll stop, about 66 kJ, must fit with margin). Check this value in the resistor datasheet.
- **Built-in thermal switch** (mandatory, see §3).

Use a Schneider **VW3A77xx** resistor (catalog, instruction sheet NHA87388) or an equivalent third-party resistor. Check the choice against the Schneider catalog table for the ATV930D30N4.

## 3. Wiring and safety (manual, DANGER, hazard of fire)
- Connect it to **PA/+ and PB** of the drive, with a shielded cable rated for the DC bus voltage (> 800 V DC), as short as possible.
- The resistor's **thermal switch must cut the mains contactor upstream of the drive**.
  **This panel has no mains contactor today** (only 1QS1 + fuses 1FU4, plan sheet 1). **Add one** (for example KM on R/S/T of 1AZ1), driven through the thermal switch. Optionally, also send it to a PLC input for an alarm.
- Mount it outside the cabinet or ventilated, away from cables and paper (it runs hot).
- Work only with the drive powered off and the DC bus discharged (measure PA/+ to PC/- < 42 V, wait 15 min).

## 4. Drive settings after fitting
| Parameter | Menu | Set |
|---|---|---|
| `brA` Dec ramp adapt | Complete settings → Generic functions → Ramp | **No** (otherwise the drive keeps stretching the ramp) |
| `BRO` Braking resistor monit | Complete settings → Error/Warn handling → Braking Resistor mon | **Warning** or **Error** |
| `BRP` Braking resistor power | same | kW of the resistor |
| `BRV` Braking resistor value | same | Ω of the resistor |
| `BRTC` Thermal time constant | same | from the resistor datasheet |
| `dEC` / stop ramp | Ramp | Can then be made shorter. Adjust on test, with the T-one keeping up (see v6h) |

## 5. PLC after fitting
The real deceleration changes, so let the PLC re-learn: write **0** to `RwSlowDecelK`, `RwStopDecelK` and `RwStopDecel`, then run 2–3 rolls (v6g/v6h).

## 6. Before ordering
Ask **La Meccanica Fumagalli**: the braking resistor and mains contactor are a change to the machine's electrical design (CE / CSA conformity of the machine).
