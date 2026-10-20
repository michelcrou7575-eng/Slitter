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

## 2. Power rating (continuous)
The resistor only works during stops and slow-downs, so its average power is small. It depends on the energy of each stop:

E ≈ ¼ · m · v² (full rewinder roll, solid cylinder) + motor/gearbox inertia

Example: full roll 1,000 kg at 800 m/min (13.3 m/s) → E ≈ 45 kJ. With 1 stop + 1 slow-down per roll and a few rolls per hour, the average power is **< 0.5 kW**.
→ **1.5–3 kW continuous, IP23 or better, with a built-in thermal switch** is ample. A heavier roll or frequent jogging means choosing the top of the range.
To size it exactly: the **roll width and maximum weight**, and the **number of stops per hour**.

Use a Schneider **VW3A77xx** resistor (catalog, instruction sheet NHA87388) or an equivalent third-party resistor with a thermal switch. Check the choice against the Schneider catalog table for the ATV930D30N4.

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
