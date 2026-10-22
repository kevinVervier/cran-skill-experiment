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
│   ├── rejection-ledger.md        # ANSWER KEY — never reaches an arm (public since 2026-10-18)
│   ├── criterion-corpus.md        # ANSWER KEY (public since 2026-10-18)
│   ├── criterion-corpus-longtail.md   # ANSWER KEY (public since 2026-10-18)
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
    │   ├── A4/pkg/  (INTENDED: Kevin's hindsight skill. AS RUN: no instruction file — a second control)
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
- **`A4` was never delivered (found 2026-10-08).** The hindsight file was intended but never written
  or installed: A4's first-call context is 7,145 tokens in all 10 runs, identical to A0, and no
  instruction file exists in any A4 tree or in git history. For the main experiment A4 is a second
  control (controls n=20) — never describe it as an oracle, an upper bound or a skill arm. A
  delivered A4 is a separate post-hoc supplementary run (12/12 canonical R01 fixes vs 0/10 fresh
  controls; an afterward positive control, never pooled with the 57): see `supplementary/README.md`.
  The talk pools the 10 undelivered-A4 runs as A0 (n=20) and says "five conditions". Run
  `supplementary/check_arm_loaded.sh` before and after any run that is supposed to carry
  instructions.
- **The ledger has only two findings.** That is complete, not partial: there were two rejection
  rounds, both human review. The mutation set is built from the criterion corpus, not from the
  ledger.

## Talk / deck (presentation pass)

The deck is `talk/talk.qmd`. Facts in it are load-bearing — it is a public
artefact about a null result, so every claim must survive a hostile check.

**Narrative (reframed 2026-10-07, restructured 2026-10-13, re-cut 2026-10-16, timeline and biomarker slide dropped 2026-10-18).** The
deck no longer ends on "no effect". Subtitle: "An agent, a rejected package, and what
a skill file did (not) add". It is built around one question — *what actually catches
mistakes when an AI agent writes your R package?* — and ends on **verification as
the bottleneck**, with the experiment's own instrument failure as the evidence.
Arc (12 main slides): the `orthoMTL` **timeline**, now the first slide after the title
(its notes hold the opening line and it names the agent for the first time): one sentence
on what it does, then five dated nodes with the gaps in orange (Sep 2014 PhD at
ECML-PKDD, Sep 2024 survival extension + manuscript submitted, Apr 2026 clinical paper
published, Jun 2026 packaging starts with the agent, Aug 2026 on CRAN). No method
explanation: the biomarker sign-flip slide and the landmark figure are gone from the
slides (their helper functions stay in the setup chunk) →
"Packaging with an agent", one slide that now holds the 2014 bug the agent's unit test
caught **and** the green checks, ending on "Submit" (there is no separate test slide
any more; the label-flip sketch lives on the correctness backup slide) → our two CRAN
rejections, which break that happy ending, then "People call that a skill file" → what
a skill file is → the design, told as a trial, with the **"One agent, no human"** box
that contrasts the interactive packaging on slide 3 with the headless runs → evidence
2, **57/57: every arm hit the ceiling**, now framed as **zero interaction**
(`R CMD check` clean with no human in the loop) rather than as a ceiling caveat on the
slide; "ceiling" is said aloud from the notes → evidence 3, `set.seed()`, where the check is silent
and the arms did differ (exploratory) → evidence 4, **the turn**: the AI judge (the
pre-registered primary measure) had 12 criteria, 10 never fired, and the 2 that did
were the judge arguing both sides of text no arm had touched → *"The cheap half is
the half a machine can check."* That closing line is the thesis, not a sign-off; the
earlier wording ("Generation got cheap. Verification did not.") is kept in the
notes as an alternative. The line was reworded on 2026-10-19: the previous version
("Machine checks are cheap. Judgement isn't.") ended on a bare abstract noun with no
referent in the deck, which read as a maxim rather than a result. See `LESSONS_LEARNED.md` §5 for the full arc and §10 for
the judge-panel finding.

Timeline discipline: dates are sourced (ECML-PKDD Sep 2014; Juric et al. published
online 10 Apr 2026; first agent-co-authored commit 2026-06-01; CRAN 2026-08-23). The
packaging was part-time work, so no duration ("twelve weeks") goes on the slide or in the
notes: it reads as an effort claim. Sep 2024 is the manuscript submission, from Kevin, not a repo fact. The
19 months is mostly journal review: say "the paper took 19 months", never "the code
sat". As of 2026-10-19 the timeline carries **no duration badges at all** — the orange
"10 years" / "19 months" / "7 weeks" pills were removed, because the Jun-to-Aug packaging
interval could never carry one and the resulting gap drew attention to the omission. The
dates stay on the slide; the intervals may still be spoken, except the packaging one.
Never put submission dates or "first try" on that slide (the two rejections must
stay a surprise on the next slide), and never credit the speed to a skill file: the
agent in the packaging story had none.

Tone discipline: this is not a null dressed up as an insight. Lead with the
shipped package, show 57/57 and name it a ceiling before the audience does, then
show the instrument failing and say what it cost.

**Slide style (2026-10-13).** First person, short declarative lines, punch line on
the click.
- **One idea per slide.** When a slide is too loaded, split it into two before
  cutting content.
- **Titles set up the punch, never give it away** ("The result" above 57/57, "The
  part I did not expect" for the judge).
- **Backgrounds are white or black, never grey.** Black (`#161616`) marks the four
  turns only: "Then CRAN rejected us. Twice.", "The result", "The part I did not
  expect", "Take home". Every content slide is white, including "Then I handed it
  the answer" (exploratory; black would oversell it).
- **Vocabulary.**
  - Say "starting package", never "the seed" (it collides with `set.seed()`).
  - Name arms by content (Control, Checklist, Process, General R, Handbook); the
    A-codes appear only in the backup arms table.
  - Say "machine check" or "executable check", not "oracle".
- **Speaker notes follow SAY / DON'T / IF ASKED.** SAY is the one line to land,
  DON'T is load-bearing precision, IF ASKED is Q&A only and never volunteered on
  stage. Keep notes short: long notes invite tangents.
- **Timing.** About 8:00 spoken in a 10-minute slot, with about 2:00 of slack on
  purpose. The budget and two checkpoints (leave the design slide by 3:20, reach
  the judge slide by 5:35) live in the setup chunk, numbered over the 12 main
  slides. If running long, "Then I handed it the answer" is the first slide to move
  back to backup.
- **Active-control framing.** Every arm, the control included, gets the offline CRAN
  docs. In the notes this is told as an add-on trial against an active control
  (standard of care), pre-specified and conservative against the hypothesis. The
  notes concede that this control is stronger than the original interactive packaging
  run, which was not a protocol. Do not call that first pass an "uncontrolled arm" or
  a "lost trace", and do not claim the original agent did or did not read the docs.
- **Say "clean under `R CMD check`", never "CRAN would have taken it".** The check
  is 0 errors and 0 warnings; one A0 tree has a residual NOTE, and a first
  submission carries the normal "New submission" NOTE. Do not say "zero notes". The
  result slide reads "no errors or warnings" in `talk.qmd` (changed 2026-10-17);
  the committed `talk.pdf` still has the old "clean" / "Submission-ready" wording
  until it is rebuilt on the internal PC.
- **Title-slide CSS lives in the YAML `header-includes`**, not in the gitignored
  `novartis-style.scss` (which does not travel with the repo) and not in the body
  (a raw `<style>` block becomes an untitled section and prints blank).
- **No em dashes on rendered slides** (removed 2026-10-16). Colons, commas or full
  stops instead. Notes and comments may keep them.
- **The deck cannot be rebuilt off the internal PC.** `talk.qmd` needs the
  gitignored Novartis assets, and `talk.html` is not shipped because
  `embed-resources: true` inlines them. Off that machine, edit the source if needed
  but present from the committed `talk.pdf`. The 2026-10-16 rebuild of `talk.pdf`
  from this deck is committed (`44317b6`, with `a2e5b22` after it).

- **The repo went public on 2026-10-18** (the experiment is unblinded and over, so
  the answer keys no longer need hiding; the slide links it). The answer-key files
  stay out of any *future* run's arm tree. `talk.pdf` is the only built deck that is
  published; `talk.qmd` and `figures.R` are tracked source. The rest of `talk/` is
  gitignored, and the Novartis template assets (`*.scss`, `*.svg`, `*.pptx`,
  `gradient_bar.png`, …) are added on the internal PC and **must never be
  committed or shipped off this machine**, now more than ever that the repo is public.
- **Never run `quarto render talk.qmd --to pdf`.** Revealjs decks take the
  LaTeX path under `--to pdf`; it deletes the existing `talk.pdf` and then fails
  (no TeX here). `*.tex` and `talk_files/` are gitignored as of 2026-10-07
  precisely because that mistake left them behind.
- **The working PDF route is `chromote` (verified 2026-10-07).** Edge's
  `--print-to-pdf` CLI flag is **broken on this host** — it crashes the network
  and GPU processes (`exit_code=-1073741819`) even on a one-line HTML file, and
  no decktape/node/Chrome is installed. `chromote` drives the same Edge binary
  over the DevTools protocol instead and works:

  ```r
  Sys.setenv(CHROMOTE_CHROME = "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe")
  b <- chromote::ChromoteSession$new()
  b$Page$navigate(paste0("file:///", normalizePath("talk/talk.html", winslash = "/"), "?print-pdf"))
  Sys.sleep(30)  # let reveal.js lay out every slide before printing
  res <- b$Page$printToPDF(landscape = TRUE, printBackground = TRUE,
                           paperWidth = 13.33, paperHeight = 7.5,
                           marginTop = 0, marginBottom = 0,
                           marginLeft = 0, marginRight = 0,
                           preferCSSPageSize = TRUE, transferMode = "ReturnAsBase64")
  writeBin(jsonlite::base64_dec(res$data), "talk/_new.pdf")
  b$close()
  ```

  Print to `_new.pdf` first, verify with `pdftools::pdf_text()`, then replace
  `talk.pdf`. Never print straight over the tracked artefact.
- **Keep deck notes in R comments, never bare HTML comments.** A `<!-- -->`
  block between slides becomes its own untitled `<section>` and prints as a
  blank page. That is what produced the blank page 2 fixed on 2026-10-07; the
  timing budget now lives in the `include: false` setup chunk.
- **Two real rejections, scored differently.** R02 (LICENSE template) was
  repaired in 57/57 runs. R01 (`set.seed()`) was present in the starting package (`seed = 42`
  default plus unconditional `set.seed()` in four exported functions) and the
  original R01 rule missed it; use `scoring/results_r01v2/`, not `seed_audit.json`,
  for R01. Arms differ on it; counts are descriptive (n=9-10 per arm).
- **R01 is an open lead, never a skill-file win.** The re-score is
  post-unblinding. It is defensible because `rescore_r01.R` is a pure function of
  tree content and never reads `.blind_map.csv` — the same code at first
  unblinding gives the same table. The controls (A0, and A4, which had no file) produced the canonical fix **zero**
  times in 20 runs; A2 and A5 mostly did. Still a post-hoc lead, not a result. See `LESSONS_LEARNED.md` §7.3.
  On slide it is labelled only "Post-hoc, exploratory." The rest is said aloud from
  the notes: run after unblinding on one criterion, no test, "a lead, not a result",
  label-blind by construction (say that, not "with the labels known"), and the fair
  criticism is a design oversight, not bias. No take-home may imply prose guidance
  helps on it.
- **The undelivered A4 file is a protocol deviation.** On the "not claiming" slide,
  say that one arm's file never reached the model and those 10 runs joined the
  control. It was caught afterwards from the 7,145-token first call.
- **The n = 5 → 10 extension is not an interim analysis.** On slide: "Not powered;
  n was set by budget." In Q&A: planned 5 per arm, extended after an unblinded look
  because budget allowed, not to chase a result. Counts are descriptive with no
  tests, so there is no error rate to inflate. Never say "interim analysis", never
  say the signal was trending, never claim a pre-registered n = 10.
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
