# v6e: `RwLearnFault` → `RwLearned_OK`

Apply on top of **1019_10** (v6d).

## Meaning
| Variable | Kind | TRUE when |
|---|---|---|
| `RwLearned_OK` | **Global** (replaces `RwLearnFault`), Publish Only | `RwMat_K` > 0 **and** (`RwStopDecel` > 0 **or** `RwLearnStop` = False) **and** no learning fault. **FALSE until learned.** |
| `LearnFault` | **New Internal** (program) | `LearnFailCnt` ≥ `RwLearnFailMax` OR `StopFailCnt` ≥ `RwStopFailMax`. Drives alarm 16, as before |

Alarm 16 behaves exactly as in v6d. "Not learned yet" (new material, `RwMat_K` reset to 0) does **not** raise an alarm. It only makes `RwLearned_OK` FALSE.

## Steps
1. **Global Variables:** rename `RwLearnFault` → **`RwLearned_OK`** (BOOL, Retain False, Publish Only).
   Comment: `Rewinder learning OK (K + stop decel learned, no fault)`.
2. **Internals:** paste `v6e_Locals_paste.txt` (`LearnFault`).
3. **AutoStop_Control:** replace the ST with `AutoStop_Control_v6e.st`. Only section 12 and the header changed.
4. **Alarms rung 16:** replace the contact `RwLearnFault` with **`LearnFault`** (NO):
   ```
   ControlVoltage ──┤ ├── LearnFault ──┤ ├──────────────────────────(S) Alarm_Array[16]
   ```
5. **Alarms rung 17:** replace the contact `RwLearnFault` (NC) with **`LearnFault`** (NC):
   ```
   ──┬── I_RsetAlarm ──┤ ├──┬── LearnFault ──┤/├────────────────────(R) Alarm_Array[16]
     └── Alarm_Reset ──┤ ├──┘
   ```
6. **F7** = 0 errors. The rename in step 1 updates any other reference automatically. Check that no `RwLearnFault` is left (Ctrl+F).
7. **HMI:** if any object uses `RwLearnFault`, re-point it to `RwLearned_OK` and **invert the logic** (green = learned OK). Suggested: a lamp "REWINDER LEARNED" on the DT35 / LEARNING page and/or the main page.
