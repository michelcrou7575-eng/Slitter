# v6n: pot ranges can only change with the motor stopped

## Why
`WorkSpd_Max` / `FinalSpd_Max` (v6i) act on the next scan. Changed while running, the set point jumps (for example 400 → 300 means −25 % at once).

## Mechanism
- The HMI (or the Watch tab) writes a **request**: `WorkSpd_Max_Set` / `FinalSpd_Max_Set`.
- The PLC copies the request into the **active** values `WorkSpd_Max` / `FinalSpd_Max` **only when `StartMotor_Cmd` = FALSE** (motor stopped).
- While the motor runs, the request waits: `SpdMax_Pending` = TRUE (HMI shows "NEW RANGE AT NEXT STOP").
- The limits are applied to the request too, so the HMI shows the value that will really be used.

## 1. Variables
- Global Variables: paste `v6n_Globals_paste.txt` (`WorkSpd_Max_Set` 400, `FinalSpd_Max_Set` 40, Retain; `SpdMax_Pending`).
- Program Externals: paste `v6n_Externals_paste.txt`.
- `WorkSpd_Max` / `FinalSpd_Max` (v6i) stay, as the **active** values. On the HMI they become **display only**.

## 2. Motor_Manager rung 6 (replaces the v6i ST)
```
// v6n: requested pot ranges, limited, applied only with the motor stopped
IF WorkSpd_Max_Set < 50.0 THEN
    WorkSpd_Max_Set := 50.0;
ELSIF WorkSpd_Max_Set > VelMax THEN
    WorkSpd_Max_Set := VelMax;
END_IF;
IF FinalSpd_Max_Set < 5.0 THEN
    FinalSpd_Max_Set := 5.0;
ELSIF FinalSpd_Max_Set > WorkSpd_Max_Set THEN
    FinalSpd_Max_Set := WorkSpd_Max_Set;
END_IF;

IF NOT StartMotor_Cmd THEN
    WorkSpd_Max := WorkSpd_Max_Set;            // motor stopped: apply
    FinalSpd_Max := FinalSpd_Max_Set;
END_IF;
SpdMax_Pending := (WorkSpd_Max <> WorkSpd_Max_Set)
                  OR (FinalSpd_Max <> FinalSpd_Max_Set);

// v6i: pots scaled to their own full scale (m/min)
IF Pot1_Work_Velocity > INT#5 THEN
    Pot1_Mem := REAL_TO_INT(INT_TO_REAL(Pot1_Work_Velocity) * WorkSpd_Max / VelMax);
ELSE
    Pot1_Mem := INT#0;
END_IF;
IF Pot2_Slow_Velocity > INT#5 THEN
    Pot2_Mem := REAL_TO_INT(INT_TO_REAL(Pot2_Slow_Velocity) * FinalSpd_Max / VelMax);
ELSE
    Pot2_Mem := INT#0;
END_IF;
```
The active values are only ever copied from the limited requests, so the old v6i limit block on `WorkSpd_Max` / `FinalSpd_Max` is no longer needed.

## 3. HMI (password page)
| Object | Tag | Setting |
|---|---|---|
| Input "WORK SPEED POT MAX" | **`WorkSpd_Max_Set`** | #### m/min, limits 50–800 |
| Input "FINAL SPEED POT MAX" | **`FinalSpd_Max_Set`** | ### m/min, limits 5–400 |
| Display "ACTIVE" next to each (optional) | `WorkSpd_Max` / `FinalSpd_Max` | read only |
| Text "NEW RANGE AT NEXT STOP" / "NOUVELLE PLAGE AU PROCHAIN ARRÊT" | visible when `SpdMax_Pending` | blinking |

Extra (optional): disable the two inputs while running (EasyBuilder: Security → enable only when `MotStop` = ON). The PLC enforces it anyway.

## 4. Transfer
- `WorkSpd_Max_Set` / `FinalSpd_Max_Set` are new, so they start at 400 / 40. If the active values were changed before (for example 300), set the same values as the Initial Value of the `_Set` variables. Otherwise the active values go back to 400 / 40 at the first stop.
- F7 = 0 errors → transfer → HMI tags re-imported.

## Test
1. Machine running: change WORK SPEED POT MAX on the HMI → the speed does **not** change, "NEW RANGE AT NEXT STOP" shows.
2. STOP → the message disappears, `WorkSpd_Max` = the new value.
3. Restart: the full pot now gives the new maximum.
