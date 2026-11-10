# HMI macros Tens_Up / Tens_Dn (main page arrows next to TENSION SP)

Each arrow = **Function Key → Execute macro** (one press = one run, no bit address, no one-shot needed).
AUTO tension ON → changes the trim `TensTrim_kg` (±10 kg, PLC resets it to 0 when GSM / width / paper type changes).
AUTO tension OFF → changes `TensManual_kg` (10..100 kg).
TENSION SP display = `TensSet_kg` (format `###.#`): it shows the result (trim, taper, JOG boost included).

## Tens_Up
```
macro_command main()
    bool  AutoT = false
    float V = 0

    GetData(AutoT, "PLC", "VAR://TensAuto", 1)
    if AutoT then
        GetData(V, "PLC", "VAR://TensTrim_kg", 1)      // AUTO: trim +1 kg
        V = V + 1
        if V > 10 then
            V = 10
        end if
        SetData(V, "PLC", "VAR://TensTrim_kg", 1)
    else
        GetData(V, "PLC", "VAR://TensManual_kg", 1)    // MANUAL: set point +1 kg
        V = V + 1
        if V > 100 then
            V = 100
        end if
        SetData(V, "PLC", "VAR://TensManual_kg", 1)
    end if
end macro_command
```

## Tens_Dn
```
macro_command main()
    bool  AutoT = false
    float V = 0

    GetData(AutoT, "PLC", "VAR://TensAuto", 1)
    if AutoT then
        GetData(V, "PLC", "VAR://TensTrim_kg", 1)      // AUTO: trim -1 kg
        V = V - 1
        if V < -10 then
            V = -10
        end if
        SetData(V, "PLC", "VAR://TensTrim_kg", 1)
    else
        GetData(V, "PLC", "VAR://TensManual_kg", 1)    // MANUAL: set point -1 kg
        V = V - 1
        if V < 10 then
            V = 10
        end if
        SetData(V, "PLC", "VAR://TensManual_kg", 1)
    end if
end macro_command
```
Limits 10 / 100 = `TensMin_kg` / `TensMax_kg` (the PLC clamps anyway).
