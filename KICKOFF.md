# Kickoff — CRAN skill-file experiment

Read this first, then `CLAUDE.md`, then `skill-experiment-preregistration.md`.

---

## Where to start the session

**In a new sibling folder. Never inside the `orthoMTL` clone.**

```
~/work/
├── orthoMTL/                    # existing clone — READ-ONLY SOURCE, never the session cwd
├── cran-skill-experiment/       # ← start the session HERE (harness, scoring, docs)
└── cran-exp-runs/               # arm trees and run artifacts — clean ancestry required
```

### Why not inside `orthoMTL`

Two reasons, and the first would silently destroy the control arm.

**1. `CLAUDE.md` walks up the tree.** Claude Code collects every `CLAUDE.md` it finds from the
working directory upward. Your `orthoMTL` clone already has one — written *during* the CRAN effort,
so it almost certainly encodes what you learned from the rejections. Put the arms anywhere beneath
it and every arm, `A0` included, silently receives a CRAN skill file. The control stops being a
control and you would not see it in any output.

**2. `.git` becomes reachable.** An arm running under the clone can walk up to the full history —
every fix, every resubmission, the accepted state. The whole point of `git archive` is to withhold
exactly that.

### The subtler trap: ancestry of the run root

`cran-skill-experiment/` has its own `CLAUDE.md` — the one naming the invariants, the ledger, the
criteria. If the arm trees live under it, they inherit it. That is why `cran-exp-runs/` is a
**separate sibling**, with no instruction file anywhere between it and the filesystem root.

`run_arm.sh` asserts this and aborts if it finds one. Do not disable the check.

Note that `CLAUDE_CONFIG_DIR` does **not** solve this. It relocates the `~/.claude` surface — user
settings, skills, auto memory — but the project tree walk is separate and starts from the working
directory.

### Where the arms actually execute

Inside the container, with only the arm tree mounted. Host ancestry is then irrelevant because there
is nothing above `/work` to find. The host layout above still matters for the harness session and for
any run launched outside the container.

---

## First tasks — Phase 0

None of these need the rejection letters, the skill files, or the docs snapshot. Start now; work the
blockers in parallel.

1. **Resolve `C0`.** First commit of `Novartis/orthoMTL`; fallback rule in `seed-and-pilot.md` §0 if
   it is scaffold-only. Record the SHA.
2. **Export the seed** with `git archive` — never `git clone`. Strip, then run the leak audit.
   Log the output.
3. **Build the base image.** Pin the `rocker/r-ver` digest, the PPM snapshot date, and the Claude
   Code CLI version. All three are placeholders in the `Dockerfile`.
4. **Pass the environment gate.** `verify_env.sh` against the accepted version. Nothing proceeds
   until the baseline completes `--as-cran` with the PDF manual and vignettes building.
5. **Seed audit.** Run every static rule against the seed to establish the before-state
   (`seed-and-pilot.md` §3). This determines the study's resolution and costs no run budget.
6. **Validate the scoring pipeline** against the baseline and `kevinVervier/orthopen`, which is a
   naturally broken tree — no fabrication needed. Rules that fire on orthopen's real violations are
   rules that work.

## What is still blocked on Kevin

- The offline CRAN docs snapshot (`snapshot/`)
- Arm skill files `A1`–`A5`
- The frozen held-out test suite, extracted from the accepted version
- Freezing `FROZEN_PROMPT.txt` (currently marked DRAFT; `orchestrate.sh` refuses to run until the
  marker is removed)

## Deliberately not built yet

The analysis and plotting script. Writing it before seeing the spread is how a pre-registration
quietly becomes decoration.

---

## Files

Everything below goes in `cran-skill-experiment/`. Nothing goes in `cran-exp-runs/` except arm
trees and run artifacts, which the scripts create.

### Governance — read before doing anything

| File | Role |
|------|------|
| `CLAUDE.md` | invariants and layout. **At the folder root** — this is the session's own instruction file |
| `KICKOFF.md` | this file |
| `skill-experiment-preregistration.md` | the spec. Where it and any other file disagree, it wins |
| `seed-and-pilot.md` | seed extraction, seed audit, pilot governance |

### Ground truth — **never reaches an arm**

| File | Role |
|------|------|
| `rejection-ledger.md` | the two known findings, their static rules, the mutation schema |
| `criterion-corpus.md` | core human-review criteria, tagged by provenance and oracle |
| `criterion-corpus-longtail.md` | 44 long-tail findings, plus the `\dontrun` audit |

These are the answer key. They stay on the harness side of the split. **Never mount
`cran-skill-experiment/` into an arm container, and never copy any of them under `RUNS_ROOT`.**

### Harness

| File | Role |
|------|------|
| `FROZEN_PROMPT.txt` | agent instruction. DRAFT until you freeze it; `orchestrate.sh` refuses to run while the marker is present |
| `Dockerfile` | frozen base image. Three placeholders to pin |
| `verify_env.sh` | environment gate |
| `run_arm.sh` | one run — isolation, instrumentation, submission block |
| `orchestrate.sh` | block-randomised scheduling |
| `scoring/extract_findings.R` | check output to normalised findings |
| `scoring/static_rules/` | one file per rule; `R01` and `R02` drafted in the ledger |

### Who creates what

**Only one item genuinely requires Kevin.** Everything else Claude Code can build in Phase 0, given
the path to the local `orthoMTL` clone.

| Path | Who | How |
|------|-----|-----|
| `baseline/pkg/` | **Claude Code** | `git archive main` from the local clone into `baseline/pkg/`. This is the accepted version — the gate target and the subtraction baseline |
| `frozen-tests/` | **Claude Code** | Copy `tests/` from HEAD. Then check with `git log --diff-filter=A -- tests/` which tests existed at `C0`: hold out only those added later (§5) |
| `snapshot/` | **Claude Code** | See below |
| `${RUNS_ROOT}/arms/A1..A3/` | **Claude Code** | Clone `posit-dev/skills` (`cran-extrachecks`, `r-package-development`) and `CoryMcCartan/agent-skills` (`cran-submit`). Record the commit SHA of each — skills are moving targets |
| `${RUNS_ROOT}/arms/A5/` | **Claude Code** | Concatenate the `snapshot/` handbook text into an instruction file. This *is* the raw-handbook arm |
| `${RUNS_ROOT}/arms/A4/` | **Kevin** | The hindsight skill. Write it only after the criterion corpus is frozen, or it is fitted to the judge as well as the test set |
| the rejection ledger | **done** | Two findings recovered (R01 seed, R02 licence), already written into `rejection-ledger.md`. Two rejection rounds, both human review; the other CRAN emails were automated confirmations. **Phase 1 is no longer blocked** |

### The handbook to snapshot

The handbook CRAN staff pointed you to is almost certainly the **CRAN Cookbook**
(`contributor.r-project.org/cran-cookbook/`, source at `github.com/r-devel/cran-cookbook`). It was
built by gathering data from recent CRAN re-submissions to identify the most common issues, and is
co-authored by a member of the CRAN Team who appears by name in public rejection correspondence.

Mirror all three, and record the capture date:

| Source | Why |
|--------|-----|
| CRAN Cookbook | problem/solution recipes derived from real re-submissions — the closest thing to the reviewers' own knowledge |
| CRAN Repository Policy | the normative document |
| Checklist for CRAN submissions | the official checklist |

Prefer cloning the Cookbook's GitHub repository over `wget --mirror` — it pins a commit, which a
mirrored website cannot.

**This is also the `HANDBOOK` provenance boundary** (§5.1.4). A criterion derivable from these three
is `HANDBOOK`; anything else is `COMMUNITY`. Snapshot first, then classify the corpus against what
the snapshot actually contains rather than against what you assume is in it.

Every arm sees this, `A0` included. That is what makes a measured skill effect conservative.

---

## Running the scripts

Both take two roots as environment variables, because the folders are deliberately split:

```bash
export EXP_ROOT=~/work/cran-skill-experiment
export RUNS_ROOT=~/work/cran-exp-runs

cd "$EXP_ROOT"
./verify_env.sh baseline/pkg
./orchestrate.sh 1          # pilot block
```

**Resolved paths on this machine** (2026-09-18): `EXP_ROOT=/c/Users/Shadow/Bricoles/cran-skill-experiment`
(unmoved) and `RUNS_ROOT=/c/Users/Shadow/cran-exp-runs` — a dedicated top-level folder, deliberately
outside `Bricoles\` since it has its own portfolio-level `CLAUDE.md` that would otherwise sit in
`RUNS_ROOT`'s ancestry.

`RUNS_ROOT` must have no `CLAUDE.md`, `AGENTS.md` or `CLAUDE.local.md` anywhere between it and the
filesystem root. `run_arm.sh` walks the ancestry and aborts if it finds one.

## Before touching anything

The invariants in `CLAUDE.md` exist because normal good engineering instincts break this
experiment — reusing a cached tree, tidying the prompt, patching a scoring edge case mid-run. Each
of those voids runs. Read them first.
