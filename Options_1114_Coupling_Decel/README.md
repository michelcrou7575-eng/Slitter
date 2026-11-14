# Options 11/14 — rewind coupling knocks during DECELERATION

**Why:** while slowing down, the motor slows the rewind roll faster than the web tension alone would; the roll's
inertia then drives the motor, the torque at the claw coupling reverses and the claws cross their play → knock.
No knock as long as **web tension × radius > roll inertia × deceleration**.

Two levers (can be combined). Try **B first** (no download), then **A**.

## Option B — softer slow-down (HMI / Watch only, no program change)
| Tag | Now | Try |
|---|---|---|
| `SoftStopDecel` | 500 mm/s² | **350**, then 300 |
| `FinalStopDecel` (end-of-roll ramp) | 500 mm/s² | **350**, then 300 |
| `DecelWeb` (auto slow-down / pot down) | 250 mm/s² | keep, or 200 |
| `SCurveTime` | 0.5 s | **0.8–1.0 s** (rounder start of the decel) |
Stop lengths and slow-down points are calculated with these values, so the stop still lands on target
(a lower decel = earlier slow-down / stop command, automatically).

## Option A — decel boost (Tension Manager, needs a download)
More unwinder brake (T-one set point) while the line ramps down: the web keeps the coupling loaded.
Requires the T-one remote set point active (`TensAOEnable` ON, F.37 = 1, calibration 1 V = 0 kg, 10 V = 250 kg).
1. Globals: paste `Globals_paste.txt` (`TensDecBoost` starts at **0 = off**).
2. Tension_Manager rung 0: insert part (a) after the JOG boost block, replace the `TensStep` line by part (b)
   (`TensionManager_DecelBoost_insert.st`).
3. Build → Transfer. HMI (TENSION MANAGER popup): `TensDecBoost` % (0–60), `TensDecRate_kg_s` (5–100), lamp `TensDecActive`.
4. Test: `TensDecBoost` **20 %**, then 30 %. Soft stop at 300 m/min on a small and a big roll: knock gone?
   Watch for web breaks (bleached paper!). Works for soft stops / slow-downs (2–5 s), not for hard stops
   (STOP held, E-stop: drive ramp / STO) — the pneumatic brake needs a few hundred ms.

## Not an option, the real fix
The claw coupling play (and red fretting dust) — repair / new claws from La Meccanica (comm. 04820).

## Also pending on the HMI / PLC (from 11/13)
- `CntResetMode` 1 / 2 / **4** (manual = 4): range check + `= 4` in Motor_Manager rung 1, initial value 4;
  HMI: Set Word 1 / 2 / 4 + Bit Lamps on `.0` / `.1` / `.2`.
- `TensMin_kg` = **0**, `TensMax_kg` = **250** (T-one: F.38 min voltage = 0 kg, F.39 max voltage = full scale F.34 = 250 kg).
- HMI macros `Tens_Up` / `Tens_Dn`: MANUAL limits 10..100 (DOWN macro: `if V < 10`).
- Screen 40: leave button = Set Word `HMI_Screen[0]` = 10 (clears `Psw`).
- `PulseRate` I/O mapping, `CntAutoReset` Retain → False.
