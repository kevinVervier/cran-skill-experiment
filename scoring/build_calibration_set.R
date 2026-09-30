#!/usr/bin/env Rscript
# ============================================================================
# Calibration set builder -- skill-experiment-preregistration.md §5.1.2,
# "Source 1 -- mutation injection (the sensitivity test)".
#
#   Rscript scoring/build_calibration_set.R
#
# Builds, from `baseline/pkg` (the ACCEPTED CRAN version -- never modified in
# place, per invariant 10), one control copy and the ten MUT-* mutants named
# in rejection-ledger.md's candidate table. Each mutant is a single, surgical,
# labelled-positive edit representing one criterion violation. Output under
# `calibration/`, sibling to `baseline/` and `scoring/` -- not under
# RUNS_ROOT, since no live agent ever touches these trees; only the judge
# reads them.
#
# Re-run is idempotent: each target dir is wiped and rebuilt from
# baseline/pkg fresh, so this can be re-run safely if a mutation needs a fix.
# ============================================================================

BASELINE  <- "baseline/pkg"
CAL_ROOT  <- "calibration"
CONTROL   <- file.path(CAL_ROOT, "control", "pkg")
MUT_ROOT  <- file.path(CAL_ROOT, "mutants")

stopifnot(dir.exists(BASELINE))

fresh_copy <- function(dest) {
  unlink(dest, recursive = TRUE)
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)
  dir.create(dest, recursive = TRUE, showWarnings = FALSE)
  file.copy(list.files(BASELINE, full.names = TRUE), dest, recursive = TRUE)
}

replace_in_file <- function(path, pattern, replacement, fixed = FALSE) {
  txt <- readLines(path, warn = FALSE)
  txt <- sub(pattern, replacement, txt, fixed = fixed)
  writeLines(txt, path)
}

insert_after_line <- function(path, line_pattern, new_line) {
  txt <- readLines(path, warn = FALSE)
  idx <- grep(line_pattern, txt)[1]
  stopifnot(!is.na(idx))
  txt <- append(txt, new_line, after = idx)
  writeLines(txt, path)
}

# ---------------------------------------------------------------------------
# Control -- unmutated accepted version. Specificity check target (§5.1.2
# Source 3): the judge should return near-clean on this.
# ---------------------------------------------------------------------------
cat("=== control ===\n")
fresh_copy(CONTROL)

# ---------------------------------------------------------------------------
# MUT-R01 -- set.seed() with a literal value inside a package function.
# Target: bootstrap_orthoMTL()'s body in R/bootstrap.R.
# ---------------------------------------------------------------------------
cat("=== MUT-R01 ===\n")
d <- file.path(MUT_ROOT, "MUT-R01", "pkg"); fresh_copy(d)
# bootstrap_orthoMTL()'s signature spans many lines; the body only actually
# opens at the final "verbose = TRUE) {" line -- inserting right after the
# "function(" token (as a first attempt did) lands mid-argument-list and
# produces a syntax error, not a mutant. Match the body-opening line instead.
insert_after_line(file.path(d, "R", "bootstrap.R"),
                   "verbose = TRUE\\) \\{$", "  set.seed(42)")

# ---------------------------------------------------------------------------
# MUT-R02 -- `+ file LICENSE` under GPL-3 pointing at a bare copyright
# template (usethis::use_mit_license() scaffolding left over).
# ---------------------------------------------------------------------------
cat("=== MUT-R02 ===\n")
d <- file.path(MUT_ROOT, "MUT-R02", "pkg"); fresh_copy(d)
replace_in_file(file.path(d, "DESCRIPTION"), "^License: GPL-3$", "License: GPL-3 + file LICENSE")
writeLines(c("YEAR: 2026", "COPYRIGHT HOLDER: Kevin Vervier"), file.path(d, "LICENSE"))

# ---------------------------------------------------------------------------
# MUT-L30 -- options()/par() changed in an example without restoration.
# Target: orthoMTL.Rd's \examples{} block.
# ---------------------------------------------------------------------------
cat("=== MUT-L30 ===\n")
d <- file.path(MUT_ROOT, "MUT-L30", "pkg"); fresh_copy(d)
insert_after_line(file.path(d, "man", "orthoMTL.Rd"),
                   "^set\\.seed\\(42\\)$", "options(digits = 3)  # never restored")

# ---------------------------------------------------------------------------
# MUT-L31 -- cat()/print() used for progress messages instead of message().
# Target: bootstrap_orthoMTL()'s body.
# ---------------------------------------------------------------------------
cat("=== MUT-L31 ===\n")
d <- file.path(MUT_ROOT, "MUT-L31", "pkg"); fresh_copy(d)
insert_after_line(file.path(d, "R", "bootstrap.R"),
                   "verbose = TRUE\\) \\{$", '  cat("Running bootstrap...\\n")')

# ---------------------------------------------------------------------------
# MUT-L29 -- a function writes to the user's filespace by default instead of
# tempdir(). Target: plot_heatmap()'s body in R/plot.R.
# ---------------------------------------------------------------------------
cat("=== MUT-L29 ===\n")
d <- file.path(MUT_ROOT, "MUT-L29", "pkg"); fresh_copy(d)
insert_after_line(file.path(d, "R", "plot.R"),
                   "^plot_heatmap <- function\\(",
                   '  write.csv(data.frame(x = 1), "orthoMTL_heatmap_log.csv")')

# ---------------------------------------------------------------------------
# MUT-L23 -- \dontrun{} around an example that actually runs fine (was
# \donttest{}, which does run under --as-cran; \dontrun{} never does).
# ---------------------------------------------------------------------------
cat("=== MUT-L23 ===\n")
d <- file.path(MUT_ROOT, "MUT-L23", "pkg"); fresh_copy(d)
rd <- file.path(d, "man", "bootstrap_orthoMTL.Rd")
txt <- readLines(rd, warn = FALSE)
txt[txt == "\\donttest{"] <- "\\dontrun{"
writeLines(txt, rd)

# ---------------------------------------------------------------------------
# MUT-C01 -- Title contains "in R" (redundant on a CRAN package).
# ---------------------------------------------------------------------------
cat("=== MUT-C01 ===\n")
d <- file.path(MUT_ROOT, "MUT-C01", "pkg"); fresh_copy(d)
replace_in_file(file.path(d, "DESCRIPTION"),
                 "^Title: Multi-Task Learning with Orthogonal Constraints$",
                 "Title: Multi-Task Learning with Orthogonal Constraints in R")

# ---------------------------------------------------------------------------
# MUT-C03 -- Description opens with "This package...".
# ---------------------------------------------------------------------------
cat("=== MUT-C03 ===\n")
d <- file.path(MUT_ROOT, "MUT-C03", "pkg"); fresh_copy(d)
replace_in_file(file.path(d, "DESCRIPTION"),
                 "^Description: Fits regularised multi-task learning models",
                 "Description: This package fits regularised multi-task learning models")

# ---------------------------------------------------------------------------
# MUT-L28 -- example uses a Suggests-only package (glmnet) unguarded.
# ---------------------------------------------------------------------------
cat("=== MUT-L28 ===\n")
d <- file.path(MUT_ROOT, "MUT-L28", "pkg"); fresh_copy(d)
insert_after_line(file.path(d, "man", "orthoMTL.Rd"),
                   "^fit\\$converged   # did optimisation converge\\?$",
                   "glmnet::glmnet(X, Y[, 1])  # Suggests-only, no guard")

# ---------------------------------------------------------------------------
# MUT-C16 -- a new exported function with no \value documented.
# ---------------------------------------------------------------------------
cat("=== MUT-C16 ===\n")
d <- file.path(MUT_ROOT, "MUT-C16", "pkg"); fresh_copy(d)
writeLines(c(
  "#' Quick Summary of an orthoMTL Fit",
  "#'",
  "#' @param object A fitted \\code{\"orthoMTL\"} object.",
  "#' @export",
  "quick_summary <- function(object) {",
  "  sum(object$B)",
  "}"
), file.path(d, "R", "quick_summary.R"))
ns <- file.path(d, "NAMESPACE")
txt <- readLines(ns, warn = FALSE)
insert_idx <- grep("^export\\(", txt)[1]
txt <- append(txt, "export(quick_summary)", after = insert_idx - 1)
writeLines(txt, ns)
writeLines(c(
  "% Generated manually for MUT-C16 (no \\value on purpose)",
  "\\name{quick_summary}",
  "\\alias{quick_summary}",
  "\\title{Quick Summary of an orthoMTL Fit}",
  "\\usage{",
  "quick_summary(object)",
  "}",
  "\\arguments{",
  "\\item{object}{A fitted \"orthoMTL\" object.}",
  "}",
  "\\description{",
  "Quick Summary of an orthoMTL Fit",
  "}"
), file.path(d, "man", "quick_summary.Rd"))

# ---------------------------------------------------------------------------
# EXTENSION (2026-09-30): the ten mutants above come from rejection-ledger.md's
# candidate table, but that table was built to validate the WHOLE oracle
# stack (tooling -> static -> judge), not the judge specifically. Cross-
# checked against scoring/judge_criteria.json (ORACLE=JUDGE rows only): 9 of
# the 10 above (R01, R02, L30, L31, L29, C01, C03, L28, C16) are all
# ORACLE=STATIC per the corpus tables -- the judge's 12-criterion list has
# nothing to detect for them, so they cannot feed the §5.1.2 quantitative
# detection-rate decision rule. Only MUT-L23 lands on a judge criterion.
#
# These 11 additional mutants, one per remaining ORACLE=JUDGE criterion, are
# what actually calibrates the judge. MUT-L23 above also stands as the
# positive for C18 (both concern \dontrun{} legitimacy -- see
# judge_criteria.json's l23_c18_overlap_note); not duplicated here.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(desc))

replace_desc_field <- function(path, field, value) {
  d <- desc(file = path)
  d$set(field, value)
  d$write(file = path)
}

# MUT-C04 -- Description collapsed to one terse line (not an elaborated paragraph).
cat("=== MUT-C04 ===\n")
d <- file.path(MUT_ROOT, "MUT-C04", "pkg"); fresh_copy(d)
replace_desc_field(file.path(d, "DESCRIPTION"), "Description", "Tools for multi-task learning.")

# MUT-C08 -- method mentioned by author/year with no doi:/arXiv:/ISBN:/URL citation.
cat("=== MUT-C08 ===\n")
d <- file.path(MUT_ROOT, "MUT-C08", "pkg"); fresh_copy(d)
replace_desc_field(file.path(d, "DESCRIPTION"), "Description", paste(
  "Fits regularised multi-task learning models where relationships",
  "between tasks are controlled via orthogonality or disjoint-support constraints.",
  "Supports regression, binary classification, and censored survival data.",
  "Implements the penalty described in Vervier et al. (2014)."
))

# MUT-C13 -- maintainer address swapped for a non-durable placeholder-style one.
cat("=== MUT-C13 ===\n")
d <- file.path(MUT_ROOT, "MUT-C13", "pkg"); fresh_copy(d)
replace_in_file(file.path(d, "DESCRIPTION"),
                 "kevin.vervier@novartis.com", "maintainer@example.com", fixed = TRUE)

# MUT-L06 -- an unexplained acronym in Description.
cat("=== MUT-L06 ===\n")
d <- file.path(MUT_ROOT, "MUT-L06", "pkg"); fresh_copy(d)
replace_desc_field(file.path(d, "DESCRIPTION"), "Description", paste(
  "Fits regularised multi-task learning models using GWAS-derived feature",
  "sets, where relationships between tasks are controlled via orthogonality",
  "or disjoint-support constraints. Supports regression, binary",
  "classification, and censored survival data."
))

# MUT-L08 -- double quotes used for emphasis rather than a publication title.
cat("=== MUT-L08 ===\n")
d <- file.path(MUT_ROOT, "MUT-L08", "pkg"); fresh_copy(d)
replace_desc_field(file.path(d, "DESCRIPTION"), "Description", paste(
  "Fits regularised multi-task learning models where relationships between",
  'tasks are controlled via orthogonality or disjoint-support constraints.',
  'Provides "fast" and "accurate" estimation for regression, binary',
  "classification, and censored survival data."
))

# MUT-L09 -- Description centers on naming the wrapper function, not the package.
cat("=== MUT-L09 ===\n")
d <- file.path(MUT_ROOT, "MUT-L09", "pkg"); fresh_copy(d)
replace_desc_field(file.path(d, "DESCRIPTION"), "Description",
  "The main function orthoMTL() fits a multi-task model. Call orthoMTL() with a predictor matrix and a response matrix to get coefficients.")

# MUT-L10 -- Description too thin, no detail on functionality or methods.
cat("=== MUT-L10 ===\n")
d <- file.path(MUT_ROOT, "MUT-L10", "pkg"); fresh_copy(d)
replace_desc_field(file.path(d, "DESCRIPTION"), "Description",
  "Tools for multi-task learning. See the documentation for details.")

# MUT-L12 -- \references{} block removed even though a published method is implemented.
cat("=== MUT-L12 ===\n")
d <- file.path(MUT_ROOT, "MUT-L12", "pkg"); fresh_copy(d)
rd <- file.path(d, "man", "orthoMTL.Rd")
txt <- readLines(rd, warn = FALSE)
start <- grep("^\\\\references\\{$", txt)
stopifnot(length(start) == 1)
end <- start - 1 + grep("^\\}$", txt[start:length(txt)])[1]
writeLines(txt[-(start:end)], rd)

# MUT-L21 -- version number inflated for what is presented as a first submission.
cat("=== MUT-L21 ===\n")
d <- file.path(MUT_ROOT, "MUT-L21", "pkg"); fresh_copy(d)
replace_desc_field(file.path(d, "DESCRIPTION"), "Version", "2.5.0")

# MUT-L27 -- example uses a conspicuously large simulated dataset.
cat("=== MUT-L27 ===\n")
d <- file.path(MUT_ROOT, "MUT-L27", "pkg"); fresh_copy(d)
replace_in_file(file.path(d, "man", "orthoMTL.Rd"),
                 "n <- 100; p <- 10; n_tasks <- 3", "n <- 100000; p <- 5000; n_tasks <- 3", fixed = TRUE)

cat("\ncalibration set built: 1 control + 21 mutants under ", CAL_ROOT, "/\n", sep = "")
