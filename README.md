# CRAN skill-file experiment

A pre-registered, controlled comparison of agent-assisted R package preparation with and without a
CRAN-specific skill file. Subject package: [`orthoMTL`](https://github.com/Novartis/orthoMTL).
Output: an R/Pharma 2026 lightning talk.

**This is a measurement instrument, not a software project.** The harness, prompts, and scoring
pipeline here are frozen once a run starts — see the invariants in [`CLAUDE.md`](CLAUDE.md) before
changing anything.

Full design, hypotheses, and stopping rules: [`skill-experiment-preregistration.md`](skill-experiment-preregistration.md) —
that file is the spec, not this one.

## Layout

This repo (`cran-skill-experiment`) holds the harness, scoring pipeline, prompts, and docs. Arm
trees and run artifacts live in a **separate**, deliberately un-nested root — see
[`KICKOFF.md`](KICKOFF.md) for the resolved path and for why the two are kept apart (`CLAUDE.md`
walks up the directory tree, so any instruction file above an arm's tree would leak into every
arm, including the no-skill control).

## Status

Private while blocks 2–5 are running. Contains material (`rejection-ledger.md`, `criterion-corpus*.md`)
that must never reach an agent arm and must not be unblinded before scoring is committed — see
invariants 7–8 in `CLAUDE.md`. Expect this to go public once scoring is complete and the talk has
been given.
