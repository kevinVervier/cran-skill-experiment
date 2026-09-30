# Pre-unblinding lock

Required by `skill-experiment-preregistration.md` §9 ("Break the mapping only
after all conformance and behavioural scores are recorded and committed to
git") and `CLAUDE.md` invariant 7 ("Do not unblind before scoring is
committed"). This file, and the commit that carries it, is that checkpoint.

**Locked:** 2026-09-30T17:15:21Z (UTC), by Kevin via Claude Code.

## What this commit locks in

All conformance scoring below was produced and recorded before any human or
process in this repository read `.blind_map.csv` or otherwise learned which
`RUN-*` ID corresponds to which arm. The scoring scripts never reference the
blind map — the only script in the tree that touches `blind_map` is
`run_arm.sh`, which *writes* the assignment at run-generation time and is not
part of scoring.

| Layer | Coverage | Status |
|---|---|---|
| Mechanical/static findings (`findings.json`) | 60/60 blinded trees | present |
| Seed-audit static check (`seed_audit.json`) | 60/60 blinded trees | present |
| Judgement oracle, calibration (`calibration/judge_results/*/rep{1,2,3}.json`) | 21 labels × 3 reps = 63/63 calls | complete, all parse as non-error JSON |
| Judgement oracle, calibration decision rule (§5.1.2) | — | **USABLE**: 91.67% detection (11/12 judge-targeted mutants), 8.33% FP rate on control |
| Judgement oracle, arm panel (`scoring/results/*/judge_rep1.json`) | 60/60 blinded trees, 1 rep each | complete, all verified non-error JSON (re-verified after two harness-failure incidents on 2026-09-30, see below) |

## Integrity note on the arm panel

The 60/60 figure above was reached only after two rounds of cleanup in this
session: the panel script's original `[ -f "${out}" ]` skip check could not
distinguish a real verdict from a harness failure (session-limit error stub,
or a 0-byte file from a process killed mid-write), and both occurred during
this run. Every file counted in the table above was individually
re-validated (parseable JSON, non-empty, `is_error` unset) before being
counted, and `scoring/run_judge_panel.sh` / `scoring/run_calibration.sh`
were both patched with an `is_valid_judge_output()` guard so a future rerun
cannot make the same mistake silently.

## Blind-map integrity anchor

`.blind_map.csv` stays gitignored and out of this commit, as required. Its
SHA-256 is recorded here so that, after unblinding, anyone can verify the
mapping file used to interpret these results is the same one that existed
at lock time — without this file ever having exposed its contents:

```
f295171c60e3c4123614f62fcb7ce2705e3f8706e720371e258f025e44661e67  .blind_map.csv
```

## Statement

Nothing under `scoring/` or `calibration/` in this commit was reviewed,
filtered, or altered with knowledge of arm identity. Unblinding may proceed
in a subsequent, separate step.
