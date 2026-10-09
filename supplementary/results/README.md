# Supplementary scores (post-hoc, labels known)

`supplementary_scores.csv`: one row per scored run of the delivered-A4 paired run
(Claude Code 2.1.294). Produced 2026-10-09 with `scoring/rescore_r01.R` (R01 class) and
`scoring/extract_findings.R` (`R CMD check` findings, baseline-subtracted). No judge panel.

- `paired = yes`: both arms of that block completed (10 pairs: blocks 11-13, 21-24, 26-28).
  `paired = no`: blocks 14 and 25, whose A0 partner was lost to an API 429; the lone A4 runs are
  reported as extras and not counted in the 10 pairs.
- `r01_class`: `canonical_fix` = no direct hit and no numeric seed default; `default_kept` = no
  direct hit but a numeric seed default remains; `hard_coded` = direct `set.seed()` hit.
- Rate-limited (429) runs are not scored and not listed: A0 blocks 14 and 25 (partial), and
  blocks 15-20 (both arms, 429 at turn 1; from the first launch, blocks 15-20 were then re-run as
  blocks 21-26). Not replaced in place.
- A0 block 23 ended `OTHER_success` (no DECLARED_DONE marker): kept.

Never pool these with the main n=57 analysis. The A4 file contains the answer to R01, so this is
a ceiling / positive-control check, not a skill-file result.
