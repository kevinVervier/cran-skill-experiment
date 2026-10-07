# CRAN skill-file experiment — project instructions

## What this is

A controlled comparison of agent-assisted R package preparation with and without a CRAN skill file.
Subject package: `orthoMTL`. Output: an R/Pharma 2026 lightning talk.

**This is a measurement instrument, not a software project.** Changes that would improve a normal
codebase — tidying the prompt, reusing a cached tree, fixing a scoring edge case mid-run — destroy
the comparison. Read the invariants before touching anything.

Full design: `skill-experiment-preregistration.md`. It is the spec. Where this file and the
pre-registration disagree, the pre-registration wins.

## Invariants — do not violate without an explicit instruction from Kevin

1. **`FROZEN_PROMPT.txt` is frozen.** Once run 1 starts, it does not change. Not for typos, not for
   clarity. If it must change, every prior run is void.
2. **Never reuse an output tree.** Each run starts from a fresh copy of `arms/<ARM>/pkg`.
3. **No `.git` in any arm tree.** History is readable and contains the answers.
4. **Arm `A0` gets no instruction file at any level** — not in the tree, not in a parent directory,
   not in `CLAUDE_CONFIG_DIR`. It is the control.
5. **`CLAUDE_CONFIG_DIR` is fresh per run.** Auto memory disabled. No state crosses runs. Note this
   relocates the `~/.claude` surface only — it does NOT stop the project tree walk.
5b. **No `CLAUDE.md`, `AGENTS.md` or `CLAUDE.local.md` anywhere above an arm tree.** `run_arm.sh`
   walks the ancestry to `/` and aborts if it finds one. Never disable that check.
6. **Do not run arm-by-arm.** Block-randomised interleaving only (`orchestrate.sh`).
7. **Do not unblind before scoring is committed.** `.blind_map.csv` stays out of the scoring
   directory.
8. **Do not submit anything to CRAN.** Ever, for any reason.
9. **The environment is fixed once recorded.** Originally: a base image, built once, never rebuilt
   mid-experiment. **Amended 2026-09-18:** no container is available on this host (see
   `ENVIRONMENT.md` for why — Shadow/Blade cloud PC, no nested virtualization). The toolchain was
   installed natively instead and recorded in `ENVIRONMENT.md`. Same rule, native form: do not
   upgrade, reinstall, or reconfigure R/TeX/pandoc/qpdf/Ghostscript/Claude Code on this host once
   block 2 starts. Changing any of them mid-experiment voids every prior run, exactly as an image
   rebuild would have.
10. **Never edit the accepted-version baseline** or the frozen test suite.

## Layout

**Two sibling roots, deliberately separate.** See `KICKOFF.md` for why — the short version is that
`CLAUDE.md` walks up the directory tree, so an arm placed under this folder would inherit this file.

Shape below is illustrative (three siblings under one parent). On this machine the two roots are
not literal siblings under a shared parent — see the resolved paths after the diagram — but the
invariant that matters is unchanged: nothing above `$RUNS_ROOT` may carry an instruction file.

```
~/work/
├── orthoMTL/                      # existing clone — READ-ONLY SOURCE, never the session cwd
│
├── cran-skill-experiment/         # $EXP_ROOT — session starts here
│   ├── CLAUDE.md                  # this file
│   ├── KICKOFF.md
│   ├── skill-experiment-preregistration.md
│   ├── seed-and-pilot.md
│   ├── rejection-ledger.md        # ANSWER KEY — never reaches an arm
│   ├── criterion-corpus.md        # ANSWER KEY
│   ├── criterion-corpus-longtail.md   # ANSWER KEY
│   ├── FROZEN_PROMPT.txt
│   ├── Dockerfile                 # UNUSED for this run — see ENVIRONMENT.md
│   ├── ENVIRONMENT.md             # native toolchain record, replaces the image digest
│   ├── verify_env.sh
│   ├── run_arm.sh
│   ├── orchestrate.sh
│   ├── scoring/
│   │   ├── extract_findings.R
│   │   └── static_rules/
│   ├── snapshot/                  # offline CRAN docs — pointed to via $CRAN_DOCS_PATH, seen by EVERY arm
│   ├── baseline/                  # accepted version + its check output
│   └── frozen-tests/              # held-out suite — never under $RUNS_ROOT
│
└── cran-exp-runs/                 # $RUNS_ROOT — NO instruction file anywhere above the arm trees
    ├── arms/
    │   ├── A0/pkg/                # control — no skill file
    │   ├── A1/pkg/  + cran-extrachecks        (checklist)
    │   ├── A2/pkg/  + cran-submit             (process + adversarial)
    │   ├── A3/pkg/  + r-package-development   (general, not CRAN)
    │   ├── A4/pkg/  + Kevin's hindsight skill (ORACLE — not a competitor)
    │   └── A5/pkg/  + raw handbook text       (distillation control)
    ├── runs/                      # per-run artifacts
    └── blinded/                   # opaque-ID trees for scoring
```

Both scripts require the roots as environment variables:

```bash
export EXP_ROOT=~/work/cran-skill-experiment
export RUNS_ROOT=~/work/cran-exp-runs
```

**Resolved paths on this machine** (2026-09-18): `EXP_ROOT` did not move — it's
`C:\Users\Shadow\Bricoles\cran-skill-experiment` (`/c/Users/Shadow/Bricoles/cran-skill-experiment`
in Git Bash), and its own `CLAUDE.md` at the root is intentional. `RUNS_ROOT` is
`C:\Users\Shadow\sandbox` (`/c/Users/Shadow/sandbox`) — a dedicated top-level folder, not under
`Bricoles\` (which has its own portfolio-level `CLAUDE.md` that would otherwise sit directly above
it, tripping invariant 5b). In practice:

```bash
export EXP_ROOT=/c/Users/Shadow/Bricoles/cran-skill-experiment
export RUNS_ROOT=/c/Users/Shadow/sandbox
```

**Renamed 2026-09-25** from `cran-exp-runs`: a live arm's own working directory (`PWD`) and its
isolated `CLAUDE_CONFIG_DIR` both sit under `RUNS_ROOT`, and both are visible to that arm by
necessity. With the old name, that meant every arm's environment carried the substring
"cran-exp-runs" — a plain `env | grep -i cran` (an arm looking for the documented
`CRAN_DOCS_PATH`) surfaced it in 4/6 block-1 pilot arms, including the A0 control, effectively
telling it "you are inside a CRAN-skill experiment." Renaming to a name with no domain-suggestive
substring closes that specific vector; see `hooks/path_confinement_guard.sh` and the `env -u`
fix in `run_arm.sh` for the two related leaks (arbitrary filesystem read, and the EXP_ROOT/
RUNS_ROOT/OLDPWD env-var leak) found and fixed the same day.

## Sequencing

Nothing runs until `verify_env.sh` passes on the accepted version. If the baseline cannot complete
`R CMD check --as-cran` with manual and vignettes building, the environment is under-provisioned and
every arm would burn turns on the same toolchain failure.

**Status (2026-09-18): `verify_env.sh` passes natively** — see `ENVIRONMENT.md`. Network egress to
`cran.r-project.org` is blocked (confirmed 2026-09-25 via a `0.0.0.0 cran.r-project.org` hosts-file
entry; a live connection attempt times out) — this was previously a container network policy, now
done at the OS level instead (see pre-registration §6). Nothing outstanding before block 2.

Then: freeze checklist (pre-registration §12) → pilot (n=1 per arm, results discarded if anything
changes afterwards) → blocks 2–5.

## Things that look like bugs but are not

- **Arms diverge in DESCRIPTION dependencies.** Intended. Versions are pinned; the dependency *set*
  is allowed to vary. Do not standardise it.
- **The cold-start calibration prompt seems wasteful.** It measures each arm's context floor, which
  is what separates skill file quality from skill file length. Do not remove it.
- **Baseline check output may contain NOTEs.** The pinned environment differs from CRAN's. Findings
  are scored *relative to* baseline, not absolutely.
- **`A4` will probably win.** It was written from this package's own failure history. It is reported
  as an upper bound, never in a ranking.
- **The ledger has only two findings.** That is complete, not partial: there were two rejection
  rounds, both human review. The mutation set is built from the criterion corpus, not from the
  ledger.

## Talk / deck (presentation pass)

The deck is `talk/talk.qmd`. Facts in it are load-bearing — it is a public
artefact about a null result, so every claim must survive a hostile check.

**Narrative (reframed 2026-10-07).** The deck no longer ends on "no effect". It
ends on **verification as the bottleneck**, with the experiment's own instrument
failure as the evidence. Arc: shipped science (`orthoMTL` on CRAN) → the
counterfactual question from our own rejections → why a measurement instrument →
the zero → **the turn**: the judge panel had 12 criteria, 10 never fired, and the
2 that did were the judge arguing both sides of text no arm had touched →
executable oracles beat prose guidance → *"Generation got cheap. Verification did
not."* That closing line is the thesis, not a sign-off. See `LESSONS_LEARNED.md`
§5 for the full arc and §10 for the judge-panel finding.

Tone discipline: this is not a null dressed up as an insight. Lead with the
shipped package, state the zero without hedging, then show the instrument failing
and say what it cost.

- **`talk.pdf` is the only public artefact.** Everything else in `talk/` is
  gitignored: the Novartis template assets (`*.scss`, `*.svg`, `*.pptx`,
  `gradient_bar.png`, …) are added on the internal PC and **must never be
  committed or shipped off this machine**.
- **Never run `quarto render talk.qmd --to pdf`.** Revealjs decks take the
  LaTeX path under `--to pdf`; it deletes the existing `talk.pdf` and then fails
  (no TeX here). Build HTML, then print `talk.html?print-pdf` with decktape or a
  headless browser. `*.tex` and `talk_files/` are gitignored as of 2026-10-07
  precisely because that mistake left them behind.
- **Two real rejections, scored differently.** R02 (LICENSE template) was
  repaired in 57/57 runs. R01 (`set.seed()`) was present in the seed (`seed = 42`
  default plus unconditional `set.seed()` in four exported functions) and the
  original R01 rule missed it; use `scoring/results_r01v2/`, not `seed_audit.json`,
  for R01. Arms differ on it; counts are descriptive (n=9-10 per arm).
- **R01 is an open lead, never a skill-file win.** The re-score is
  post-unblinding. It is defensible because `rescore_r01.R` is a pure function of
  tree content and never reads `.blind_map.csv` — the same code at first
  unblinding gives the same table. But A4, written from this exact rejection
  history, produced the canonical fix **zero** times, which is the opposite of a
  clean skill effect. See `LESSONS_LEARNED.md` §7.3.
- **The maintainer-email finding is C13, from the experiment itself** — not a
  later discovery by a newer model. And it is **not a policy violation**: a named
  person at a company address is compliant; the risk is filtering and job changes.
- **Do NOT say "flagged in every tree except A5".** No arm ever changed the
  address — it is `kevin.vervier@novartis.com` in all 57 runs. The 10 COMPLIANT
  verdicts are the judge excusing the corporate domain because Novartis Pharma AG
  is also the listed copyright holder, and its own 2 NON_COMPLIANT A5 runs cite
  the same fact as aggravating. C13 measures judge variance, not conformance
  (`LESSONS_LEARNED.md` §9).

## Reporting posture

Kevin's standing preference: flag the uncomfortable implication first, then the path forward.
Defensibility over impressiveness. If a result is weak, ambiguous, or undercuts the talk's premise,
say so directly — a null finding stated plainly is worth more here than a clean bar chart nobody
believes.
