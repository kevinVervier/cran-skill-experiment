# Supplementary: delivered-A4 vs a fresh control

**Status: post-hoc, labels known, not part of the pre-registered analysis.** Added 2026-10-08
after the main experiment's arm A4 was found to have had no instruction file (first-call context
identical to A0 in all 10 runs; see `LESSONS_LEARNED.md`). The main A4 data stay as they are,
reported as a second control. Nothing here changes a frozen file.

| File | What it is |
|---|---|
| `A4_CLAUDE.md.draft` | Draft hindsight file, from `rejection-ledger.md` (R01, R02) only. Kevin edits the wording. **Not yet installed in any arm tree.** |
| `check_arm_loaded.sh` | Manipulation check: `pre` (file present, excluded from build) and `post` (first-call context > A0's). |
| `orchestrate_pair.sh` | Blocks 11+, each one fresh A0 + one A4, randomised order, check before and after. |

## Install A4 (manual, once, by Kevin)
1. Edit `A4_CLAUDE.md.draft` for language only. Keep it to the two ledger items: no judge criteria,
   no `LESSONS_LEARNED.md`, nothing from the unblinded results.
2. Copy to `$RUNS_ROOT/arms/A4/pkg/CLAUDE.md`.
3. Create `$RUNS_ROOT/arms/A4/pkg/.Rbuildignore` containing `^CLAUDE\.md$` (as A1-A3 and A5 have).
4. `supplementary/check_arm_loaded.sh pre A4` must print `ok`.

## Caveats to state wherever results appear
- Claude Code is newer than in the main experiment (2.1.293 now; 2.1.282-284 then).
- Scored with `R CMD check`, the seed audit and `rescore_r01.R` only. The judge panel is not used.
- New control runs exist precisely so A4 is never compared to controls from another time.
