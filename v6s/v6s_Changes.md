# v6s: paper (thickness) change while GSM OK is ON

## How it worked before (v6p)
`RwMat_K` (learned paper thickness) is filtered: each 10 s window moves it 30 % (`RwLearn_K`) toward the new measurement. After a paper change it only follows slowly (≈ 50 s → 83 %, ≈ 100 s → 97 %). During that time the remaining length, the slow-down diameter and the stop diameter are computed with the old paper → slow-down/stop too early or too late. GSM OK stays ON: nothing tells the operator.

## v6s (AutoStop_Control section 4 only)
1. **Automatic:** a window more than `RwMatChangePct` (25 %) away from `RwMat_K`:
   - 1st one: ignored (outlier: splice, roll start, vibration),
   - 2nd in a row: the paper has changed → `RwMat_K` := the new value **directly** (≈ 20 s after the change).
   Normal windows are filtered as before. `RwMatChangePct` = 0 → off (v6p behaviour).
2. **Manual: `RwMatReset`** (HMI button "NEW PAPER", Set ON, the PLC resets it): `RwMat_K` = 0 → GSM OK goes OFF → the first valid 10 s window sets it again.
   With `RwMat_K` = 0 the diameter target is still respected (plain target, no anticipation) until it is learned.

## Steps
1. Global Variables: paste `v6s_Globals_paste.txt` (`RwMatReset`, `RwMatChangePct` 25.0 Retain). Externals: type the two names (types come from the globals).
2. Internals: paste `v6s_Locals_paste.txt` (`MatChangeCnt`, `T_MatReset` TON).
3. Replace the AutoStop_Control ST with `AutoStop_Control_v6s.st` (= v6p + section 4a + the change in section 4).
4. F7 → transfer. No Retain variable renamed.
5. HMI window 44: button **NEW PAPER** → `RwMatReset` (Set Bit, **Momentary**: ON while pressed). Must be **held 3 s**; then the PLC resets the learned thickness and clears the bit (lamp off = done). Released earlier → nothing happens. Visible when `MotStop`.

## Test
- Same paper: `RwThick_mm` stable, `TaglMonoTRM.MatChangeCnt` mostly 0.
- Thicker/thinner paper (> 25 %): after ≈ 20 s of winding `RwThick_mm` jumps to the new value.
- Small changes (< 25 %, e.g. 80 → 90 g/m²): followed by the normal filter in about 1 min. Lower `RwMatChangePct` (15) if needed, or press NEW PAPER.
