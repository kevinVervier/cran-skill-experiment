# Criterion corpus — CRAN human review

Criteria for the judgement oracle (§5.1), drawn from crowd-sourced reports of what CRAN reviewers
actually ask maintainers to change. Automated `R CMD check` failures are deliberately excluded —
every `orthoMTL` submission passed the automated gate.

**Freeze this file before writing `A4` and before any arm runs.**

---

## Provenance and oracle class

`PROV` tags the source (§5.1.4): `HANDBOOK` = in the snapshot every arm receives; `COMMUNITY` =
folklore not in the official docs; `LETTER` = from `orthoMTL`'s own reviews, **excluded from arm
scoring**.

`ORACLE` assigns the cheapest instrument that can catch it (§4.8): `TOOLING` → `STATIC` → `JUDGE`.

---

## A. DESCRIPTION — Title and Description

The Title and Description fields are the most-cited nitpicking hotspot in human review.

| ID | Criterion | PROV | ORACLE |
|----|-----------|------|--------|
| C01 | Title contains no "in R" / "with R" — redundant on a CRAN package | COMMUNITY | STATIC |
| C02 | Title is in title case | HANDBOOK | STATIC |
| C03 | Description does not start with "This package", "A package", or the package name | HANDBOOK | STATIC |
| C04 | Description is an elaborated paragraph, not one line | HANDBOOK | JUDGE |
| C05 | Other package and software names in single quotes, correctly capitalised (`'Shiny'`, not `'shiny'`) | HANDBOOK | STATIC |
| C06 | Acronyms capitalised (`API`, not `Api`) | COMMUNITY | STATIC |
| C07 | Function names written with parentheses — `cat()` | HANDBOOK | STATIC |
| C08 | Method/API references cited as `doi:`, `arXiv:`, `ISBN:` or URL | HANDBOOK | JUDGE |
| C09 | References use angle brackets, no space after `doi:` / `https:` | HANDBOOK | STATIC |
| C10 | Description avoids redundant repetition of the package name | HANDBOOK | STATIC |

## B. DESCRIPTION — roles and licence

| ID | Criterion | PROV | ORACLE |
|----|-----------|------|--------|
| C11 | `Authors@R` includes a copyright holder (`cph`) — author or employer | HANDBOOK | STATIC |
| C12 | ORCID supplied via `comment = c(ORCID = ...)` where available | HANDBOOK | STATIC |
| C13 | Maintainer email address is appropriate and durable | COMMUNITY | JUDGE |
| C14 | `+ file LICENSE` used only for *additional restrictions*, never a bare copyright template | **LETTER** | STATIC |
| C15 | All DESCRIPTION slots filled | COMMUNITY | STATIC |

## C. Documentation

| ID | Criterion | PROV | ORACLE |
|----|-----------|------|--------|
| C16 | Every exported function documents a return value; document it even when nothing is returned | HANDBOOK | STATIC |
| C17 | Internal functions with partial documentation carry `@noRd` | COMMUNITY | STATIC |
| C18 | `\dontrun{}` only where the example genuinely cannot run — missing software, API keys | HANDBOOK | JUDGE |
| C19 | Examples runnable in under ~5 s are unwrapped; slower ones use `\donttest{}`, not `\dontrun{}` | COMMUNITY | STATIC |
| C20 | Examples never wrapped in `if (FALSE) {}`; use `if (interactive()) {}` | COMMUNITY | STATIC |
| C21 | No empty documentation tags | COMMUNITY | STATIC |
| C22 | URLs use https and canonical form (`https://CRAN.R-project.org/package=`) | HANDBOOK | TOOLING |
| C23 | No relative file URIs in README — `LICENSE.md`, `NEWS.md` must be absolute | COMMUNITY | STATIC |
| C24 | No HTML5-invalid attributes (`<img align=>`) | COMMUNITY | TOOLING |

## D. Runtime behaviour

The category `R CMD check` is weakest at, and where `orthoMTL`'s own seed finding sits.

| ID | Criterion | PROV | ORACLE |
|----|-----------|------|--------|
| C25 | No `set.seed()` with a literal value inside a package function | **LETTER** | STATIC |
| C26 | Nothing written to the user's home filespace or clipboard; `tempfile()` / `tempdir()` only | HANDBOOK | STATIC |
| C27 | Temporary artefacts cleaned up after examples, tests and vignettes | COMMUNITY | STATIC |
| C28 | `options()` and `par()` restored on exit | COMMUNITY | STATIC |
| C29 | Nothing installed into the system R installation | HANDBOOK | STATIC |
| C30 | Default core/thread use ≤ 2 | HANDBOOK | STATIC |

## E. Submission conduct

Not scoreable on an output tree — listed for completeness, excluded from arm scoring.

| ID | Criterion | PROV | ORACLE |
|----|-----------|------|--------|
| C31 | Resubmission bumps the patch version | COMMUNITY | — |
| C32 | `cran-comments.md` states it is a resubmission and what changed | COMMUNITY | — |
| C33 | New versions not submitted more often than ~30 days | COMMUNITY | — |

---

## Two things this survey settled

**1. The overlap risk is confirmed, not hypothetical.** The main community list points readers to
`DavisVaughan/extrachecks` for solutions to CRAN feedback — and Posit's `cran-extrachecks` skill
(arm `A1`) derives from that same lineage. `A1` and the `COMMUNITY` criteria share ancestry.

Consequence for §5.1.4: compute per-criterion overlap between `A1`'s content and this corpus before
scoring, and report `A1`'s `COMMUNITY` panel with that caveat or restrict it to `HANDBOOK`. Do not
present `A1` winning the community panel as a clean result.

**2. Most criteria are `STATIC`, not `JUDGE`.** Of ~30 scoreable criteria, roughly five genuinely
need judgement — whether a Description reads as an informative paragraph, whether a `\dontrun{}` is
justified, whether a maintainer address is durable. The rest are exact rules.

This is the most useful result of the survey. The study's dependence on judge calibration is much
smaller than §7 assumed: build the static rules, and the judge covers a handful of prose-quality
criteria rather than carrying the whole conformance endpoint.

---

## Sources

- ThinkR-open/prepare-for-cran — crowd-sourced list of things CRAN asks maintainers to change
- CRAN submission checklist and CRAN Repository Policy (both `HANDBOOK`)
- *R Packages* (2e), release chapter — Title/Description as human-review hotspots, `cph` role
- DavisVaughan/extrachecks — solutions to CRAN feedback; ancestor of arm `A1`
- `orthoMTL` review letters (`LETTER` rows)

Record the capture date for each. Community sources drift; the corpus must be frozen with a date.
