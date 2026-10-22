# HMI: opening the password popups 22 / 44 (working 10/22/2026)

## Principle
- The password is typed in popup **11 - SETUP 11** (tag `Psw`).
- PLC Console rung 4: `Psw = 22` → `Psw22` ON, `Psw = 44` → `Psw44` ON.
- `HMI_Screen[0]` / Change window can NOT open popups (only full pages 10, 12, 20).

## EasyBuilder Pro V6.10
1. Window **10 - MAIN** → Object → **Embed Window → Direct Window**:
   - Trigger **ON**, Window No. **44 SETUP 44**, Style **Popup window**
   - Read: Device PLC, Tag **`Psw44`** (BOOL)
   - Position: X 162, Y 25, W 700, H 550
2. Same for window **22** with tag **`Psw22`**.
3. Red X on 44 / 22: **Set Word `Psw` = 0** (No shape, over the X picture) → closes + logout.
4. No Change window PLC Control on `HMI_Screen[0]`.

## Still to fix on window 44 (Diagnoser 10/22/2026)
| Object | Tag now | Should be |
|---|---|---|
| Numeric 19 WORK SPEED MAX | `EncoderWheel_Diam` | **`WorkSpd_Max_Set`** |
| Numeric 21 FINAL SPEED MAX | `EncoderWheel_Diam` | **`FinalSpd_Max_Set`** |
| Toggles 9 / 24 / 26 | `Core_Measure` ×3 | `Core_Measure`, **`UwTeachUndo`**, **`RwTeachUndo`** (Set Bit, Set ON) |
| Toggle 25 | `RwTeachCore` | OK (better: Set Bit, Set ON) |
| Word Lamp 17 | `UwTeachState` | OK, add one for **`RwTeachState`** (5 states) |
| Labels | "MIN DIAMETER" | "CORE DIAMETER" |

## PLC (optional cleanup)
- Console rung 4: wrong code `DINT#20` → `DINT#10` (or delete the MOVE).
- Console rung 5: keep only `P_First_RunMode → Psw := 0`.
