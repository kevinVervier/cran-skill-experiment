# Pre-registration: Does a CRAN skill file change agent-assisted package preparation?

**Status:** DRAFT — frozen before any run. Version this file in git; commit hash of the frozen
version is quoted in the talk.

**Author:** Kevin Vervier
**Target venue:** R/Pharma 2026 lightning talk (10 min)
**Subject package:** `orthoMTL` (accepted on CRAN, 2026)

---

## 1. Claim under test

**Primary claim.** Supplying an agent with a CRAN-specific skill file at project start reduces the
number of *authoring-time-detectable* CRAN rejection findings, relative to the same agent with no
skill file.

**Secondary claim — skill file versus resource.** Because every arm receives the same handbook
snapshot, the comparison is not "guidance versus nothing" but **distilled procedural guidance versus
a pointer to the official documentation**. That is the sharper and more useful question, and the arm
structure (§3, `A0` / `A5` / skill arms) is built to separate front-loading from distillation.

**What this is not.** This is a demonstration with replicates on a single package, not a trial. It
cannot support a claim about CRAN preparation in general, about other packages, or about other
agents. Single-package, single-agent, single-model. State this on the slide.

**Pre-committed fallback framing.** If arms overlap (see §8), the finding is:
*generic public skill files do not transfer to package-specific CRAN failure modes; the effect is
carried almost entirely by hindsight.* That is a more useful result for the audience than a
ranking, and it is what the oracle arm (§3) is designed to quantify.

---

## 2. Starting state

**Origin commit `C0`:** the first commit of `Novartis/orthoMTL`, the CRAN-targeted successor to
`kevinVervier/orthopen`. Chosen because it requires no judgement call and cannot be accused of
having been selected after seeing results.

Fallback, pre-registered: if the first commit is a scaffold with no installable package
(`DESCRIPTION` plus `R/` with at least one function), `C0` is the first commit that has one. See
`seed-and-pilot.md` §0 for the verification and the leak checks.

`C0 SHA = 681675f201c810eca668c0528996aaf24b432e0e` (resolved 2026-09-18; frozen)

The literal first commit (`065d361ed0c5a6b3f32325f7490b74930538b5a6`, "Initial commit") is
scaffold-only — `.gitignore`, `LICENSE`, `README.md`, no `DESCRIPTION` or `R/`. Per the fallback
rule, `C0` is the next commit, "initial push from internal to external repo" (2026-06-01), which
carries a full `DESCRIPTION` and populated `R/`. See `seed-leak-audit.txt` in this directory for the
grep verification output.

**Construction of each arm's working tree:**

```bash
git archive C0 | tar -x -C arms/<arm_id>/pkg    # no .git — history is not exported
```

`git clone` at a commit is **not** acceptable: the agent can walk the history forward and read the
fixes. Export a tree.

**Leakage strip list.** Remove from every exported tree if present at `C0`, and confirm by grep:

- `cran-comments.md`
- `NEWS.md` / `NEWS`
- any CRAN correspondence, submission notes, reviewer emails
- `TODO`, `NOTES.md`, planning docs referencing CRAN findings
- CI configs that encode later-added check flags
- `.Rbuildignore` entries added downstream (inspect diff `C0..HEAD`)

**Verification step (must pass before any run):** grep every exported tree for each rejection-ledger
keyword (§4). Zero hits required. Log the grep output.

---

## 3. Arms

| ID | Arm | Role |
|----|-----|------|
| `A0` | No skill file | **Control.** Current model, no guidance. |
| `A1` | `cran-extrachecks` (posit-dev/skills, `r-lib/`) | **Checklist.** CRAN-specific, aimed at ad-hoc requirements `devtools::check()` misses |
| `A2` | `cran-submit` (CoryMcCartan/agent-skills) | **Process + adversarial.** Six-phase workflow with built-in self-review |
| `A3` | `r-package-development` (posit-dev/skills, `r-lib/`) | **General.** R package craft, not CRAN-specific |

**Two independent CRAN skills exist, and they embody opposite philosophies.** That contrast is more
informative than three interchangeable files:

- `cran-extrachecks` is a **checklist**: documentation completeness, DESCRIPTION formatting, URL
  validation, administrative compliance. Declarative — here are the things to verify.
- `cran-submit` is a **process with an adversarial step**: it instructs the agent to act as a strict
  reviewer hunting for any reason to reject, and stages the work across six phases explicitly to
  minimise resubmission cycles.

**Pre-registered prediction.** Given that every real submission passed the automated gate and failed
human review, a skill that builds in adversarial self-review should outperform a checklist on the
judgement panel. If `A2` beats `A1` on `COMMUNITY` criteria and rounds while matching it on
`HANDBOOK`, that is the mechanism claim: *what a skill file buys is not a list, it is a review step.*
Record this prediction before running — a confirmed pre-registered prediction is worth far more in a
talk than a post-hoc explanation of whichever arm won.

**`A3` is the specificity control** — general R packaging craft with no CRAN targeting — so any `A1`
or `A2` advantage can be attributed to CRAN specificity rather than to guidance in general.

| | Guidance | Specificity | Adversarial step |
|---|---|---|---|
| `A0` | pointer to docs | — | no |
| `A5` | raw handbook text | undistilled | no |
| `A3` | distilled | general R packaging | no |
| `A1` | distilled | CRAN submission | no |
| `A2` | distilled | CRAN submission | **yes** |
| `A4` | distilled | this package's own history | (as written) |

**Survey notes, for the methods slide.** Of six candidate sources reviewed: one was a personal
package wishlist with no CRAN content; one was a meta-skill for *generating* package skills, not for
submission; one was `cran-extrachecks` repackaged under another name on a skill marketplace; one
repository returned 404. Two independent CRAN skills and several general R-packaging skills remain.
The scarcity is itself a reportable observation — CRAN-specific agent guidance barely exists in
public.

**Declared overlap risk.** Both CRAN skills target the same ad-hoc-requirement space the judgement
oracle's `COMMUNITY` criteria are drawn from. Before scoring, compute the overlap between the frozen
criterion list and each skill's content, and report it per arm. High overlap means that arm's
`COMMUNITY` result carries the caveat or is reported on the `HANDBOOK` panel only.
| `A4` | Kevin's skill file, written from `orthoMTL`'s own rejection history | **Hindsight oracle — not a competitor** |
| `A5` | Raw handbook dumped into context, unabridged | **Distillation control** — see below |

**On `A5` — this arm replaces the length-matched placebo.**

Every arm already has the handbook available at a path. `A5` instead loads the handbook *text
itself* into context up front, unabridged, as an instruction file. That isolates the two things a
skill file actually does:

| | Front-loaded into context | Distilled and procedural |
|---|---|---|
| `A0` | no (pointer only) | no |
| `A5` | yes | no |
| `A1`–`A3` | yes | yes |

- If `A5` ≈ `A0`: front-loading alone buys nothing; the value is in distillation.
- If `A5` ≈ skill arms: distillation buys nothing; skills are just context injection, and a
  `cat handbook >> CLAUDE.md` would do.
- If `A5` sits between: both contribute, and you can say by how much.

It also does the placebo's job — controlling for context volume — with realistic rather than
irrelevant content, and it answers the question an R/Pharma audience will actually ask: *why write a
skill file instead of pointing the model at the docs?*

Prefer this over a length-matched nonsense file. If budget forces a choice, drop the nonsense
placebo, not this.

**On `A4`.** This arm is fitted on the test set by construction. It is reported as an *upper bound
on the achievable effect*, labelled as such on every figure, and excluded from any ranking. Its
value to the talk: it separates "a skill file helps" from "knowing the answer helps." If `A4` is
also weak, the honest conclusion is that the bottleneck is not guidance.

**On the historical run.** The original development was **not** an autonomous agent run. It involved
a human in the loop enforcing compliance manually, two rejection rounds, and an external information
injection — CRAN staff supplied their handbook link after submission 2. It differs from every arm in
model version, process class, *and* information available over time.

It is therefore **not a reference line and must not be plotted.** It is the motivating narrative:
the story you open the talk with. Any attempt to put it on the same axis as the arms invites — and
deserves — an objection you cannot answer.

**What it does establish** is the claim under test. The manual enforcement was *your* labour. The
hypothesis is that a skill file substitutes for it. That reframes the endpoint (see §7).

**`A5` decision:** include / exclude — `____________`. Cheap insurance against the "any extra
context helps" objection, at the cost of one more arm's compute.

---

## 4. Conformance oracle: tooling-defined, history-validated

**Design principle.** The oracle is the check tooling, not a hand-curated prose ledger, and not a
diff against the accepted version. Deriving findings from `C0..HEAD` would bias toward whatever was
visible as a diff and would reinstate the similarity endpoint rejected in §7 — scoring "converged on
my fix" rather than "avoided the failure." Nothing is submitted to CRAN.

### 4.1 The frozen check suite

Fixed invocation, fixed order, fixed versions, identical for baseline and all arms:

| Tool | Invocation | Catches |
|------|------------|---------|
| `R CMD check --as-cran` | flags: `____` | the bulk of incoming checks |
| `urlchecker::url_check()` | | dead / redirecting URLs in docs |
| `spelling::spell_check_package()` | wordlist frozen at accepted version | DESCRIPTION/Rd spelling |
| `rhub::rhub_check()` v2 | platforms: `____` | cross-platform, oldrel, gcc/clang variance |
| `goodpractice::gp()` (optional) | | style/structure; **advisory only, not scored** |

Record the exact version of every tool alongside the environment record (§6) — see `ENVIRONMENT.md`
(2026-09-18 amendment: no container digest exists for this run of the experiment, see below).

### 4.2 Baseline

Run the frozen suite against the **accepted CRAN version** in the pinned environment. Record its
output verbatim. This is the clean reference — not necessarily zero findings, since a pinned
environment may emit NOTEs CRAN tolerated. Any finding present in the baseline is subtracted from
every arm.

**Hard gate — no runs start until this passes.** The baseline must complete `R CMD check --as-cran`
end to end, with the PDF manual and vignettes actually building. That requires the environment to
carry TeX Live, pandoc, `qpdf`, Ghostscript, `checkbashisms`, and **every package in Suggests**.

If the environment is under-provisioned, every arm burns turns fighting the same environmental
problem, and that noise swamps any skill signal. Provision fully and verify before spending budget.

**2026-09-18 amendment — container dropped, native environment substituted.** The pinned-Docker
design (this section, §6, §11) assumed a single frozen image. The host available for this run of
the experiment cannot run one: it is a cloud-hosted Windows instance (Blade/Shadow) without nested
virtualization exposed to the guest, so neither WSL2 nor Hyper-V — and therefore not Docker Desktop
— can start. The toolchain above was installed natively instead, and `verify_env.sh` was adapted
(not weakened) to run without a container. Full specs, exact versions, what changed, and the
declared gaps this introduces (no PPM-pinned snapshot date, no `checkbashisms`, no per-run
filesystem isolation) are in `ENVIRONMENT.md`, which is now the frozen reference in place of an
image digest. Treat it with the same discipline as invariant 9: recorded once, not touched again
once block 2 starts.

**Declared limitation:** doing this removes environment friction that the original process had.
State it. The experiment measures skill effect on package work, not on toolchain wrangling.

### 4.3 Finding extraction

Per arm output tree: run the suite, parse into normalised finding records
(`{tool, severity, category, message_hash, file}`), subtract the baseline set. The remainder is that
run's finding set. Fully automated — no judgement, no unblinding.

Normalisation is the only fiddly part: message text varies by path and filename. Hash on the
category, not the raw string. Write and test this parser **before** any run, on the baseline plus
one deliberately broken tree.

### 4.4 History as validation, not as oracle

Extract the historical rejection findings from your repo and CRAN correspondence. For each, ask one
question:

> Would the frozen suite (§4.1) have emitted this?

| ID | Historical finding | Emitted by frozen suite? | Which tool | Class |
|----|--------------------|--------------------------|------------|-------|
| R01 | `set.seed()` inside a function | **N** | `scoring/static_rules/R01_seed_in_function.R` (static) | `STATIC` |
| R02 | `+ file LICENSE` with boilerplate LICENSE | **N** | `scoring/static_rules/R02_license_template.R` (static) | `STATIC` |

Filled 2026-09-20 from `rejection-ledger.md`'s own per-finding detail (its Tooling/Static
rule/Class rows), not re-derived independently — this table was just out of sync with data that
already existed. The two static rules were validated this session: run directly against
`baseline/pkg`, the seed (`arms/A0/pkg`), and `kevinVervier/orthopen` (fresh clone of the real
9-year-old repo). Both return zero hits on all three — true negatives, confirmed by hand (R01:
every `set.seed` present is either a roxygen example comment or takes a caller-supplied `seed`
argument, never a literal number inside a function body; R02: none of the three trees combine a
GPL-3-family license with `+ file LICENSE` — the seed does, but its `set.seed`/`License` state
matches R01/R02's *absence* correctly, i.e. the rules didn't false-fire on unrelated content). No
tree tested so far actually *violates* R01/R02 (that needs the mutation set, not this validation
pass), so "N" above is asserted from R CMD check's documented behaviour (it does not do RNG-state
or license-content analysis) rather than empirically re-derived by injecting the violation —
flagging that distinction rather than overclaiming it.

- **Y → class Y (detectable).** Confirms oracle coverage.
- **N → class N (tooling-invisible).** Human reviewer policy calls, maintainer-address confirmation,
  judgement on package scope or title wording. **No skill file can be scored on these.** They are
  excluded from the endpoint and reported separately as the ceiling on what any arm could achieve.

The proportion of historical findings in class Y is itself a reportable number: *the frozen suite
covers k of N of the failures that actually happened.* If k/N is low, the honest headline is that
most of this package's CRAN friction was not mechanically detectable — which is a finding, and a
more interesting one than a bar chart.

**This is where manual review is genuinely needed**, and it is bounded: one pass over N historical
findings, done before any arm runs, with no arm output visible. Ambiguous rows get a second opinion.
Everything downstream is automated.

### 4.5 Discovery ledger (second population, separate endpoint)

The project history does **not** primarily record failures. The original agent built a good package
and largely *discovered* CRAN requirements as it went — including by reading the CRAN policy site
mid-project. Two distinct populations must not be conflated:

| Population | Source | What it measures |
|------------|--------|------------------|
| **Rejection findings** | CRAN correspondence, resubmissions | things that got through to submission |
| **Discovery items** | project transcripts / commits | compliance work the agent found on its own |

Discovery items are **not failures**. They are the cost of self-service. This is where the skill
file's actual claim lives: not "prevents errors you couldn't otherwise avoid" but "front-loads
knowledge you would otherwise spend turns discovering."

**Extract from the original transcripts:** for each compliance requirement the agent acted on,
record *what* and *at which turn / commit*. That yields a discovery timeline for the historical run,
and a comparable one per arm. The endpoint is **when** each requirement was addressed, not whether.

Caveat to state on the slide: the historical timeline comes from a different model and cannot be
compared directly to arm timelines. It anchors the *shape* of the discovery process, not the count.
`A0` in this experiment is the comparable baseline.

### 4.6 Local check failures (third population)

Most of the original effort went **before** any submission: repeated local failures to get
`R CMD check --as-cran` to complete or pass. These are neither rejection findings nor discovery
items, and they are the largest cost bucket in the real story.

Log every check invocation per run and classify its outcome:

| Outcome | Meaning | Counts toward endpoint? |
|---------|---------|-------------------------|
| `COMPLETE_CLEAN` | ran to completion, no findings above baseline | — |
| `COMPLETE_FINDINGS` | ran to completion, findings present | yes |
| `FAIL_PACKAGE` | aborted due to the package — broken Rd, failing example, bad DESCRIPTION, vignette error | **yes** |
| `FAIL_ENVIRONMENT` | aborted due to the toolchain — missing system dep, missing Suggests, network | **no — reported separately** |

The package/environment split is the one that matters. A skill file cannot install LaTeX. Excluding
`FAIL_ENVIRONMENT` from the endpoint is a pre-committed decision, not a post-hoc rescue; and if the
§4.2 gate held, these should be near zero anyway. If they aren't, the gate failed and the affected
runs are void.

**`FAIL_PACKAGE` is a genuine skill-sensitive endpoint.** Knowing that examples must run, that
`\value` is required in every exported Rd, that vignettes must build offline — that is exactly what
a skill file carries.

## 4.8 Static-rule oracle — the third class

Findings that the check suite misses are not automatically judgement calls. Some are deterministic
rules that simply no standard tool implements.

Both known findings from the rejection letters fall here: a literal `set.seed()` inside a package
function, and `+ file LICENSE` under GPL-3 pointing at a bare copyright template. Neither is emitted
by `R CMD check --as-cran`; both are a short, exact parse rule.

**Assign every ledger finding to the cheapest oracle that can catch it:**

```
tooling  →  static rule  →  judge
```

Only findings no rule can express reach the judge. This matters more than it first appears: the
judge is the noisiest instrument in the study and the one whose calibration could fail (§5.1.2).
Every finding moved out of it reduces the study's dependence on that calibration.

Static rules live in `scoring/static_rules/`, one file per finding, each returning a list of hits.
They run in the same scoring pass as §4.3 and their output merges into the finding set. Like the
finding parser, they are **written and tested against the baseline and the mutants before any arm
runs** — a rule written after seeing arm output is fitted to arm output.

See `rejection-ledger.md` for the schema, the rules derived so far, and the class roll-up.

**The class ratio is a reportable number.** If most findings land in `TOOLING` or `STATIC`, the study
rests on deterministic oracles and the judge becomes a supplement rather than a dependency — a much
stronger position than §7's floor discussion assumes.

### 4.9 Note on the Y/N line

The line is *detectable by the tooling the agent had access to*, not abstract detectability. Adding
`rhub` moves cross-platform findings into class Y. This is defensible without appealing to CRAN's
internal process, and it must be stated as a design choice rather than a fact about CRAN.

---

## 5. Behavioural oracle (deletion guard)

A clean `R CMD check` is trivially obtainable by deleting functionality. Conformance alone would
reward that. Therefore:

**Frozen held-out test suite.** Take the accepted version's test suite, freeze it, withhold it from
every arm. Strip the exported trees of `tests/` if present at `C0` — or, if tests exist at `C0`,
retain them and hold out only tests added later. Record which.

Run the frozen suite against each arm's output tree. Report pass rate.

**Scope-preservation metrics** (baseline = accepted version):

- count of exported functions
- count of documented examples that execute
- vignette present / builds
- lines of R source (crude, but catches wholesale deletion)

**Joint reporting rule.** An arm that passes `--as-cran` cleanly but fails behavioural tests or
drops exported API is scored as a **failure**, not a win. No single-number summary that could hide
this.

---

## 5.1 Judgement oracle — simulated reviewer

The tooling oracle (§4) cannot see class-N findings: title wording, description prose, scope
judgement, policy calls. Those were real causes of resubmission and are currently unmeasured. A
simulated reviewer recovers them.

### 5.1.1 The circularity problem — address it first

An LLM judge scoring LLM output shares a model family with the thing it scores. Two failure modes:

- **Shared-prior bias.** The judge may favour output that resembles what it would itself produce,
  independent of quality.
- **Criterion echo.** If a skill file's phrasing overlaps the judge's criteria, the score measures
  agreement between two documents, not compliance.

This is the objection the audience will raise. It has to be answered before the result, not after.

Mitigations, all pre-committed:

1. **Different model for judging than for the arms.** Not a different prompt — a different model.
2. **Judge sees the package and the criteria only.** Never the skill files, never the arm identity.
3. **Blinded and order-randomised**, using the same opaque IDs as §9.
4. **Judge replicates.** LLM judgements are noisy; run each tree ≥3 times and report agreement.
   Low inter-replicate agreement is itself a reportable result about judge reliability.
5. **Pinned judge model version**, recorded per scoring run.

### 5.1.2 Calibration — the step that makes this credible

**The judge must be validated against known ground truth before it scores any arm.**

**Constraint established from the submission history:** every submission passed CRAN's automated
incoming gate. Both rejections came from human review; the other CRAN emails were automated
confirmations of successful checks.

This has a consequence that must be stated plainly: **the automated logs contain zero positives.**
Sensitivity cannot be estimated from them. The "easy adversary" is not a calibration set. It is
only a specificity check — the judge should not invent findings on trees that a real automated gate
passed.

Sensitivity therefore needs a constructed positive set.

**Source 1 — mutation injection (the sensitivity test).**

With only two recovered findings, constructed positives are not a supplement — they are the
sensitivity test. Take the accepted version and inject, one at a time, known violations of the
*class* CRAN's human reviewers raise. Each mutant is a labelled positive with a known answer.

Build the mutant list from the criterion corpus, weighted toward the idiomatic-but-wrong class the
two real findings exemplify. The table in `rejection-ledger.md` names ten candidates; ten to fifteen
is enough. Run the judge blind over mutants and unmutated controls in randomised order.

Reported before any arm result: per-mutation detection rate, false-positive rate on unmutated
controls, agreement across judge replicates.

This is mutation testing applied to the oracle itself — the same logic as testing whether a test
suite can detect a deliberately broken implementation.

**Source 2 — the two recovered findings (face validity, not statistics).**

There were two rejection rounds, both human review, yielding two stated objections — a
`set.seed()` call with a literal value inside a package function, and `+ file LICENSE` under GPL-3
pointing at a bare copyright template.

Reconstruct the package state at each and run the judge blind. Report as a qualitative check, both
findings listed individually, with **n=2 stated plainly and no rate attached**. Two items support no
estimate of anything; they establish only that the judge is not blind to the objections this package
actually received.

**Source 3 — the accepted version (specificity).** The judge should return near-clean on the version
CRAN accepted. Persistent findings there are the judge's false-positive floor and are subtracted from
arm scores exactly as the tooling baseline is (§4.2).

**Decision rule, pre-committed.** If the judge detects fewer than half the injected mutations, or its
false-positive rate on controls exceeds its detection rate, it is declared unusable. The judgement
layer then stands as a declared, unmeasured gap — which, given §7's floor expectation, means the
study reports on efficiency and predictability alone. Decide this before looking at arms.

### 5.1.3 Criteria extraction and scoring format

Extract an explicit criterion list from the frozen handbook snapshot (§6.4) plus the four incoming-
check logs. Freeze it. One row per criterion.

Per criterion, the judge returns:

- **`COMPLIANT` / `NON_COMPLIANT` / `NOT_APPLICABLE`**, plus
- **a required evidence citation** — file and line, or the specific text at issue.

Binary with mandatory evidence, not a graded A/B/C scale. A three-level scale invites middle-hugging
and produces scores that cannot be audited; requiring a citation forces the judge to ground each call
in the package and makes disagreements inspectable. `UNCLEAR` is permitted but counted separately and
never scored as compliant.

The criterion list is frozen before any arm runs. Extending it after seeing arm output fits the
scorer to the arms.

### 5.1.4 Criterion corpus and provenance stratification

Augmenting the judge with CRAN community knowledge — mailing-list threads, maintainer blog posts,
well-known folklore — makes it a stronger reviewer than the handbook alone supports. That creates an
information asymmetry with the arms, which only receive the handbook snapshot.

**This asymmetry is an asset, but only if every criterion is tagged with its source.**

| Tag | Provenance | What a score on it measures |
|-----|-----------|------------------------------|
| `HANDBOOK` | derivable from the snapshot every arm receives | did the agent use the documentation it had? |
| `COMMUNITY` | mailing lists, blogs, folklore — **not** in the snapshot | does the skill file carry knowledge beyond the official docs? |
| `LETTER` | the two rejection findings for this package | reserved for calibration; **excluded from arm scoring** |

**Score arms separately on `HANDBOOK` and `COMMUNITY`. Never pool them.**

Pooled, a community-heavy criterion set would penalise every arm equally on knowledge none of them
could reach from the docs, and the offset would be mistaken for "skills don't help." Stratified, the
two panels answer different questions — and the `COMMUNITY` panel is the direct test of what a skill
file is actually *for*: encoding knowledge the official documentation does not contain.

`LETTER` criteria are excluded from arm scoring because they are this package's own answer key.

**Corpus governance:**

- **Every criterion carries a citation** to the source that supports it. Untraceable criteria are
  dropped, not softened. CRAN folklore is frequently stale or specific to one maintainer's
  experience.
- **Prefer criteria appearing in ≥2 independent sources.** Single-source community claims are the
  main false-positive risk.
- **Cap the criterion count.** More criteria means more opportunities for the judge to invent
  findings. A tight, well-evidenced set beats an exhaustive one.
- **Freeze the corpus before writing `A4`.** If the same reading informs both the judge's criteria
  and your own skill file, `A4` is fitted to the judge as well as to the test set. `A4`'s judge
  score is then uninterpretable and should be reported on tooling and efficiency only. Declare this
  regardless — it is already an oracle arm and one more caveat costs nothing.
- **Mutation calibration (§5.1.2) must span both strata**, so you know the judge's detection rate
  separately for handbook and community criteria. A judge that is reliable on documented rules and
  erratic on folklore should be used only on the panel where it works.

**On strictness.** Do not instruct the judge to be harsh, demanding, or to hold a high bar. Tone-
based strictness is not calibratable — it shifts the false-positive rate without improving detection,
and it cannot be audited afterwards. Strictness comes from **criterion coverage plus mandatory
evidence**, not from prompt personality. A judge given forty cited criteria and required to ground
each verdict in a file and line is strict in a way you can defend; a judge told to be tough is
producing opinions.

---

## 5.2 Considered and excluded: evolutionary skill-file optimisation

GEPA-style optimisation — evolve candidate artifacts, retain the Pareto frontier, use an LLM to
generate crossovers from feedback — is a good fit for *producing* a skill file. It is a poor fit for
*this* experiment, and including it would break the design.

- The experiment compares **fixed** arms. An arm that optimises during the run is not a fixed
  treatment and cannot be compared to one that doesn't.
- Optimising `A4` against this study's own scoring harness would fit the oracle as well as the test
  set — compounding the leakage that `A4` already carries by construction, and forfeiting the one
  thing that arm is good for (a clean upper bound).

**Legitimate follow-on design, out of scope here:** run GEPA against this harness on a *different*
package, then evaluate the evolved skill file on `orthoMTL` as genuinely held-out. That is a second
study with a real held-out test, and it needs the scoring harness this one builds. Note it as future
work; do not let it into the current run budget.

---

## 6. Frozen prompt and run protocol

**Instruction (identical across arms, verbatim, frozen):**

> See `FROZEN_PROMPT.txt` — frozen (no `DRAFT` marker present; confirmed 2026-09-20). Not duplicated
> here to avoid the two copies drifting; `run_arm.sh` reads it directly (`$(cat
> "${EXP_ROOT}/FROZEN_PROMPT.txt")`). It does not name any specific CRAN finding.

**Budget and stopping rule (identical across arms) — confirmed by Kevin 2026-09-20:**

- **max turns: 120.** `run_arm.sh`'s existing default (`--max-turns "${MAX_TURNS:-120}"`).
- **max wall-clock: 7200s (2h).** `run_arm.sh`'s existing default, now genuinely enforced by a live
  watcher (see below) rather than inferred after the fact from a `timeout` exit code.
- **stopping condition: agent declares done, OR budget exhausted, OR 8 consecutive assistant turns
  with no `Edit`/`Write` tool call (`STUCK_LOOP`).** Implemented and behaviourally tested 2026-09-20:
  `run_arm.sh` now runs `claude` in the background via process substitution (so its PID is capturable
  independently of the `tee`/`jq` pipeline), with a watcher subshell polling `stream.jsonl` every 5s.
  It resets the counter on any `Edit`/`Write` tool call and kills the process + records
  `.termination_live` if the threshold is reached before that. An independent disowned backstop
  process (`CAP + 60s`) guards against the watcher itself failing. 8 was chosen to tolerate normal
  early-run reading (skill file, snapshot, package) without false-triggering, while still catching a
  run that's genuinely not recovering well before it burns the full 120-turn budget — **this
  threshold has only been tested against synthetic transcripts, not a real agent run; watch it
  closely during the pilot and adjust if it fires on legitimate exploration or fails to fire on a
  real stuck run.**
- **the agent may run `R CMD check` itself: yes.** Already true in practice (`run_arm.sh`'s
  `--allowedTools` includes `Bash`) and matches this section's own recommendation.

**Termination reason — recorded for every run, mandatory.** Without it, an arm stuck in a check-fix
loop and an arm that finished fast both read as "used N turns."

**Skill-instruction hazard and the scope-alignment rule.** `cran-submit` ends by telling the agent to
ask the user to commit and to submit via `devtools::submit_cran()`. In headless autonomous mode there
is no user to ask, and submission is forbidden for every arm.

**Rule (applies uniformly to all arms, including `A1`, `A4` and any skill added later):**

> From an arm's skill file, remove *only* instructions that direct the agent to perform the actual
> CRAN submission, or to hand off to a user for action. Nothing else is altered — not wording, not
> ordering, not scope, not the review or checking content.

Framed this way it is **scope alignment**, not editing: it removes instructions to take actions the
protocol forbids for every arm and that no arm could complete, in the same class as provisioning the
container so no arm fights LaTeX. Framed as "trimming `A2`," it would be a discretionary edit to one
competitor, and the pre-registration's force comes from arms being untouched.

Conditions:

- **Applied identically to every arm.** Check each skill file against the rule; most will need no
  change. That `A2` is the one affected must fall out of the rule, not motivate it.
- **The diff is archived and published** alongside the results, so anyone can verify the edit was
  confined to terminal submission instructions.
- **Declared in limitations** (§10): `A2` was run with its submission hand-off removed.

**Decide this in the pilot, not now.** The frozen prompt already forbids submission and asks the
agent to state when it is done, which may be sufficient on its own. Run `A2`'s pilot unmodified:

- terminates `DECLARED_DONE` → **leave the skill untouched.** No edit, no caveat, cleanest result.
- hangs, or attempts a submission → apply the scope-alignment rule, then rerun the whole pilot block.

Either way the decision is made before measurement blocks, on pilot evidence, and recorded.

**Independently of the above:** block network egress to CRAN submission endpoints. `run_arm.sh`
already checks `cran.r-project.org/submit.html` reachability before every run and **aborts if it
resolves** — but on a container that reachability check enforced a network policy someone else set
up; on this native host, `cran.r-project.org` is reachable like any other site (we've been
installing packages through CRAN mirrors all session), so **run_arm.sh will correctly refuse to
start any real run until this is actually blocked** (Windows Firewall outbound rule or a hosts-file
null-route for `cran.r-project.org`). Not yet done — tracked in `ENVIRONMENT.md` as a pre-Phase-1
to-do, not assumed solved by dropping the container.

| Code | Meaning |
|------|---------|
| `CONVERGED_CLEAN` | declared done, check completes clean |
| `CONVERGED_DIRTY` | declared done, findings remain |
| `BUDGET_EXHAUSTED` | hit turn/time cap while still working |
| `STUCK_LOOP` | no-modification rule triggered |
| `VOID` | environment failure (§4.6) — run discarded and repeated |

`BUDGET_EXHAUSTED` and `STUCK_LOOP` are **non-completions**, not slow successes. Report the
non-completion rate per arm as an endpoint in its own right (§7).

**Environment pinning.** `R CMD check --as-cran` output varies by R version, platform, and
dependency versions. Without pinning, arms differ for reasons unrelated to skills.

- ~~container image: `rocker/r-ver:____` (fixed digest, not tag)~~ — **dropped 2026-09-18**, no
  container available on this host; native environment recorded in `ENVIRONMENT.md` instead
- ~~CRAN snapshot date: `____` (Posit PPM date-pinned repo)~~ — **not pinned natively**; declared
  gap, see `ENVIRONMENT.md` §"Declared gaps" item 2
- check invocation: `R CMD check --as-cran` (fixed flags; confirmed working natively in
  `verify_env.sh`, see `ENVIRONMENT.md`)
- same image used for the agent run and the scoring run

**Replicates.** `n = ____` per arm (**5 recommended, 3 minimum**). Agent runs are stochastic;
`n = 1` measures noise. Total runs = arms × n — budget this explicitly before starting.

### 6.1 Pilot phase (n = 1 per arm)

**Purpose: debug the harness, not measure anything.** The pilot tests whether the prompt is
workable, the budget sufficient, the leakage strip complete, and the §4.3 parser functional
end-to-end.

**Pooling rule, pre-committed:** if *anything* changes after the pilot — prompt wording, budget,
strip list, parser, container — the pilot runs are **discarded, not pooled**. A harness fix
invalidates the runs that motivated it. Only if the pilot needs zero changes may its runs count as
replicate 1.

Budget the pilot as spent regardless.

### 6.2 Run ordering over a 3-week window

Do **not** run arm-by-arm. Interleave by replicate block: all arms once in randomised order, then
all arms again, and so on. Over three weeks the agent's model version, tooling, or infrastructure
may change; arm-by-arm ordering would confound any such drift perfectly with arm identity.
Interleaving spreads it.

**Record the model version string on every run.** If it changes mid-experiment, that is a covariate
to report, not to hide — and interleaving is what makes it survivable rather than fatal.

### 6.3 Budget allocation (3 weeks, ≤30 runs)

Prioritise **replicates over arms**. If between-run variance is high, 5 arms × 5 is more informative
than 6 arms × 4.

**Replicate count — confirmed by Kevin 2026-09-20:** pilot **1 run per arm = 6** (§12 already says
"n = 1 per arm"; the "5–6" below likely predates `A5` being finalised as a sixth arm — 6 is the
number that's actually consistent with 6 arms existing), then **4 further replicates per arm = 24**.
Total **30**, exactly the `≤30 runs` cap in this section's own heading — not a coincidence to leave
unremarked, it means the confirmed plan already spends the full budget
and there's no slack for a 7th arm or a 5th replicate without cutting something else first.

Recommended: pilot 5–6 runs → then 4 further replicates per arm. Run `A5` (placebo) last, with
whatever budget remains; drop it without regret if variance turns out large. Pre-commit to the drop
rule now so it isn't a post-hoc choice.

### 6.4 Network access — now a primary protocol variable

The original agent read the CRAN policy website. This means `A0` is **not** a knowledge-free
control: with network access it can bootstrap its own guidance. The skill file's advantage
compresses to *speed of access*, not *possession of knowledge*.

Two mutually exclusive designs. Pick one and declare it:

| Design | Question actually tested | Expected effect | Realism |
|--------|--------------------------|-----------------|---------|
| **Network ON, all arms** | Does a skill beat self-service discovery? | small, mostly on efficiency | high — matches real use |
| **Network OFF, all arms** | Does a skill substitute for knowledge? | large, on conformance | low — nobody works this way |

**Recommended: ON**, with the CRAN policy pages **snapshotted and served locally to every arm
identically**. Live fetching over a 3-week window means arms see different content if CRAN updates a
page, and it isn't reproducible for anyone re-running this. Freeze the snapshot, record the capture
date, log every fetch.

**ON** selected design (matches recommendation above) — already the implemented state, not just a
choice on paper: `run_arm.sh`'s `--allowedTools` includes `WebFetch`, identically for every arm
including `A0`. Snapshot date **2026-09-18** (`snapshot/PROVENANCE.txt`): CRAN Cookbook (commit
`975290326e80da64220ee62dfe369ea9d5091927`), CRAN Repository Policy, and the CRAN submission
checklist, mounted at `$CRAN_DOCS_PATH` identically for every arm.

**The handbook decision.** CRAN staff supplied their handbook link only after submission 2 in the
original process. It is the single highest-value document in the story, and how you handle it
determines what the experiment means.

**Include it in the frozen snapshot, available identically to every arm — including `A0`.**

This deliberately makes the control *stronger* than the original run was at its start. That is the
point: any skill effect measured against a handbook-equipped control is a **conservative** estimate,
and the experiment tests the question that actually matters — *does a skill file add anything on top
of the official documentation being available?* If the answer is no, that is worth knowing and worth
saying.

Handicapping `A0` by withholding the handbook would produce a larger effect and an indefensible one.
Do not do it.

### 6.5 Arm isolation

Claude Code assembles context from more than the working directory. Each of these is a leakage
vector between arms:

- **CLAUDE.md walks up the tree.** Any `CLAUDE.md` in a parent of `arms/` loads into *every* arm,
  including the no-skill control.
- **`~/.claude/CLAUDE.md` is global** — loads in every project on the machine. If one exists, `A0`
  is not a clean control.
- **`~/.claude/skills/`, `rules/`, `settings.json`, hooks, subagents, MCP servers** are read from
  the home config directory too, not just the project.
- **Auto memory** persists per project under the home config directory and can carry state between
  runs — fatal for interleaved replicates.
- **Nested `CLAUDE.md` inside an arm tree** loads when files in that subdirectory are read.

Isolation measures:

1. Set `CLAUDE_CONFIG_DIR` to a **fresh per-run directory**, so the entire `~/.claude` equivalent is
   arm-scoped and disposable. This is the cleanest single control.
2. Disable auto memory for every run (`CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`).
3. Ensure no `CLAUDE.md` exists at or above `arms/` — verify, don't assume.
4. Launch with cwd = the arm's package root; never use `--add-dir`.
5. Run `/context` (or `/memory`) at the start of run 1 per arm and **archive the loaded-file list**.
   This is your evidence of isolation, and it belongs on a backup slide.
6. Grep each arm tree for stray `CLAUDE.md` / `AGENTS.md` before starting.

Verify these mechanics against current Claude Code docs before freezing — the config surface moves
between versions.

**Run log.** Per run: arm, replicate index, block index, model version string, Claude Code version,
loaded-context file list, start/end time, turn count, token count, network fetch log, full
transcript archived, output tree archived.

---

## 7. Endpoints

**Co-primary 1 — residual review burden.** Count of findings in the output tree above baseline
(§4.3). Lower is better.

This is the same number as "conformance findings," renamed to say what it means. Each residual
finding is something a human would have had to catch and enforce — precisely the labour spent in the
original process. Reporting it as review burden connects the measurement to the claim without
inflating it.

**Co-primary 2 — efficiency.** Turns, tokens, and wall-clock to reach the arm's final state; plus
turn index at which each discovery item (§4.5) was addressed.

Efficiency is co-primary rather than secondary **because the control has network access and the
handbook**. If `A0` can read the official documentation itself, review burden may floor at zero for
every arm and carry no signal. The skill file's realistic claim is front-loading, and front-loading
is measured in turns.

**Co-primary 3 — predictability (the "peace of mind" endpoint).** Between-replicate **spread** of
endpoints 1 and 2, per arm.

This is the operationalisation of peace of mind, and it is free — you are already running
replicates. An arm with a good mean and wide spread is not something you would trust with a
submission; an arm with a slightly worse mean and tight spread is. Predictability, not average
performance, is what "I can stop personally checking this" actually requires.

**Report spread as the headline, not as an honesty footnote.** If skill arms cluster and `A0`
scatters, that is the result — and it survives even if the means overlap.

**Co-primary 4 — review rounds.** Number of find-and-fix cycles required to reach a clean state:
run the frozen suite, return findings to the agent, repeat until clean or capped.

This is the **audience-facing number**. It is the analogue of the real pre-submission loop, not of
the two CRAN rounds — most of the historical cost sat in local check failures and manual enforcement
before anything was ever submitted. "N rounds per arm" is legible to anyone who has submitted to
CRAN in a way that token counts are not, and each round is one occasion a human would have been
pulled in.

It also substitutes for the human-interaction count that cannot be measured directly: every arm runs
autonomously, so interventions are zero by construction. Rounds are the closest honest proxy — count
them, and say plainly that they are a proxy.

Cap rounds at `____` and report cap-hits as non-completions.

**Co-primary 5 — non-completion rate.** Proportion of runs terminating `BUDGET_EXHAUSTED` or
`STUCK_LOOP` (§6). An arm that fails to produce a checkable package within budget has failed,
regardless of how good its successful runs looked. Report alongside, never averaged in.

**Mechanism endpoints.** These explain *why* an arm wins, not just that it did — and for a
ten-minute slot they make a better slide than any bar chart:

- **turn index of first `R CMD check` invocation.** Early-check versus build-then-check is the most
  plausible single mechanism for a skill effect, and it is one number per run.
- check-cycle count, and `FAIL_PACKAGE` count per run (§4.6)
- turn index at which each discovery item was addressed (§4.5)

If the skill arms check on turn 3 and the control checks on turn 40, that is the finding, and the
audience will remember it.

**Floor-effect rule — now an expectation, not a contingency.**

Every historical submission passed CRAN's automated gate. The mechanical oracle (§4) is therefore
**expected** to floor at or near zero for most arms, including the control. Residual review burden
was designed as co-primary 1 on the assumption that it would discriminate; the submission history
says it probably will not.

Pre-committed consequences:

- Residual review burden is retained and reported, but the study is **not designed around it**. If
  ≥80% of runs reach zero findings above baseline, report the floor explicitly and move on.
- **The judgement oracle (§5.1) becomes the primary conformance instrument**, because that is where
  every real failure in this package's history occurred. Its calibration figures therefore carry the
  weight of the result and must be shown first.
- If the judge fails calibration (§5.1.2 decision rule), the study has **no working conformance
  endpoint** and reports on efficiency, predictability, rounds and non-completion alone. That is a
  narrower talk but an honest one. Decide and state this before running.

*"Every arm passes the machine checks; the differences are entirely in what a human reviewer would
still object to"* is the likely shape of this result. It is also the more interesting finding, and it
is worth building the talk around rather than discovering in week three.

**Secondary.**
- `R CMD check --as-cran`: counts of ERROR / WARNING / NOTE, and the specific NOTE texts
- frozen test suite pass rate
- scope-preservation metrics (§5)
- count of network fetches to CRAN policy / handbook pages (direct measure of substituted discovery)
- *optional:* simulated resubmission rounds — feed findings back, count rounds to clean. Closest
  analogue to the real submission loop, but adds runs; include only if budget allows.

**Not endpoints.** Textual or structural similarity to the accepted version. The accepted state is
one acceptable solution among many; similarity would largely measure stylistic coincidence, and it
would penalise an arm for solving a problem differently but correctly. Explicitly rejected in this
design — say so if asked.

---

## 8. Analysis and pre-committed interpretation

- Report **per-run values with the spread**, not arm means alone. With n ≤ 5, a dot plot per arm;
  no error bars implying a distribution that hasn't been established.
- No significance testing. n is too small and the runs are not independent samples from any
  population of packages. Descriptive only. Say this out loud rather than being asked.
- **If test-arm distributions overlap `A0`:** report as no detected effect for public skill files.
  Do not rank on non-overlapping means.
- **If `A4` separates from `A0` but `A1–A3` do not:** the effect is hindsight, not guidance. Primary
  headline.
- **If `A5` (placebo) also separates from `A0`:** the effect is context volume, not content. Report
  this even though it undercuts the talk's premise.

---

## 9. Blinding

Anonymise output trees to opaque IDs (`RUN-a7f3`, ...) before scoring. Break the mapping only after
all conformance and behavioural scores are recorded and committed to git.

Scoring the ledger requires judgement per row; blinding is what makes those judgements credible.

---

## 10. Declared limitations (for the slide)

- n = 1 package, 1 agent, 1 model version
- ledger classification (§4) is a judgement call, made blind but made by the package author
- `A4` is fitted on the test set by construction and is reported as a bound, not a result
- the historical development run is observational and confounded with model version
- no claim about other packages, other domains, or non-CRAN release processes

---

## 11. Instrumentation

### 11.1 Capture mechanism

Headless `claude -p` with `--output-format stream-json --verbose`. The final result line carries
cost, duration, turn count, and token usage; `--output-format json` gives the same for single-shot
calls. Tee the raw stream to disk before parsing — if a parse fails you want the original bytes.

Finer granularity, if needed: the per-message JSONL transcript under `CLAUDE_CONFIG_DIR`. Because
isolation already scopes that directory per run (§6.5), the transcript lands somewhere known and
disposable.

Fleet-level OTel (`CLAUDE_CODE_ENABLE_TELEMETRY=1`) is available but unnecessary here — per-run JSON
plus the transcript covers everything, with no collector to stand up.

Captured per run: `total_cost_usd`, `duration_ms`, `num_turns`, input/output tokens, cache read and
creation tokens, wall clock, termination reason, first-check event index, check invocation count.

### 11.2 The token-count confound — must be handled

**Raw token totals partly measure skill file length, not skill file quality.**

A cold headless run loads the full context before doing any work — a cold `claude -p` in a repo root
can burn on the order of 10⁵ tokens on load alone. That floor scales with the size of the loaded
instruction set. A verbose but excellent skill file will look expensive; a terse but useless one will
look cheap. Reporting tokens naively could invert the result.

Three mitigations, all pre-committed:

1. **Cold-start calibration.** Before each run, issue a null prompt in that arm's exact
   configuration and record its token cost. This is the arm's context floor.
2. **Report tokens twice** — raw, and net of the floor. The net figure is the work; the floor is the
   overhead. Both are real costs and both belong on the slide.
3. **Report skill file length** for every arm, and treat token efficiency as *conditional on* it.

This is also where `A5` (length-matched placebo) earns its keep: it separates content from volume in
the token accounting, not just in the outcome.

**Wall clock is the more robust efficiency measure** for a talk audience, because it is insensitive
to context volume and is what "peace of mind" actually feels like. Turn count sits between the two.
Lead with turns and wall clock; present tokens with the caveat attached.

### 11.3 Cost note

Cold-start overhead is paid on every run. With ~30 runs plus 30 calibration prompts, budget for it
explicitly rather than discovering it in week three.

---

## 12. Sequencing — de-risk before spending run budget

The load-bearing uncertainty in this study is **whether the judge calibrates**. Given the floor
expectation (§7), a failed judge leaves the study with no conformance endpoint at all. That
uncertainty must be resolved before, not after, three weeks of runs.

**Phase order — do not reverse:**

| Phase | Work | Needs run budget? | Gate to proceed |
|-------|------|-------------------|-----------------|
| **0** | Build image, pass `verify_env.sh`, validate the finding parser on baseline + broken tree | no | gate passes |
| **1** | Extract criteria; build the mutation set; **calibrate the judge** (§5.1.2) | judge calls only — cheap | judge detects ≥50% of mutations, FP rate below detection rate |
| **2** | Freeze everything (§13); pilot block | 1 block | pilot needs no harness changes |
| **3** | Measurement blocks 2–5 | 4 blocks | — |

**Phase 1 is the cheap insurance.** Judge calls cost a fraction of an agent run. If the judge fails
calibration, you learn it in days rather than discovering in week three that the only endpoint left
is turn count.

**If the judge fails calibration, the study is still worth running** — on efficiency, predictability,
rounds and non-completion, with the judgement gap declared. Decide in advance whether that narrower
result justifies the budget. It probably does, but make the call knowingly.

**Schedule note.** The talk is 20–21 October. Phase 1 consumes calendar time that is not run budget;
plan for it explicitly rather than taking it out of the three weeks.

---

## 13. Freeze checklist

- [x] `C0` identified and recorded
- [x] Trees exported, leakage strip applied, grep verification logged
- [x] Rejection ledger complete, Y/N classification done, independently sanity-checked. §4.4's table
      filled 2026-09-20 (both `N` / `STATIC`). `Round` fields filled 2026-09-20: R02 (license) →
      Round 1 (fixed 2026-07-10), R01 (seed) → Round 2 (fixed 2026-08-07, alongside "resubmission 2"
      prep) — inferred from git history (commit dates, PR branch names), confirmed by Kevin; no
      direct rejection-email text was consulted, worth noting if that distinction ever matters.
- [x] Frozen test suite separated and withheld
- [x] Prompt frozen — confirmed 2026-09-20: no `DRAFT` marker in `FROZEN_PROMPT.txt`.
- [x] Budget and stopping rule fixed — **confirmed by Kevin 2026-09-20**: 120 turns / 7200s
      wall-clock (existing `run_arm.sh` defaults) plus the newly implemented and behaviourally-tested
      `STUCK_LOOP` watcher (8 consecutive no-Edit/Write assistant turns kills the run and records the
      reason) — see §6 for the full design. **Still only tested on synthetic transcripts, not a real
      agent run** — the pilot (2026-09-21) is the first real exercise of this; watch it closely.
- [x] ~~Container image digest~~ and CRAN snapshot date recorded — N/A, native environment;
      `ENVIRONMENT.md` recorded instead (2026-09-18). **CRAN egress block: done** 2026-09-20
      (`cran.r-project.org` null-routed; confirmed via `run_arm.sh`'s own reachability check logic
      and via the scoring pipeline picking up the resulting network-failure findings — see
      `ENVIRONMENT.md` and the `extract_findings.R` environment-finding fix, 2026-09-20).
- [x] Replicate count fixed — **confirmed by Kevin 2026-09-20**: pilot 1/arm (6) + 4 further/arm
      (24) = 30 total, spending the full `≤30` cap exactly (§6.3).
- [x] This file committed; commit hash: `a37d6dfa97f4a1248275812f556d303a113d99bf` — repo
      initialised and root commit made 2026-09-21 (176 files, harness as of pilot day).

**No run starts until every box is ticked.**
