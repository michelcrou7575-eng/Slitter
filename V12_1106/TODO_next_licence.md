# Pending for the next Sysmac licence (after V12_1106_6)

| # | Where | Change | Why |
|---|---|---|---|
| 1 | Alarms rung 29 | delete the `ControlVoltage` contact | messages keep cycling during an E-stop |
| 2 | Global initial values | `RwRatioD` = live value (≈ 2800), `TensWaitHz` = value found on the machine | Retain loss / download with init |
| 3 | AutoStop lines 568 / 598 | comments 1/2/4/8 and "8 s" | tidy |
| 4 | Option | warning 20 without beep (CASE split) | if the horn stop beep is enough |
| 5 | Option | warning 22 "Front gate open – JOG only" (`JogRun · NOT I_FrontGuard_Closed · NOT I_Prot_ByPass`, normal coil) | information during JOG |

## Without Sysmac (any time)
- ATV930 (SoMove 2.11, 192.168.137.15): `UFR` 100 → 120 → 140 % on a big roll; save `.psx` before / after.
- HMI: `TensWaitHz` numeric (#.#, 0–5), Event Log texts 13–21, macro on `LW-200` / `LB-200..202`.
- Check `RwRatioD` is the same on a small and a big roll (DT35 calibration).
