# HMI macro "AutoStop_Refused_Entry" (EasyBuilder Pro 6.10, cMT2108X2)

Purpose: different warning text for an unwinder / rewinder AUTO STOP refusal (PLC warning 21), and keep the
unwinder STOP LENGTH field visible during an unwinder refusal. HMI only (no PLC change).

Macro settings: **Periodical execution, Time interval 5 (x 100 ms = 0.5 s)**. Device name = `"PLC"`
(OMRON EtherNet/IP NJ/NX). Tags are written `"VAR://<tag>"` (insert with GET/SET FN to be sure).
Tags read: `AutoEnRefused`, `AutoEnWhy`, `UwStopLenShow`, `UwStopDiamShow`, `UwSlowDiamShow` (all Publish Only in the PLC).
Local addresses: `LW-200`, `LB-200..202` — check they are free (Find/Replace Addr). Never use `LW/LB-9000…9999` (system).

```
macro_command main()
    bool  Refused = false
    bool  PlcStopLen = false, PlcStopDiam = false, PlcSlowDiam = false
    bool  ShowStopLen = false, ShowStopDiam = false, ShowSlowDiam = false
    bool  UwRefused = false
    short Why = 0
    short Code = 0

    GetData(Refused,     "PLC", "VAR://AutoEnRefused", 1)
    GetData(Why,         "PLC", "VAR://AutoEnWhy", 1)
    GetData(PlcStopLen,  "PLC", "VAR://UwStopLenShow", 1)
    GetData(PlcStopDiam, "PLC", "VAR://UwStopDiamShow", 1)
    GetData(PlcSlowDiam, "PLC", "VAR://UwSlowDiamShow", 1)

    if Refused and Why == 1 then
        UwRefused = true                       // unwinder AUTO refused
    else
        UwRefused = false
    end if

    ShowStopLen  = PlcStopLen or UwRefused     // keep STOP LENGTH visible to correct it
    ShowStopDiam = PlcStopDiam and not UwRefused
    ShowSlowDiam = PlcSlowDiam and not UwRefused

    if Refused then
        Code = Why                             // 1 = unwinder, 2 = rewinder
    else
        Code = 0
    end if

    SetData(Code,         "Local HMI", LW, 200, 1)   // Event Log: ==1 / ==2
    SetData(ShowStopLen,  "Local HMI", LB, 200, 1)   // STOP LENGTH field + label
    SetData(ShowStopDiam, "Local HMI", LB, 201, 1)   // STOP AT Ø field + label
    SetData(ShowSlowDiam, "Local HMI", LB, 202, 1)   // SLOW AT Ø field + label
end macro_command
```
If `==` gives a compile error, write `if Refused == true and Why == 1 then`.

## Event Log (replace the generic event on `AlarmCodeSV[21]`)
| Event | Read address | Type | Condition | Category | Text |
|---|---|---|---|---|---|
| A | Local HMI `LW-200` | Word | == 1 | Warning | Unwinder AUTO STOP refused: metres already reached – reset the counter or raise STOP AT |
| B | Local HMI `LW-200` | Word | == 2 | Warning | Rewinder AUTO STOP refused: roll ≥ target – raise the target or load a new core |

## Visibility (unwinder column, MAIN page)
| Object | Visibility bit |
|---|---|
| STOP LENGTH numeric + label | `LB-200` ON |
| STOP AT Ø numeric + label | `LB-201` ON |
| SLOW AT Ø numeric + label | `LB-202` ON |

The PLC (V12_1106_6, AutoStop line 353) now also keeps `UwStopLenShow` ON during an unwinder refusal, so the
macro and the PLC agree; the macro remains the source of the refusal texts.

Test: rewinder target below the roll + rewinder AUTO ON → text B; `Current_Metre` ≥ STOP AT + unwinder AUTO ON → text A
and the STOP LENGTH field stays visible.
