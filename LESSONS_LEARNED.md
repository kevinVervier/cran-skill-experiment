# Lessons learned — CRAN skill-file experiment

*Written 2026-09-30, immediately after unblinding. Source: unblinded results
(`unblinded_results.csv`), `PRE_UNBLINDING_LOCK.md`, project memory notes, and `LATER.md`.
Descriptive only; no significance testing (pre-reg §8).*

## 1. Headline result (lead with the uncomfortable part)

- **No detected effect of any skill file on conformance.** Across the 57 completed runs, residual
  review burden is 0 above baseline in every run. The floor rule (§7) applies: report it and move on.
- **The hindsight oracle (A4) does not separate from the A0 control.** A4 was written from this
  package's own failure history, so this is the most uncomfortable result. It says the instrument
  was too weak to detect an effect as much as it says skills do nothing.
- **The judge signal is two criteria.** All 57 NON_COMPLIANT verdicts come from C13 (employer-domain
  maintainer email) and L08 (quote style). C13 is flagged in every tree except A5. L08 looks like
  judge noise.
- **No arm checks early.** Median turn of first `R CMD check`: A0 184, A1 140, A2 272, A3 157,
  A4 115, A5 190, with heavily overlapping ranges. The "skill arms check early" mechanism is not in
  the data.
- **Efficiency differences are modest and confounded by skill length.** A1 is cheapest (median 40
  turns, $1.80), A2 is most expensive (78 turns, $3.21), and the rest sit near A0 (58.5 turns, $2.08).
- **Spread (co-primary 3) is not clearly better in any arm** at n=9–10.

## 2. What the talk can honestly claim

- Machine checks alone do not discriminate here. Every arm, including the no-skill control, passes
  (the floor effect the pre-reg predicted).
- A judgement-style oracle calibrated to 91.7% detection and 8.3% false positives still found almost
  no arm differences. Two criteria carry everything.
- Public skill files showed no measurable benefit on this package, this model and this oracle. That
  is a null, not proof of no effect.
- What it cannot claim: anything about other packages, other models, or human review outcomes
  (n = 1 package, 1 agent, 1 model version).

## 3. Design lessons (for the next experiment)

1. **The oracle floored, as the pre-reg warned, but the seed was live on the machine side.** The
   seed carried four machine-detectable defects (missing NAMESPACE, license template, DESCRIPTION
   metadata, unused imports). Every completed run in every arm, A0 included, repaired all four with
   no regressions (57/57). So the floor is a measured success: the agent runs `R CMD check` against
   itself. What was *not* live was the judge side: ~9 applicable criteria per tree, only two ever
   fired. Next time, seed judge-only defects too, so they can discriminate.
2. **Seed design: one unrepairable constant dominates.** C13 (employer email) is a fact the agent
   cannot know to change, so it fires in every tree. It consumes the judge's dynamic range. Exclude
   constants from the judged set, or report them separately.
3. **A4 "upper bound" assumes the instrument can see the gap.** Since A4 didn't separate, the
   experiment has no positive control that proved sensitivity. Add a deliberately handicapped arm
   (e.g. a misleading skill) so a null can be distinguished from a blind instrument.
4. **One judge rep per tree.** Calibration used 3 reps; the arm panel used 1. L08 variance between
   arms suggests judge noise, and one rep can't separate that from arm effect.
5. **Single-criterion A5 effect is uninterpretable on its own.** A5 changed the maintainer email in
   7 of 9 runs, and no other arm did. §8's "context volume vs content" reading does not apply
   cleanly to a single criterion. Check what the raw handbook text says about maintainer email
   before drawing any conclusion.

## 4. Process / protocol lessons

1. **Rate limits were the biggest operational threat.** Batching blocks into one `orchestrate.sh`
   call produced an escalating 429 cascade on every attempt in blocks 6–10. Each needed manual
   cleanup and resume. Three block-3 runs ended on 429 (A1 at 10 turns; A2 and A5 at 1 turn, $0) and
   were never rerun. *Next time: pace blocks one at a time, and use cumulative `usage.json` to back
   off proactively (both already in `LATER.md`).*
2. **Infrastructure failures need a pre-registered category.** §7 defines non-completion only as
   `BUDGET_EXHAUSTED` / `STUCK_LOOP`. A 429 is neither, and the decision to exclude or rerun had to be
   made after seeing data. Pre-register "infrastructure failure: excluded, rerun, n reported".
3. **Sample size was extended after an interim unblinded look** (n=5 → 10/arm, 2026-09-28). This is
   post-hoc and must be disclosed as such. Do not present n=10 as pre-registered.
4. **Isolation leaks were found by piloting, not by design.** The block-1 pilot exposed (a) the
   `cran-exp-runs` substring leaking through `env`/`PWD` (fixed by renaming to `sandbox`),
   (b) arbitrary filesystem reads from inside an arm (fixed by `hooks/path_confinement_guard.sh`),
   and (c) `EXP_ROOT`/`RUNS_ROOT`/`OLDPWD` env leakage (fixed by `env -u` in `run_arm.sh`). Keep the
   pilot; it paid for itself.
5. **The harness must distinguish a real result from a failure stub.** The judge panel's
   `[ -f out ]` skip check accepted session-limit error stubs and 0-byte files from killed processes.
   It now has `is_valid_judge_output()`. Validate outputs by content, not by existence.
6. **Environment changed mid-design.** Docker was dropped (no nested virtualization on the cloud PC)
   and the toolchain was installed natively. Provenance records still carry
   `image_digest=REPLACE_WITH_DIGEST` and a blank `r_version`. The writeup should say
   `ENVIRONMENT.md` supersedes them.
7. **The blinding lock worked.** The blind map's SHA-256 was recorded in the lock commit and
   verified unchanged at unblinding. Keep this pattern. Note that the map legitimately contains
   duplicate rows from resumes, and dedupe on join.
8. **Git Bash and Windows Python disagree on paths** (`/c/...` vs `C:/...`). Budget for this in
   cross-tool scripts.

## 5. Suggested narrative framing (for the presentation pass)

1. The claim and why it is worth testing (skills are everywhere, evidence is thin).
2. Why a measurement instrument, not a demo: blinding, frozen prompt, fresh trees, interleaving.
3. The first finding is about measurement: machine checks floor, so the judge carries the result.
4. The result: no separation, including the hindsight oracle A4.
5. What would change the answer: a seed with live judge-only defects, a handicapped positive-control arm,
   multi-rep judging, and other packages.
6. Declared limitations, stated plainly and early, including the post-hoc n extension.

## 7. Talk-construction decisions (2026-10-06)

Recorded during the presentation pass, before bundling the deck for transfer.

1. **Narrative reframed to follow the real chronology.** The deck now runs:
   agentic refactoring of PhD code → CRAN prep → two human-review rejections →
   acceptance → *then* the counterfactual question ("would a skill file have got
   us there in one shot?"). Previously the question slide led with the
   literature hedges; those moved to a footnote. The motivation is our own
   submission history, not a gap in the literature.

2. **Per-defect repair rates are now reported, not just the all-four count.**
   All four seeded defects were repaired in **57/57** runs, including
   `license_template` — the defect corresponding to real rejection **R02**.
   This is a sharper statement of the null than "n_seed/n_runs fixed everything"
   and it directly answers "did the skills fix the LICENSE?": yes, and so did
   the control.

3. **R01 (`set.seed()`) was present in the seed; the scoring rule missed it.**
   An earlier version of this entry said R01 "was never seeded". Wrong. The seed
   carries `seed = 42` as a default and an unconditional `set.seed(seed)` in
   `orthoMTL`, `cv_orthoMTL` and `simulate_mtl` (and the default in `bootstrap_orthoMTL`) -
   the pattern in the baseline's `cran-comments.md`. `R01_seed_in_function.R`
   only flagged a literal inside a body, so `seed_audit.json` never saw it and
   the §4.8 "zero hits, true negative" validation of the seed was wrong.
   Fixed 2026-10-06: the rule now also flags numeric-default formals reaching
   `set.seed()`, plus a companion `seed_numeric_defaults()` for trees that keep
   the default but route it through a helper. Validated on 8 synthetic cases,
   the seed (3 hits), baseline and control (0), `MUT-R01` (1). Original results
   untouched; re-score in `scoring/results_r01v2/r01_rescored.csv`
   (`scoring/rescore_r01.R`). Completed runs, direct hit / default kept via
   helper / canonical `NULL` fix: A0 6/4/0, A1 1/8/0, A2 1/1/7, A3 3/7/0,
   A4 4/6/0, A5 1/0/8. Descriptive only (n=9-10). The "default kept" class
   (e.g. `local_seed()` restoring `.Random.seed`) is a judgement call whether
   CRAN would accept it. Not yet hand-verified tree by tree beyond spot checks.
   Consequence: the "all arms identical" framing holds for the four seeded
   defects and C13, not for R01. A4 (written from the rejection history) did not
   produce the canonical fix in any run.

4. **The maintainer-email ("Novartis address") observation is NOT new.** It is
   criterion **C13**, already in the corpus, and per §1 it is flagged by the
   judge in **every tree except A5** — i.e. it was found *during* the experiment,
   not later by a newer model. Any postscript slide must say so. Framing it as a
   fresh discovery would misrepresent our own results.

5. **C13 is not a policy violation.** CRAN policy requires "a single designated
   maintainer (a person, not a mailing list)" whose address is current and
   usable "without any form of filtering". `kevin.vervier@novartis.com` is a
   person, so it is compliant today; the exposure is corporate mail filtering
   and employer change. The talk must say "not a violation today" out loud.
   Verified against `snapshot/cran-repository-policy.txt` (lines 52-58) and the
   Cookbook's `description_issues.qmd`. Slated for change in **0.2.0**.

6. **PDF build route is unresolved and cost us the artefact.** `quarto render
   --to pdf` on a revealjs deck goes down the LaTeX path, which wiped the
   tracked `talk/talk.pdf` and then failed (no TeX on this host). The correct
   route is HTML + a headless-browser print (decktape or Chrome/Edge
   `--print-to-pdf` over `talk.html?print-pdf`); neither node/npm nor Chrome is
   installed here, only Edge. `talk.pdf` is currently staged as deleted and must
   be restored or rebuilt on the target machine. **Do not run `--to pdf` on this
   deck again.**

## 8. Open decisions before the writeup

- Rerun or exclude the three 429 block-3 runs, and how to label them.
- Whether to report C13 separately (constant, not skill-responsive) and recompute judge counts
  without it.
- Whether to investigate the A5 and C13 difference or list it as an unexplained observation.
- Commit `unblinded_results.csv`, `scoring/unblind_join.py` and this file (not yet committed).
