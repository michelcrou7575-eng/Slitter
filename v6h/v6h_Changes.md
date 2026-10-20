# v6h: web on the floor at a stop (unwinder overruns)

## Field observation (10/20/2026)
STOP at 120 m/min: the **rewinder stops abruptly**, the **unwinder keeps turning** and lays the web on the floor in front of the machine.

## Cause (electrical plan sheets 1, 9, 15)
On a stop, `StartMotor_Cmd` drops →
- drive DI1 (run) drops → the rewinder stops on the drive's stop ramp (`Stt` / `dEC`);
- **at the same moment** `O_Brake` (PLC out 02 "REEL BRAKE AUTOMATIC CONTROL" → T-one terminal 4) drops → the T-one leaves **automatic tension control** (load cells) and switches to **"stop"**.

The tension loop is switched off exactly when it is needed most (hard rewinder deceleration). The stop setting of the T-one does not hold the heavy unwinder roll, so the unwinder overruns and the web goes slack.

## Fix: BrakeHold
`O_Brake` stays ON (T-one in automatic) **during the stop**, until:
- the web speed `RwSpeed` < **5 m/min**, or
- **15 s** have passed (safety timeout), or
- the auxiliaries drop (E-stop: the T-one also gets 4KA2 on terminal 5, unchanged).

While running nothing changes (`BrakeHold` = `Brake_Cmd`).

## Steps (on top of v6g)
1. Internals: paste `v6h_Locals_paste.txt` (`BrakeHold`, `BrakeHoldTicks`).
2. Replace the ST with `AutoStop_Control_v6h.st` (only the header and the new section 13 at the end).
3. **Output_Manager rung 2:** add `BrakeHold` (NO) **in parallel** with `Brake_Cmd`:
   ```
   ──┬── Brake_Cmd ──┤ ├──┬──────────────────────────────────────( ) O_Brake
     └── BrakeHold ──┤ ├──┘
   ```
4. F7 = 0 errors → transfer.

## Test
1. Run at 120 m/min → STOP. The web must stay tight (no loop on the floor). Watch: `BrakeHold` TRUE during the stop, FALSE below 5 m/min.
2. Same test at work speed, then an **automatic stop** (meters or diameter).
3. **E-stop** at speed: must behave as before (4KA2 path).

## If the web still goes slack
The T-one cannot follow the rewinder deceleration, even in automatic (brake torque or response time too low). Then also:
- **ATV930:** check `Stt` (type of stop) = **ramp**, and make the stop ramp (`dEC`) **longer**. Read the current `Stt` / `dEC` / `brA` first.
- **T-one:** check the stop level / stop torque and the regulation gain (RE T-one manual).
