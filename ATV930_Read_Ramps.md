# ATV930 (1AZ1): reading Stt, dEC, brA on the graphic keypad

Source: ATV900 Programming Manual NHA80757-14 (in this repo), pages 341–347 and 619–628.

## 1. Go to the main menu
Press the **Home (house) key**, or ESC several times, until the main menu appears:
Simply Start / Dashboard / Diagnostics / Display / **Complete settings** / Communication / File management / **My preferences**.

## 2. If "Complete settings" is NOT in the list
Two possible reasons (both in **My preferences**, which is always visible):

| Check | Menu | Fix |
|---|---|---|
| **Access level** | My preferences → **Access Level (LAC)** | If it is **Basic (BAS)**, only Simply Start / Dashboard / Diagnostics / My preferences are shown. Set it to **Standard (STD)** or **Expert (EPR)**. |
| **Password** | My preferences → **Password (COD-)** → *Password status (PSST)* | If it is **Pwd is locked (LOCK)**, Complete settings and Communication are hidden. Enter the 6-character password (**Password PWD**). Ask La Meccanica Fumagalli: it cannot be read or reset without the password. |

Also: My preferences → Parameter access → **Visibility (PVIS)** → set **All (ALL)**, so that parameters of inactive functions are shown too.

## 3. The parameters
| Parameter | Menu path |
|---|---|
| **dEC** Deceleration (also ACC, Inr ramp increment, rPt ramp type) | Complete settings → Generic functions → **Ramp (RAMP-)** |
| **brA** Dec. ramp adapt | Complete settings → Generic functions → **Ramp (RAMP-)** |
| **dE2 / AC2 / rPS** (2nd ramp, switched by DI5 = `O_AccDec2`) | Complete settings → Generic functions → **Ramp switching** |
| **Stt** Type of stop | Complete settings → Generic functions → **Stop configuration (STT-)** |
| **FrS** Nominal motor frequency | Complete settings → Motor parameters → Motor data |
| **HSP** High speed | Complete settings → Generic functions → **Speed Limits** (also in Simply Start) |

Factory values for reference: dEC = 3.0 s, brA = Yes, Stt = On ramp (RMP).
brA = Yes: the drive **stretches** the deceleration ramp on its own when the DC bus voltage rises. That is likely here: there is no braking resistor (plan sheet 1).

## 4. Without the keypad
- **Webserver:** the embedded Ethernet webserver, if the drive's Ethernet port is connected (My preferences → Webserver).
- **SoMove** (free, Schneider) on a PC, via the Modbus port with a USB cable (TCSMCNAM3M002P). It reads all parameters, and **you can save the complete configuration as a file**, which is a good backup before any change.

**Don't change anything yet.** Just read and note `dEC`, `brA`, `Stt`, `dE2`, `rPS`, `FrS`, `HSP`, and send me the values.
