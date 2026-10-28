# Next modifications (noted, not started)

## HMI stop targets editable while AUTO is ON (10/28/2026, operator request)
Today the operator must switch **RwStopEnable** OFF before entering a rewinder stop diameter (`RwTargetDiam`), then ON again. Same on the unwinder (`UwStopEnable` / `UwStop_At_Meter`).
Wanted: change the target without switching AUTO off and on. To check first: HMI input interlock on the enable bit, and the PLC side (latched `RwSlowReq` / `RwStopReq` reset when the target changes, `RwResetHyst`).
