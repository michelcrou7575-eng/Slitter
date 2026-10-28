# v6x: "DID YOU CHANGE THE PAPER?" popup at each new parent roll

## PLC (AutoStop_Control section 10, base print 1027 + v6w)
- New parent roll loaded on the unwinder (`UnWinder_Empty` TRUE → FALSE, sonar ON `Measure_ON`) → **`GsmAsk`** := TRUE.
- HMI **YES** → `GsmAskYes` := TRUE → PLC forgets the learned thickness (`RwMat_K` = 0, like NEW PAPER), clears `GsmAskYes` and `GsmAsk`.
- HMI **NO** → `GsmAsk` := FALSE (the thickness is kept; the automatic detection still works).
- Not triggered by a rewinder extraction (same paper), only by a new parent roll.
- Limitation: a parent roll changed **before** it was empty (no `UnWinder_Empty`) gives no popup → use NEW PAPER.

## Variables
- Globals: paste `v6x_Globals_paste.txt` (`GsmAsk`, `GsmAskYes`, BOOL, Publish Only, not Retain). Externals: type both names.
- Internals: paste `v6x_Locals_paste.txt` (`UwEmptyMem`).
- Replace the ST with `AutoStop_Control_v6x.st` (= v6w + this). F7 → transfer.

## HMI (EasyBuilder)
1. New popup window (for example **51 "GSM ASK"**, about 500 × 250):
   - Text: **DID YOU CHANGE THE PAPER (GSM)?** / **AVEZ-VOUS CHANGÉ DE PAPIER (GRAMMAGE) ?**
   - Button **YES / OUI**: Set Bit → `GsmAskYes` → **Set ON**.
   - Button **NO / NON**: Set Bit → `GsmAsk` → **Set OFF**.
2. Window 10 MAIN: Object → Embed Window → **Direct Window**, Trigger ON, Window No. 51, Style **Popup window**, Read tag **`GsmAsk`**.
   Leave **Monopoly** unticked on window 51, so MAIN stays usable if the operator answers later.
3. Compile → download.

## Test
Load a new parent roll (sonar sees the empty → full change): the popup appears. NO → closes, GSM OK stays ON. YES → closes, GSM OK goes OFF, re-learned after the first window.
