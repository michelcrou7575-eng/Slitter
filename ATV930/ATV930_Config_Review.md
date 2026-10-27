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
