# Rejection ledger — `orthoMTL`

Ground truth for judge calibration (§5.1.2) and for the mutation set. Extract every distinct finding
from the four human review letters. **Freeze before any arm runs.**

Each row carries four things: the finding, whether the frozen check suite emits it, whether a
deterministic static rule can catch it, and the mutation that injects it.

---

## Schema

| Field | Meaning |
|-------|---------|
| **ID** | `R01`, `R02`, … |
| **Finding** | as stated by the reviewer |
| **Round** | which of the two rejection rounds |
| **Tooling** | does the frozen check suite (§4.1) emit it? `Y` / `N` |
| **Static rule** | can a deterministic grep/AST rule catch it? `Y` / `N` |
| **Class** | `TOOLING` / `STATIC` / `JUDGE` / `UNREACHABLE` |
| **Mutation** | how to inject it into the accepted version |
| **Origin** | why a competent agent would produce this |

**Class assignment, in priority order.** A finding goes to the cheapest oracle that can catch it:
tooling → static rule → judge. Only findings no rule can express reach the judge. This matters
because the judge is the noisiest instrument in the study; every finding moved out of it reduces the
study's dependence on judge calibration.

---

## Findings

### R01 — `set.seed()` inside a function

> Please do not set a seed to a specific number within a function.

| | |
|---|---|
| **Round** | **2** — fixed 2026-08-07 (`fix(cran): do not hardcode set.seed() defaults in exported functions`, PR "fix/no-hardcoded-seed-cran-feedback"), same day as `docs/cran-comments-resubmission-2` prep. Confirmed by Kevin 2026-09-20 from git-history inference — no direct rejection-email text consulted. |
| **Tooling** | **N** — `R CMD check --as-cran` does not flag this |
| **Static rule** | **Y** |
| **Class** | `STATIC` |
| **Origin** | Reproducibility is a virtue in statistical code. Setting a seed inside a function looks responsible; it silently hijacks the user's RNG stream. An agent writing careful-looking R produces this by default. |

**Static rule.** Parse each file in `R/`; flag any `set.seed()` call appearing inside a function
body with a literal numeric argument. Exclude `tests/`, `vignettes/`, `inst/`, and top-level script
files — the objection is specifically to seeds set inside package functions.

```r
# scoring/static_rules/R01_seed_in_function.R
flag_seed_in_function <- function(pkg_dir) {
  files <- list.files(file.path(pkg_dir, "R"), pattern = "[.][Rr]$", full.names = TRUE)
  hits <- list()
  for (f in files) {
    exprs <- tryCatch(parse(f, keep.source = TRUE), error = function(e) NULL)
    if (is.null(exprs)) next
    walk <- function(e, in_fn = FALSE) {
      if (is.call(e)) {
        if (identical(e[[1]], quote(`function`))) in_fn <- TRUE
        if (identical(e[[1]], quote(set.seed)) && in_fn &&
            length(e) > 1 && is.numeric(e[[2]])) {
          hits[[length(hits) + 1]] <<- list(file = basename(f), call = deparse(e))
        }
        for (i in seq_along(e)) if (i > 1 || !is.name(e[[i]])) {
          tryCatch(walk(e[[i]], in_fn), error = function(err) NULL)
        }
      }
    }
    for (e in exprs) walk(e)
  }
  hits
}
```

**Mutation `MUT-R01`.** Insert `set.seed(42)` at the top of one exported function's body in the
accepted version.

**Behavioural note.** A naive fix — deleting the call — may break tests that relied on it. That is
exactly what the frozen held-out suite (§5) is for: an arm that removes the seed and breaks
determinism where tests expect it has not solved the problem. Check `R01` and test pass rate
jointly.

---

### R02 — `+ file LICENSE` with a boilerplate LICENSE under GPL-3

> License components with restrictions and base license permitting such:
> `GPL-3 + file LICENSE`. Please omit `+ file LICENSE` and the file itself, which looks like a
> template for the MIT license. For GPL-3, it is only used to specify additional restrictions to the
> GPL such as attribution requirements.

| | |
|---|---|
| **Round** | **1** — fixed 2026-07-10 (`fix(cran): drop invalid + file LICENSE per CRAN reviewer feedback`, PR "fix/license-field-cran-feedback"), a month before the seed fix and before any "resubmission 2" labeling appears. Confirmed by Kevin 2026-09-20 from git-history inference — no direct rejection-email text consulted. |
| **Tooling** | **N** — check validates that the License field parses and the referenced file exists, not whether the file's *content* is appropriate to the base license |
| **Static rule** | **Y** |
| **Class** | `STATIC` |
| **Origin** | `usethis::use_mit_license()` writes a `YEAR` / `COPYRIGHT HOLDER` template. Combine that with a GPL-3 DESCRIPTION and you get exactly this. The failure comes from idiomatic tooling, not carelessness — which is why an agent following standard R practice reproduces it. |

**Static rule.** Flag when the License field names a GPL variant **and** includes `+ file LICENSE`
**and** the LICENSE file contains only `YEAR:` / `COPYRIGHT HOLDER:` lines with no substantive
additional restriction.

```r
# scoring/static_rules/R02_license_template.R
flag_license_template <- function(pkg_dir) {
  lic <- tryCatch(desc::desc_get_field("License", file = pkg_dir), error = function(e) NA)
  if (is.na(lic) || !grepl("\\+ *file LICENSE", lic)) return(list())
  if (!grepl("^GPL|^AGPL|^LGPL", lic)) return(list())
  lf <- file.path(pkg_dir, "LICENSE")
  if (!file.exists(lf)) return(list())
  txt <- readLines(lf, warn = FALSE)
  body <- trimws(txt[nzchar(trimws(txt))])
  looks_template <- all(grepl("^(YEAR|COPYRIGHT HOLDER)\\s*:", body, ignore.case = TRUE))
  if (looks_template) list(list(license = lic, lines = body)) else list()
}
```

**Mutation `MUT-R02`.** Set `License: GPL-3 + file LICENSE` in the accepted version and add a
two-line `YEAR:` / `COPYRIGHT HOLDER:` LICENSE file.

---

### R03 and beyond

**The ledger is complete at two findings.** There were two rejection rounds, both from human
review; the remaining CRAN emails were automated confirmations of successful checks. R01 and R02 are
the whole of it.

### Where the cost actually was

Two rounds is a short round-trip, and the study should not pretend otherwise. But the effort was
never mostly in the round-trips — it was in the pre-submission loop: repeated local `--as-cran`
failures (§4.6), compliance requirements discovered by reading rather than by being told (§4.5), and
manual enforcement by the maintainer between the agent and the submission.

**That is precisely what this experiment measures.** Turns to a clean check, find-and-fix rounds,
residual review burden and regressions are all pre-submission quantities. The two CRAN rounds are
the visible tip; the endpoints target the part underneath.

Say this plainly in the talk rather than inflating the round count. "Two rejections, and weeks of
work before them" is both true and the more interesting claim.

---

## Consequence: the mutation set comes from the corpus, not the ledger

With two findings, the ledger cannot source a mutation set on its own. Build `MUT-*` from
`criterion-corpus.md` and `criterion-corpus-longtail.md` instead, **weighted toward the
idiomatic-but-wrong class that R01 and R02 exemplify** — defects a competent R developer produces by
following convention, not by carelessness.

Good candidates from the corpus, all in that class:

| Mutant | Source | Why it is idiomatic |
|--------|--------|---------------------|
| `MUT-R01` | R01 | reproducibility habit |
| `MUT-R02` | R02 | `usethis::use_mit_license()` scaffolding |
| `MUT-L30` | L30 | `options()` / `par()` changed in an example without restoration |
| `MUT-L31` | L31 | `cat()` / `print()` for progress messages |
| `MUT-L29` | L29 | a default output path in a writing function |
| `MUT-L23` | L23 | `\dontrun{}` around an example that runs fine |
| `MUT-C01` | C01 | "in R" in the Title — reads natural on GitHub |
| `MUT-C03` | C03 | Description opening "This package…" |
| `MUT-L28` | L28 | example using a `Suggests` package unguarded |
| `MUT-C16` | C16 | a new exported function with no `\value` |

Ten to fifteen is enough. Each is injected into the accepted version singly, giving a labelled
positive with a known answer.

R01 and R02 remain the face-validity check — *the judge caught both of the findings CRAN actually
raised on this package* — reported qualitatively, with n=2 stated plainly and no rate attached.

---

## Pattern to watch

Both known findings are **idiomatic-but-wrong**: they arise from defaults a competent R developer
would produce — reproducibility habits, `usethis` scaffolding — not from sloppiness. If the rest of
the ledger holds this shape, it sharpens the talk considerably:

> The failures were not the agent being careless. They were the agent being conventional. The
> conventions are wrong for CRAN, and no amount of general R craft guidance would have caught them.

That prediction is testable against `A3` (general R packaging skill, no CRAN targeting). If `A3`
performs no better than `A0` on these findings, the claim holds.

---

## Roll-up (fill as rows are added)

| Class | Count | Oracle | Reliability |
|-------|-------|--------|-------------|
| `TOOLING` | 0 | frozen check suite | deterministic |
| `STATIC` | 2 (R01, R02) | static rules | deterministic |
| `JUDGE` | 0 | LLM reviewer | needs calibration |
| `UNREACHABLE` | 0 | none | declared gap |

Filled 2026-09-20 — the ledger is complete at two findings (see above), both `STATIC`, so this
roll-up is already final, not partial. **Ratio: 2/2 in `STATIC`, 0 in `JUDGE`.** On the two findings
CRAN actually raised, the judge is not load-bearing at all — the strongest version of the claim in
the note above.

**Static rules validated this session** (2026-09-20): `scoring/static_rules/R01_seed_in_function.R`
and `R02_license_template.R` were run against `baseline/pkg`, the seed (`arms/A0/pkg`), and a fresh
clone of the real `kevinVervier/orthopen` (9-year-old original, not the locally-developed copy that
was archived — see `Bricoles/orthopen-local-dev-archive-2026-09-20.zip`). Zero hits on all three,
confirmed by hand to be true negatives, not rule bugs or missed violations: every `set.seed` present
across all three trees is either inside a roxygen example comment (not parsed as code) or takes a
caller-supplied `seed` argument (not a literal number), and none of the three combine a GPL-family
`License` with `+ file LICENSE` naming a template `LICENSE` file. No tree tested so far actually
violates R01/R02 — that is what the mutation set is for, not this validation pass.

**The ratio is a headline number.** If most findings land in `TOOLING` or `STATIC`, the study rests
on deterministic oracles and the judge becomes a supplement rather than a dependency — which is a far
stronger position than the one assumed in §7.
