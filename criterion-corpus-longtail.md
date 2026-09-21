# CRAN human review — long-tail catalogue

Companion to `criterion-corpus.md`. That file holds the well-known criteria; this one holds the
**long tail**: findings observed once or twice in the wild, scraped from `cran-comments.md` files,
GitHub issue threads, and the r-package-devel archives.

Rare findings matter here because the study's whole premise is that `orthoMTL` died on human review,
not on the automated gate. The long tail *is* human review.

`FREQ`: `HIGH` = cited across several independent sources · `MED` = a few · `N1` = one observed case.
`ORACLE` per §4.8: `TOOLING` → `STATIC` → `JUDGE`.

---

## A. Title

| ID | Finding | FREQ | ORACLE |
|----|---------|------|--------|
| L01 | Title exceeds 65 characters — rejection recorded with a request to shorten | MED | STATIC |
| L02 | Title is just the package name; a real title was demanded | N1 | STATIC |
| L03 | Redundant lead-ins flagged: "A Toolkit for", "Tools for", "for R" | HIGH | STATIC |
| L04 | Backticks (`` `` ``) used instead of single quotes in the Title field | N1 | STATIC |
| L05 | Title not in title case — reviewer supplied the corrected version verbatim | HIGH | STATIC |

## B. Description prose

| ID | Finding | FREQ | ORACLE |
|----|---------|------|--------|
| L06 | Every acronym must be expanded in Description — X-SAMPA, BPMN, GWAS, SNP | HIGH | JUDGE |
| L07 | Acronyms belong in Description, not Title | MED | STATIC |
| L08 | Double quotes reserved for publication titles; not for emphasis or ordinary phrases | N1 | JUDGE |
| L09 | Description names the main wrapper function instead of describing the package | N1 | JUDGE |
| L10 | Description too thin — "add more details about functionality and implemented methods" | HIGH | JUDGE |
| L11 | `\code{}` markup used inside DESCRIPTION; removal requested | N1 | STATIC |
| L12 | References are a strong suggestion, not compulsory — but asked for on most new submissions | HIGH | JUDGE |
| L13 | arXiv preprints should use `doi:10.48550/arXiv.YYMM.NNNNN`, not bare `arXiv:` | N1 | STATIC |

## C. DESCRIPTION fields

| ID | Finding | FREQ | ORACLE |
|----|---------|------|--------|
| L14 | Invalid MARC role (`rth`) rejected at pretest | N1 | STATIC |
| L15 | `Remotes:` field present — must be removed for CRAN | N1 | STATIC |
| L16 | `Depends: R (>= 3.3.3)` — patchlevel dependency rejected; use `x.y.0` | N1 | STATIC |
| L17 | `LazyData: true` with no `data/` directory | MED | STATIC |
| L18 | Stale `Date:` field on resubmission of an archived package | N1 | STATIC |
| L19 | CITATION uses old-style `personList()` / `citEntry()` instead of `c()` / `bibentry()` | MED | STATIC |
| L20 | No `Authors@R` field at all | MED | STATIC |
| L21 | Version number reduced at reviewer's implicit prompting to reflect maturity | N1 | JUDGE |

## D. Examples

| ID | Finding | FREQ | ORACLE |
|----|---------|------|--------|
| L22 | Package submitted with **no examples at all** — "can you add some examples" | N1 | STATIC |
| L23 | `\dontrun{}` → `\donttest{}` unless genuinely unrunnable. The single most-quoted paragraph in all reviewer correspondence | HIGH | JUDGE |
| L24 | Reviewer's preferred structure: user-facing examples, then `\dontshow{}` for check-only, each < 5 s | MED | STATIC |
| L25 | Roxygen example for an **unexported** function must call it with `pkg:::fun()` | MED | STATIC |
| L26 | Examples exceeding 10 s CPU. Note: `--as-cran` does **not** run `\donttest{}` locally, but CRAN runs it periodically — so local silence is not safety | HIGH | TOOLING |
| L27 | Large example datasets rejected on principle: examples exist to show call syntax, not to demonstrate scale | N1 | JUDGE |
| L28 | Examples must run without `Suggests` / `Enhances` packages installed — guard with `@examplesIf` or `if (require(pkg))` | MED | STATIC |

## E. Runtime and filesystem

| ID | Finding | FREQ | ORACLE |
|----|---------|------|--------|
| L29 | Functions must not write by default to the user's filespace — including the package directory and `getwd()`. Omit default paths; write to `tempdir()` | HIGH | STATIC |
| L30 | Reset `options()`, `par()`, and working directory after changing them in examples, vignettes **and demos** — `old <- options(digits = 3) … options(old)` | HIGH | STATIC |
| L31 | Console messages that cannot be suppressed — use `message()` / `warning()`, not `print()` / `cat()`; better still, return an object with a `print` method | HIGH | STATIC |
| L32 | More than 2 parallel cores used by default in examples, vignettes or tests | MED | STATIC |
| L33 | Overall check time > 10 minutes | MED | TOOLING |
| L34 | Detritus left in the temp directory (`lastMiKTeXException`) | MED | TOOLING |

## F. Documentation and links

| ID | Finding | FREQ | ORACLE |
|----|---------|------|--------|
| L35 | `\value` missing from exported functions. Second most-quoted item after `\dontrun{}` | HIGH | STATIC |
| L36 | Relative file URIs in README — `LICENSE`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, a vignette PDF | HIGH | STATIC |
| L37 | URL redirects flagged even when status is 200 — a missing trailing slash is enough | HIGH | TOOLING |
| L38 | `\keyword{}` entries with trailing commas, or leftover roxygen template text, generating several index terms | MED | STATIC |
| L39 | Lost braces / escaped LaTeX specials (`\&`) in Rd | MED | TOOLING |
| L40 | HTML5-invalid `<img align=>` attribute | MED | TOOLING |

## G. Process and conduct

| ID | Finding | FREQ | ORACLE |
|----|---------|------|--------|
| L41 | Resubmission of an archived package must state what caused the archival | MED | — |
| L42 | Tarball filename must follow `PACKAGE_VERSION.tar.gz` from `R CMD build` | N1 | — |
| L43 | Tests should carry `skip_on_cran()` where long or fragile | MED | STATIC |
| L44 | Reviewers do reverse themselves — at least one comment was retracted as a false positive on appeal | N1 | — |

---

## What the long tail actually shows

**1. The reviewer team is tiny and its boilerplate is stable.** The same names recur across years —
Uwe Ligges, Martina Schmirl, Swetlana Herbrandt, Benjamin Altmann, Julia Haider — and so does the
wording. The `\dontrun{}` paragraph appears near-verbatim in submissions years and continents apart.

This is good news for the judge: the target is a small set of stable, reusable sentences, not an
open-ended notion of quality. It also means **criteria can be phrased in the reviewers' own
wording**, which should improve detection.

**2. Overlap with arm `A1` is now confirmed at the item level.** Posit's `cran-extrachecks` is
derived from `DavisVaughan/extrachecks`, a public dump of ad-hoc CRAN checks — and its contents map
almost one-to-one onto entries here: the 65-character title limit, single-quoted software names,
forbidden "Functions for" openings, redirecting URLs, `:::` in unexported examples.

This is no longer a risk to declare; it is a measured fact to handle. `A1`'s score on any criterion
traceable to `extrachecks` measures overlap between two documents that share a source. Tag each
criterion with whether `extrachecks` covers it, and report `A1` on the uncovered subset separately.

**3. `STATIC` continues to dominate.** Of 44 long-tail findings, roughly 26 are exact rules, 8 are
already emitted by tooling, 8 need judgement, and 2 are process-only. **The judge is needed for
under a fifth of the corpus.** Combined with the core file, this is the strongest available argument
that the study does not rest on judge calibration.

**4. The `orthoMTL` findings fit the observed distribution.** Both known letter items —
`set.seed()` inside a function, `+ file LICENSE` under GPL-3 — are idiomatic-but-wrong in exactly
the way L30 (unrestored `options()`) and L31 (`cat()` to console) are. Careful, conventional R that
CRAN forbids. The mutation set should be weighted toward this class rather than toward obvious
breakage.

---

## Appendix: emulating `\dontrun` locally — the hiding audit

**`\donttest` needs no emulation.** Since R 4.0.0, `--as-cran` runs it by default, in two passes:
first with `\donttest` commented out, then again including it, with only the first pass timed and
compared against any `.Rout.save`. The env var `_R_CHECK_DONTTEST_EXAMPLES_` controls it and defaults
to false *except* under `--as-cran`.

**`\dontrun` is never run by check** under any default. That makes it the only place an arm can hide
a failing or slow example from the tooling oracle — and, not coincidentally, the single most-quoted
paragraph in all reviewer correspondence (L23).

### The three invocations

```bash
# 1. Baseline scoring pass — what CRAN's incoming check does.
#    \donttest runs; \dontrun does not.
R CMD check --as-cran pkg_0.1.0.tar.gz

# 2. Hiding audit — forces \dontrun to execute.
R CMD check --as-cran --run-dontrun pkg_0.1.0.tar.gz

# 3. Isolate a single example set without a full check.
R -q -e 'tools::testInstalledPackage("pkg", commentDontrun = FALSE, commentDonttest = FALSE)'
```

From R: `rcmdcheck::rcmdcheck(args = c("--as-cran", "--run-dontrun"))`, or
`devtools::check(run_dont_test = TRUE)`, which sets `--run-donttest` (note: *donttest*, not
*dontrun* — the argument name does not cover the case you need here).

### Audit rule

Run pass 1 and pass 2. Then:

> Any example wrapped in `\dontrun{}` that completes successfully in under 5 seconds under
> `--run-dontrun` is a finding.

That is the reviewers' own threshold, quoted near-verbatim across years of correspondence: unwrap if
executable in under 5 seconds, otherwise use `\donttest{}`. `\dontrun{}` is legitimate only where the
example genuinely cannot run — missing software, missing API keys.

```r
# scoring/static_rules/L23_dontrun_audit.R
# Compare pass 1 and pass 2 timings per example file.
# An example that only appears in pass 2 AND completes < 5s was hidden, not unrunnable.
audit_dontrun <- function(pass1_timings, pass2_timings, threshold = 5) {
  hidden <- setdiff(names(pass2_timings), names(pass1_timings))
  Filter(function(f) pass2_timings[[f]] < threshold, hidden)
}
```

### Why this belongs in the design

It closes the deletion loophole from a second direction. §5's frozen test suite catches an arm that
removes functionality; this catches an arm that keeps functionality but hides a broken or slow
example behind `\dontrun{}` to get a clean check. Both are ways to pass the tooling oracle without
solving the problem, and the most-cited CRAN complaint is exactly this move.

Add pass 2 to the frozen check suite (§4.1) and record `dontrun_hidden` as a finding category.

---

## Sources

r-package-devel archives (2018–2025) · `DavisVaughan/extrachecks` · `ThinkR-open/prepare-for-cran` ·
*R Packages* (2e) ch. 9 and 22 · CRAN submission checklist and Repository Policy · public
`cran-comments.md` files and CRAN-feedback issue threads from `polite`, `RAINBOWR`, `NeuroDecodeR`,
`firebase`, `gsloid`, `secuTrialR`, `bpmnVisualizationR`, `checkhelper`, `codebookr`, `mcgibbsit`,
`BayesCTDesign`

Record the capture date. Community sources drift; freeze the corpus with a date attached.
