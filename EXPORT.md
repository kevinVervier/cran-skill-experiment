# Transferring this repo to another machine

Written 2026-10-07. The repo has no reachable remote (`cran.r-project.org` egress is blocked and
there is no push target), so transfer is by **git bundle** — a single file carrying the complete
history that clones like a normal remote on the far side.

## What you were given

| File | What it is |
|---|---|
| `cran-skill-experiment.bundle` | The whole repository, all branches, full history (~1.9 MB) |
| `Vervier_RPharma2026_orthoMTL.pdf` | The built deck, if the talk is all you need |

## Restoring

```bash
git clone cran-skill-experiment.bundle cran-skill-experiment
cd cran-skill-experiment
git log --oneline -1    # expect e7f606c
git ls-files | wc -l    # expect 2353
```

The clone sets the bundle as `origin`. That remote is a dead file path — remove it or repoint it
before committing anything you intend to keep:

```bash
git remote remove origin
```

## What is NOT in the bundle, and why

**The Novartis template assets.** `talk/` depends on files that are gitignored by design and must
never leave the internal machine (`CLAUDE.md`, talk section):

- `novartis-style.scss`
- `Logo Warm Black RGB.svg`
- `gradient_bar.png`
- `novartis2026_template.pptx`
- `cran.png`, `surv_mtl.png` (figure images)

**Consequence: `talk.qmd` will not render on the target machine** until those are copied across by
whatever route is approved for internal assets. The built `talk/talk.pdf` *is* in the bundle, so if
you only need to read or present the deck, nothing further is required. Rebuilding it needs the
assets plus the `chromote` route in `CLAUDE.md`.

**`talk.html` is deliberately excluded** from both the bundle and any email attachment: Quarto
builds it with `embed-resources: true`, which inlines the template assets into the file. Shipping
the HTML would ship the assets.

**The blinded arm trees.** `RUNS_ROOT` (the `arms/`, `runs/` and `blinded/` directories) was never
part of this repo and lives only on the original Shadow cloud PC. The repo carries the *derived*
scoring artefacts — `scoring/results/*/` (findings, judge output, seed audits),
`unblinded_results.csv`, `scoring/results_r01v2/` — but not the package trees they were computed
from. Anything requiring the trees themselves (e.g. hand-verifying the R01 classification, §11)
cannot be done from the bundle alone.

## Environment

The bundle does not carry the toolchain. `ENVIRONMENT.md` records the native R/TeX/pandoc/qpdf/
Ghostscript versions this experiment was run against, and invariant 9 fixes them for the duration
of the experiment. The experiment is complete, so the target machine only needs enough to read the
documents and rebuild the deck — but do not re-run any arm on a different toolchain and compare it
to these results.

R packages used by the analysis in this repo: `ggplot2`, `dplyr`, `readr`, `jsonlite`, `purrr`,
`pdftools`, `chromote` (deck printing only).

## Verifying what arrived

```bash
git bundle verify cran-skill-experiment.bundle   # "The bundle records a complete history"
sha256sum cran-skill-experiment.bundle
```

Compare the checksum against the one sent alongside the file.
