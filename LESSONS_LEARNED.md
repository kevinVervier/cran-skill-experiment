# Lessons learned — CRAN skill-file experiment

*Written 2026-09-30, immediately after unblinding. Source: unblinded results
(`unblinded_results.csv`), `PRE_UNBLINDING_LOCK.md`, project memory notes, and `LATER.md`.
Descriptive only; no significance testing (pre-reg §8).*

## 0. Correction (2026-10-08): arm A4 was never delivered — it is a second control

**Read this before anything below.** Sections 1–13 were written when A4 was believed to be a
hindsight skill arm. It was not. Evidence, all from the run logs and git history:

| Arm | First-API-call context, tokens (all 10 runs) | Instruction file |
|---|---|---|
| A0 control | 7,145 | none |
| **A4** | **7,145** | **none, in any run tree, `arms/A4/pkg`, or git history** |
| A3 / A2 / A1 / A5 | 8,233 / 9,693 / 12,810 / 32,088 | `CLAUDE.md` (2.7 / 6.4 / 14 / 76 KB) |

Cause: the Phase 0 build left A4 "intentionally untouched" for Kevin to write; the freeze
checklist (pre-registration §13) had no box confirming it existed; `run_arm.sh` guards only that
the control has no file, never that instructed arms have one. Nothing caught it for 60 runs.

Consequences:
- **A4 is a second control.** Controls are n=20 (A0 + A4). "A4 ties A0" meant A0 tied A0.
- **The oracle / upper-bound / "cheat arm" framing is void**, here and in the talk. There was
  never a positive control. This is the strongest form of the §3.3 limitation.
- **The null is intact and cleaner:** none of the four skill files (A1, A2, A3, A5) beat a
  20-run control on the seeded defects. A0 vs A4 also gives a free noise estimate (R01: A0 6/4/0,
  A4 4/6/0 — same distribution, different runs).
- **R01 lead is slightly sturdier:** 0 canonical fixes in 20 control runs vs A2 7/9 and A5 8/9
  (post-hoc, descriptive, no test).
- Skills were delivered as always-loaded `CLAUDE.md` files, not through the on-demand `Skill`
  tool (which was not available to the agent). "Skill file" in this study means that.
- Also to disclose: Claude Code auto-updated during the experiment (recorded 2.1.276; runs used
  2.1.282 ×18, 2.1.283 ×31, 2.1.284 ×11). Models: agent `claude-opus-5-5`, judge `claude-sonnet-5`.

Remedy: `supplementary/` — a post-hoc paired run of a delivered A4 against fresh A0 controls,
with `check_arm_loaded.sh` as a manipulation check. Reported separately, never pooled.

Decision (2026-10-09, Kevin): in the talk the 10 undelivered-A4 runs are **pooled as A0 (n=20)**,
not dropped, and the deck says "five conditions". The 57-run analysis is unchanged otherwise. The
relabelling was made after unblinding, on instrument-failure grounds (first-call tokens), not on
outcomes.

Supplementary result (blocks 11-13, 21-24, 26-28 = 10 matched pairs; blocks 14 and 25 lost their
A0 partner to a 429, so their A4 runs are unpaired extras; Claude Code 2.1.294; labels known; no
judge panel). R01 via `scoring/rescore_r01.R`: fresh A0 0 canonical / 6 default kept / 4 hard-coded;
delivered A4 10/0/0 (12/12 with the extras). R02 (LICENSE) repaired in every tree, both arms. `R CMD check` (`extract_findings.R`, 22 trees): 0 errors and 0 warnings everywhere; residual burden 0 in 21, 1 in one A0 tree (block 28, `description_meta`); no arm separation. Scores: `supplementary/results/`. This
is a ceiling check — the file quotes the reviewer and names `seed = NULL` — and an after-the-fact
positive control, NOT evidence that the blinded run would have shown the same. A0 block 23 ended
`OTHER_success` (91 turns, no DECLARED_DONE marker): kept; it does not change the counts.

## 1. Headline result (lead with the uncomfortable part)

- **No detected effect of any skill file on conformance.** Across the 57 completed runs, residual
  review burden is 0 above baseline in every run. The floor rule (§7) applies: report it and move on.
- **~~The hindsight oracle (A4) does not separate from the A0 control.~~ [Superseded, see §0:
  A4 had no instruction file; it is a second control.]** The original text called this the most
  uncomfortable result. The truer uncomfortable fact is that the experiment never had a positive
  control.
- **The judge signal is two criteria.** All NON_COMPLIANT verdicts come from C13 (employer-domain
  maintainer email, 47) and L08 (quote style, 23). C13 fires in 47/57 trees; the 10 COMPLIANT
  verdicts are 7 A5 plus one each A2/A3/A4. L08 looks like judge noise.
- **Correction (2026-10-07): the C13 variation is judge adjudication, not arm behaviour.** An
  earlier version of this section said A5 "changed the maintainer email in 7 of 9 runs". That is
  wrong. In all 57 completed runs — every arm, including all 9 A5 runs — the maintainer address is
  still `kevin.vervier@novartis.com`; no arm ever edited it. What varies is the judge's reasoning:
  in the 10 COMPLIANT trees it excuses the corporate domain by pointing at the copyright holder
  ("matching the listed copyright holder Novartis Pharma AG", "company-sponsored package"), and 7
  of those 10 happen to be A5. C13 is under-specified — it does not say whether a `cph` match
  justifies an employer domain — so it measures judge variance, not conformance. See §3.5 and §9.
- **No arm checks early.** Median turn of first `R CMD check`: A0 184, A1 140, A2 272, A3 157,
  A4 115, A5 190, with heavily overlapping ranges. The "skill arms check early" mechanism is not in
  the data.
- **Efficiency differences are modest and confounded by skill length.** A1 is cheapest (median 40
  turns, $1.80), A2 is most expensive (78 turns, $3.21), and the rest sit near A0 (58.5 turns, $2.08).
- **Spread (co-primary 3) is not clearly better in any arm** at n=9–10.

## 2. What the talk can honestly claim

*Revised 2026-10-07 after §9 and §10. The headline is no longer "no effect"; it is "the instrument
could not have seen one."*

- **The machine-check result stands and is unaffected by the judge problems.** It came from
  `R CMD check`, not the oracle. Every arm, control included, repaired all four seeded defects
  (57/57). Machine checks alone do not discriminate here — the floor effect the pre-reg predicted.
- **The judge panel added no sensitivity on top of it.** Ten of its twelve criteria never fired;
  the two that did measure judge adjudication of unchanged text (§10). Calibration at 91.7%
  detection / 8.3% false positives did not survive contact with the arm panel at one rep per tree.
- **So the honest claim is about measurement, not about skill files.** "Public skill files showed
  no measurable benefit on this package, this model and this oracle" is true but understates it:
  this oracle could not have detected a benefit if one existed. That is a null *instrument*, which
  is a stronger and more useful statement than a null result.
- **The uncomfortable corollary, stated first per §12.** Without a positive control (§3.3), a null
  from a blind instrument is indistinguishable from a true null. We cannot separate them.
- **R01 is a genuine open thread, not a win.** It is the one place arms differ (§3.5). Report it as
  a lead with its caveats attached — post-unblinding re-score, one criterion, n=9–10, no test, and
  the controls (A0, plus A4 which had no file, §0) produced the canonical fix zero times in 20
  runs, so this is a lead worth testing, not a result.
- **What it cannot claim**: anything about other packages, other models, other rubrics, or human
  review outcomes (n = 1 package, 1 agent, 1 model version, 1 judge rep).

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
3. **There was no A4 upper bound (§0).** A4 was never delivered, so the experiment has no positive
   control that proved sensitivity. Add a manipulation check that each instructed arm's context
   exceeds the control's (`supplementary/check_arm_loaded.sh`). Add a deliberately handicapped arm
   (e.g. a misleading skill) so a null can be distinguished from a blind instrument.
4. **One judge rep per tree.** Calibration used 3 reps; the arm panel used 1. L08 variance between
   arms suggests judge noise, and one rep can't separate that from arm effect.
5. **Single-criterion A5 effect is uninterpretable on its own — and on C13 it is not an arm effect
   at all.** *Revised 2026-10-07.* The original entry said A5 changed the maintainer email in 7 of 9
   runs. It did not: no arm ever changed it (§1). The follow-up suggested here — "check what the raw
   handbook says about maintainer email" — was done and came back empty: the handbook's only
   relevant line is `description_issues.qmd:178` ("make sure the provided email address is actively
   monitored"), which says nothing about employer domains and cannot explain A5. The C13 split is
   judge adjudication of a `cph`-matched corporate address.

   The genuine single-criterion arm effect is **R01**, where A2 (7/9) and A5 (8/9) reach the
   canonical `seed = NULL` fix and A0/A1/A3/A4 essentially never do. Here the handbook *does*
   contain the answer verbatim: `code_issues.qmd:53-83` ("Setting a Specific Seed") carries the
   exact `function(..., seed = NULL){ if(!is.null(seed)) set.seed(seed) }` pattern and the
   instruction "Ideally, the argument is already set to `NULL` per default", under a CRAN reviewer
   quote matching the real R01 rejection. But that text sits in `snapshot/`, readable by **every**
   arm including A0, so handbook availability alone does not explain the split. A5 is the arm with
   the handbook front-loaded into context rather than merely pointed at, which is the pre-reg §3
   "front-loading, not distillation" reading; A2's route is unconfirmed (its skill file is not on
   this host). Descriptive, one criterion, n=9. Do not present as established.

## 4. Process / protocol lessons

1. **Rate limits were the biggest operational threat.** Batching blocks into one `orchestrate.sh`
   call produced an escalating 429 cascade on every attempt in blocks 6–10. Each needed manual
   cleanup and resume. Three block-3 runs ended on 429 (A1 at 10 turns; A2 and A5 at 1 turn, $0) and
   were never rerun. *Next time: pace blocks one at a time, and use cumulative `usage.json` to back
   off proactively (both already in `LATER.md`).*
2. **Infrastructure failures need a pre-registered category.** §7 defines non-completion only as
   `BUDGET_EXHAUSTED` / `STUCK_LOOP`. A 429 is neither, and the decision to exclude or rerun had to be
   made after seeing data. Pre-register "infrastructure failure: excluded, rerun, n reported".
   *Resolved for this experiment 2026-10-07 (§11): excluded, not rerun, reported separately; n=57.*
   Two design requirements for next time: (a) the category must be defined **before** the first run,
   with the exclude-or-rerun rule fixed in advance, so the decision cannot be contaminated by seeing
   which arms failed; (b) a rerun policy only works if replacements keep their position in the
   block-randomised schedule — a run replayed weeks later under different rate limits is not the
   same experimental unit, which is why rerunning was rejected here.
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

*Revised 2026-10-07. The arc now ends on verification as the bottleneck, with the instrument's own
failure as the evidence. Not a spin on a null — a reweighting toward what was actually learned.*

1. The science and the shipped artefact: joint vs separate task learning → `orthoMTL`, on CRAN.
   This is the credibility deposit the rest of the talk spends.
2. The counterfactual question, from our own submission history: would a skill file have got us
   there in one shot?
3. Why a measurement instrument, not a demo: blinding, frozen prompt, fresh trees, interleaving,
   a pre-registered design and a hindsight-oracle upper bound. **The methodology is a contribution
   independent of the result** — most claims in this space are untested.
4. The result: zero separation of any skill file from the control (A4 was a second control, §0).
5. **The turn, and the real finding:** the judge panel that was meant to see past `R CMD check`
   had ten of twelve criteria never fire, and the two that did were the judge arguing both sides
   of text no arm had touched (§10). Found *after* unblinding by reading evidence strings nobody
   had to read. The counts looked like a clean two-criterion signal; only the free-text
   justifications exposed it.
6. The transferable lesson: executable oracles beat prose guidance. `R CMD check` floored because
   it works. Judgement criteria that are not operationally defined measure the judge. Anyone
   building an agentic pipeline has this problem.
7. Limitations plainly and early, including the post-hoc n extension and the missing positive
   control. R01 offered as an open lead, explicitly not as support for the headline.
8. Close on verification as the bottleneck — the thesis, not a sign-off.

**Tone discipline.** This audience has sat through nulls dressed up as insights. The engagement
comes from refusing to do that: lead with the shipped package, state the zero without hedging,
then show the instrument failing and say what it cost. Do not let the positive frame quietly
reinstate R01 as a win (§2).

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
   defects and C13, not for R01. A4 had no instruction file (§0) and, like A0,
   did not produce the canonical fix in any run.

   **On defending the post-unblinding timing (added 2026-10-07).** The objection to answer is
   "you re-scored after seeing the labels." The answer has three parts, in this order: (1) the
   original rule was wrong in a demonstrable way — it returned **zero hits on the seed itself**,
   a detector that cannot see the defect it was built for; (2) the correction was to the detector,
   not to the direction of the result; (3) `rescore_r01.R` takes a tree path and returns hits, is
   a pure function of package file content, and never reads `.blind_map.csv` — **the same code run
   at first unblinding would have produced the identical table.** Arm labels cannot have influenced
   it because the code never sees them. Validated on 8 synthetic cases, the seed (3 hits), baseline
   and control (0), and `MUT-R01` (1).

   This does not make R01 a skill-file win, and the talk must not present it as one: one criterion,
   n=9–10, no test; the controls (A0 and the file-less A4, §0) produced the canonical fix zero times
   in 20 runs. Still a post-hoc lead, not a skill-file win. Report it as the most interesting
   loose end in the dataset (§2).

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

## 9. The C13 mechanism (2026-10-07)

Why the judge split on C13, established from the 57 completed runs' judge evidence strings
(`scoring/results/*/judge_rep1.json`; the blinded trees themselves are not on the current host).

1. **The address is identical everywhere.** All 57 evidence strings quote
   `kevin.vervier@novartis.com`. No arm in any run edited it.
2. **The copyright holder is the hinge, and the judge uses it both ways.** Novartis Pharma AG is
   listed as `cph` in every tree. The judge invokes it in 20 of 57 verdicts — as *mitigating* in 8
   of the 10 COMPLIANT ones ("plausible institutional address matching the cph", "company-sponsored
   package") and as *aggravating* in 12 NON_COMPLIANT ones ("corporate domain tied to Novartis
   Pharma AG, also listed as copyright holder; such addresses are not durable"). Same fact,
   opposite valence. The clincher is within A5: its own 2 NON_COMPLIANT runs both cite the cph, as
   aggravating.
3. **So there is no tree-content trigger to find.** The split is not caused by a DESCRIPTION or
   `inst/COPYRIGHTS` difference between arms — the inputs agree. It is one under-specified criterion
   resolved inconsistently at one judge rep per tree. A5's 7/9 is a cluster in judge noise, not an
   arm effect.
4. **Consequence for the design.** This is §3.4 ("one judge rep per tree") biting on a second
   criterion, after L08. A criterion that admits a mitigating reading the rubric does not adjudicate
   will produce arm-shaped noise. Next time: state in the criterion whether an employer domain
   matching the `cph` is acceptable, and use ≥3 reps so within-tree variance is measurable.

## 10. The judge panel had no working discriminator (2026-10-07)

Established from `scoring/judge_criteria.json` and the 57 completed runs' judge evidence. This
supersedes §1's "the judge signal is two criteria" by explaining what those two criteria actually
measured. It is the strongest available statement of why the experiment detected nothing.

### 11.1 Only 2 of 12 criteria ever fired

| | criteria | ever NON_COMPLIANT |
|---|---|---|
| HANDBOOK | 3 | 0 |
| COMMUNITY, explicit provenance | 1 | 1 (C13) |
| COMMUNITY, inferred provenance | 8 | 1 (L08) |

Six criteria (C04, C08, L09, L10, L12, L27) returned COMPLIANT in all 57 trees — constant, zero
discriminating power. Four more were NOT_APPLICABLE in nearly every tree (C18 55/57, L23 54/57,
L06 49/57, L21 2/57). The panel's effective width is 2 of 12; after excluding C13 per §11 it is
**one** criterion, and that one is inferred-provenance.

This is the §3.1 floor effect repeating on the judge side. The pre-registration anticipated the
machine checks flooring and expected the judge to carry the result; the judge floored too.

### 11.2 Provenance is thinner than §1 implied

Of the 9 COMMUNITY criteria, **8 carry `prov_inferred: true`** — every row sourced from
`criterion-corpus-longtail.md`, which has no PROV column at all. `_meta.prov_note` states the
inference openly: that file's contents are scraped from `cran-comments.md`, GitHub threads and
r-package-devel archives, so by construction they are not derivable from the handbook snapshot the
arms received. The inference is recorded rather than silently assumed, which is the right call.

`_meta.letter_note` is the sharper problem: **no JUDGE row is tagged LETTER**, because both real
orthoMTL findings (R01, R02) are ORACLE=STATIC. The judge carries zero of the two known
ground-truth findings. Everything it scored was handbook-general or folklore, never a documented
cause of our actual rejections.

### 11.3 L08 fails the same way C13 does, more blatantly

L08 hinges almost entirely on one seed string, present unchanged in every tree:
`A patient is considered "uncensored" only if all task labels are non-NA` (`R/metrics.R:24`,
`man/cindex_mtl.Rd:34`).

- 22 of the 23 NON_COMPLIANT verdicts cite that exact line as emphasis quoting.
- **2 COMPLIANT verdicts cite the same line and excuse it** — "double quotes only around the
  technical term to define a concept, not for emphasis" / "used only for code/class-name literals".
  Same file, same line, opposite verdict. This is the C13 both-ways pattern (§9.2) repeated.
- The other 29 COMPLIANT verdicts **never looked at `metrics.R`**: they checked DESCRIPTION, found
  no double quotes, and declared compliance.

So L08 is a compound of three things, none of them a property of the arm: whether the judge searched
beyond DESCRIPTION, and if it found the line, which of two defensible readings it picked. A1's 0/9
NON_COMPLIANT is not A1 fixing anything — the judge simply never opened the file in any A1 run.

### 11.4 What this means for the result

Both signal-carrying criteria are now explained as judge variance rather than conformance. The null
is therefore stronger and differently framed: not "no effect was detected" but **"the judge panel
had no criterion capable of detecting one."** An instrument with one noisy binary left cannot
distinguish a true null from blindness — which is §3.3's missing-positive-control problem arriving
from a second direction.

## 11. Open decisions before the writeup

- ~~Rerun or exclude the three 429 block-3 runs, and how to label them.~~ **Resolved 2026-10-07:
  exclude, do not rerun, report as a named infrastructure category.** The three are
  `A1_r3_b3` (10 turns, $0.59, `COMPLETE_FINDINGS`), `A2_r3_b3` and `A5_r3_b3` (1 turn, $0.00,
  `FAIL_PACKAGE`) — all block 3, all `API_ERROR_api_error_429`. Analysed n stays **57 of 60**.

  *Why exclude rather than rerun.* A rerun now would execute under a different rate-limit regime and
  a later wall-clock position than every other run, breaking the block-randomised interleaving that
  invariant 6 exists to protect. Three replacement runs scored after unblinding would also be the
  only runs in the experiment whose results were produced with the arm labels known. Excluding
  costs almost nothing: A2 and A5 died at 1 turn having spent $0.00, so there is no agent behaviour
  in them to recover, and A1 at 10 turns is well short of its arm median of 40.

  *Why this is not a silent drop.* §4.2 already records that the pre-registration has no category
  for this: §7 defines non-completion as `BUDGET_EXHAUSTED` / `STUCK_LOOP` only, and a 429 is
  neither — it is the API refusing service, not the agent failing. So these must **not** be folded
  into the co-primary 5 non-completion endpoint, which would misattribute an infrastructure fault to
  arm behaviour. Report them as a separate line: *"3/60 runs lost to API rate limiting;
  infrastructure, not agent behaviour; excluded; n=57 analysed."* The talk already does this orally
  (`talk.qmd`, notes on "What I am *not* claiming").

  *One finding worth keeping from them.* All three carry `judge_nc = 3` and `judge_applicable = 8`
  despite A2 and A5 containing an essentially untouched seed tree. The judge panel scored failure
  stubs as though they were results. That is the §4.5 validate-by-content lesson showing up in the
  arm panel rather than the harness, and it is further evidence for §10: a judge that returns a
  plausible three-criterion verdict on a package that was never worked on is not measuring the
  package.

  *Disclosure.* State the exclusion rule and the n in the same breath as the result, not in a
  footnote. It was decided after seeing which runs failed, which is exactly the post-hoc pattern
  §4.3 warns about — the mitigation is that the rule ("infrastructure failures are excluded and
  reported") is content-independent and applies to all three regardless of arm.
- ~~Whether to report C13 separately~~ **Resolved 2026-10-07: report C13 separately and recompute
  judge counts without it.** Two independent reasons. (a) It is a constant the agent cannot know to
  change, so it is not skill-responsive. (b) Its arm variation is judge adjudication, not arm
  behaviour (§9). Excluding it leaves `judge_nc` at a mean of 0.0–0.78 per run with **L08 alone**
  carrying the residual (A0 3/10, A1 0/9, A2 6/9, A3 4/10, A4 3/10, A5 7/9). **Superseded in part
  by §10:** L08 is not merely noisy, it is the same both-ways judge variance on a single unchanged
  seed string, with 29 of its COMPLIANT verdicts never having opened the relevant file. So the
  recomputation does not rescue the panel — it empties it. Report the C13-excluded counts, but say
  what §10.4 says rather than presenting L08 as a surviving signal.
- ~~Whether to investigate the A5 and C13 difference~~ **Resolved 2026-10-07** — see §3.5 and §9.
  Not an arm effect; no further investigation warranted.
- **New (2026-10-07): decide whether the judge panel is reportable as a measurement at all.** Per
  §10, 10 of 12 criteria never fired and the 2 that did measure judge behaviour, not conformance.
  Options: (a) report the panel as a negative result about the instrument, which is the honest
  reading and fits the talk's measurement-first narrative; (b) report judge results only as a
  descriptive appendix with the §10 caveats attached; (c) drop the judge panel from the headline
  entirely and rest the null on the machine-check floor plus R01. Kevin's call — (a) is the most
  defensible and the most uncomfortable.
- Whether the post-unblinding R01 re-score can carry weight in the talk given it was not scored
  blind, and whether the `default_kept` class needs hand-verification (blocked: the blinded trees
  are not on the current host).
- ~~Commit `unblinded_results.csv`, `scoring/unblind_join.py` and this file (not yet committed).~~
  **Done** — all three are tracked (`bb2d81e`); this file has been amended since in `a141f78`.
