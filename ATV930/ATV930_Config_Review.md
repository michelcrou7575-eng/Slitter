# ATV930D30N4: review of Slitter903_Config_Org.txt (SoMove export 10/27/2026)

Drive V3.4IE28, SoMove DTM 4.6.4. **Ethernet: fixed IP 192.168.137.15** (not 192.168.250.x → that is why it was never found on the machine network).

## Only these parameters differ from the factory settings
- Motor standard 60 Hz (40 HP, 460 V, 55 A, 60 Hz, 1771 rpm = factory values for this rating)
- Motor tune results (RSA, IDA, LFA, TRA… = autotune done)
- Ethernet IP mode = fixed address
- Number of motor starts NSM = 10359

**Everything else is factory default**, including:

| Code | Value | Plan / PLC expects | Remark |
|---|---|---|---|
| FR1 (reference 1) | **AI1** | speed ref from PLC MAB221 VO2 (handover says AI2) | ⚠ check which terminal the wire is on |
| AI2A | not assigned | | |
| RPS (ramp switching) | **not assigned** | DI5 = 2nd ramp (`O_AccDec2`) | DI5 does **nothing** → AC2/dE2 never used |
| RRS (reverse) | **DI2** | | ⚠ nothing must be wired on DI2 |
| RSF (fault reset) | DI4 | | |
| ACC / dEC | 3 s / 3 s (0 → 60 Hz) | | |
| AC2 / dE2 | 5 s / 5 s | | unused (RPS not assigned) |
| TA1–TA4 | 10 % rounding | | |
| **brA** | **Yes** | | drive stretches the decel on DC bus overvoltage (no braking resistor) |
| Stt | On ramp | | |
| LSP / HSP | 0 / 60 Hz | | 10 V = 60 Hz |
| CTT | Sensorless flux vector V | | |
| CLI | 73.8 A | | |
| FLR catch on fly | not configured | | |

## Question 1: was this read BEFORE or AFTER the password reset?
**Answered 10/27/2026:** the password was unlocked with **RESET!** (Schneider FAQ), which is NOT a factory reset. So this export is the **original configuration**: speed reference on **AI1**, 2nd ramp never active.
RESET! only unlocks until the next power cycle: enter **000000** as the new password so the status becomes "no password defined". SoMove/Ethernet user: Communication → Comm parameters → Embd Eth Config → User Authentication.

- **After**, and the reset was a factory reset: the original configuration is lost (FR1, RPS…). Check that the drive still follows the PLC reference before running.
- **Before** (or the machine runs normally with it): this IS the original configuration. The speed wire is then on **AI1**, and the 2nd ramp was never active.

Quick check, machine stopped and safe: **Display → I/O map → Analog inputs**: AI1 / AI2 voltage while the PLC writes `InvRef` (manual mode, Watch tab). The one that moves is the wired input. Or look at the terminal.

## Why the stops are long (with this config)
dEC = 3 s from 60 Hz is already short. The real limit is **brA = Yes** + no braking resistor: the motor regenerates into the DC bus, the drive stretches the ramp to avoid an ObF trip. Field: 24 mm/s² at 120 mm, 90 mm/s² at 600 mm.
→ **Shortening dEC changes nothing.**

## Options (one at a time, test, record)
1. **brA = High Torque (DYNA)** (manual p. 343): adds a magnetising current during the decel, so more energy is burned in the motor → stronger decel **without a resistor**. "Use comparative testing". The motor heats more during decels; watch the motor thermal with many stops.
2. **Braking resistor** on PA/PB (see Braking_Resistor.md): the real fix, the drive can then follow dEC = 3 s.
3. Optional: RPS = DI5 so `O_AccDec2` really selects AC2/dE2 (jog / manual). Only after deciding which ramps are wanted.

## After any drive change: let the PLC re-learn
Watch tab: `RwStopDecelK` = 0, `RwStopDecel` = 0 (re-learned at the next stop ≥ 50 m/min). `RwSlowDecelK`: leave it, it climbs by itself (fix 5 margin 1.25) over 2–3 auto slow-downs.
Before any change: **save the configuration** (SoMove "Save as" / keypad File management → copy to keypad).

## Motor nameplate vs drive motor data (photo 10/27/2026)
Siemens 1LE1523-2AB59-0JA4-Z, 200L, 240 kg, IE3, SF 1.15, Design A.

| Drive | Code | In the drive now | Nameplate | Action |
|---|---|---|---|---|
| Nominal motor power | NPR | 40 HP | 40 HP / 30 kW | OK |
| Nominal motor voltage | UNS | 460 V | **480 V Δ** | → 480 V |
| Nominal motor current | NCR | 55 A | **46.0 A** | → 46.0 A |
| Nominal motor frequency | FRS | 60 Hz | 60 Hz | OK |
| Nominal motor speed | NSP | 1771 rpm | **1778 rpm** | → 1778 rpm |
| Motor cos phi (if asked) | COS | — | 0.83 | → 0.83 |
| Motor thermal current | ITH | **55 A** | 46.0 A | → **46.0 A** (55 A = motor overload protection 20 % too high) |

The drive holds the **factory values** for a 40 HP motor, not the nameplate. The autotune (RSA, IDA…) was therefore done with wrong data (IDA 36.5 A magnetising current looks high: about 26 A expected for 46 A at cos phi 0.83).

### Procedure (machine stopped, run command OFF, motor cold)
1. Save the current configuration (SoMove "Save as" / keypad copy).
2. Complete settings → Motor parameters → Motor data: UNS 480, NCR 46.0, NSP 1778 (FRS 60, NPR 40 HP unchanged).
3. Motor parameters → Motor thermal monitoring: ITH = 46.0 A.
4. **Autotune (TUN = Apply autotuning)**: standstill autotune, the motor is energised but does not turn. The STO must be released (4KA2 on), PLC run command (DI1) OFF. Takes a few seconds; check status = done.
5. Save the new configuration again (new file name).
6. Test run in manual, then auto: speed stability (the PLC loop compensates), no drive alarm.
Do the motor data + autotune **before** testing brA = DYNA: the High Torque braking works with the motor flux model.

## Wiring photo 10/27/2026 vs the export: they do NOT match
| Terminal | Wire | Plan | Export says |
|---|---|---|---|
| AI2 / COM | 13.70 / 13.80 (shielded pair) | speed reference from PLC MAB221 VO2 | FR1 = **AI1**, AI2 not assigned |
| AI1 | empty | | |
| DI5 | 15.70 | 2nd ramp `O_AccDec2` | RPS **not assigned** |
| R1A / R1C | 24PW / 12.30 | fault relay → PLC IN 08 | |
| STOA / STOB | 1.10 / 1.20 | STO via 4KA2 | |

With FR1 = AI1 and nothing on AI1, the drive would get **no speed reference**: the machine could not run in auto. Since it ran, the export is probably **not the drive's real configuration** (SoMove project defaults, a partial "Load from device", or a different configuration set), unless the drive was reset since.

### Check on the keypad (nothing to change)
Complete settings → Command and Reference → **Ref Freq 1 Config (FR1)**, and Generic functions → Ramp switching → **RPS**.
- Keypad shows **AI2** / **DI5** → the export is wrong: redo SoMove **Load from device** (connected, "Device → Load from device"), check that "Modified parameters" now lists FR1, AI2… and save again.
- Keypad shows **AI1** / not assigned → the drive was reset: **do not run**. Restore: FR1 = AI2, AI2T = voltage (0–10 V, UIL2 0 V / UIH2 10 V), RPS = DI5, then motor data + autotune.

## 10/27/2026: the motor does not run any more → the drive is on factory settings
FR1 = AI1 (nothing wired) → no speed reference. Restore (keypad or SoMove, machine stopped):

| Step | Menu (Complete settings →) | Parameter | Set to |
|---|---|---|---|
| 1 | Command and Reference | **FR1** Ref Freq 1 Config | **AI2** |
| 2 | Input/Output → AI/AQ → AI2 | **AI2T** | **Voltage** (0–10 V) |
| 3 | same | UIL2 / UIH2 | 0 V / 10 V (factory) |
| 4 | Motor parameters → Motor data | UNS / NCR / FRS / NSP / NPR | 480 V / 46.0 A / 60 Hz / 1778 rpm / 40 HP |
| 5 | Motor parameters → Thermal monitoring | ITH | 46.0 A |
| 6 | Motor parameters → Motor tune | TUN | Apply autotuning (STO released, no run command) |
| 7 | Generic functions → Ramp switching | RPS | DI5 (AC2 / dE2 stay 5 s) |
| 8 | My preferences → Password | | 000000 → "no password defined" |
| 9 | SoMove / keypad | | **save the configuration** (new file) |

Unknown original values (lost): HSP (factory 60 Hz), ACC/dEC (factory 3 s), AC2/dE2. In auto the PLC speed loop compensates the speed scale; in manual the full pot = HSP.
Test: manual at low pot → motor turns, then auto at 100 m/min → `Velocity_M_min` follows the set point. If the work speed max (400 m/min) is not reached in auto with `InvRef` at 4000, raise HSP.
After the restore, in the Watch tab: `RwStopDecelK` = 0, `RwStopDecel` = 0 (re-learn).
