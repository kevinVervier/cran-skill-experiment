#!/usr/bin/env Rscript
# ============================================================================
# Finding extraction — pre-registration sections 4.1 / 4.3
#
#   Rscript scoring/extract_findings.R blinded/RUN-a7f3
#
# Runs the frozen check suite against one (blinded) output tree, normalises the
# results into comparable finding records, and subtracts the baseline set.
#
# BUILD AND TEST THIS BEFORE ANY EXPERIMENTAL RUN. Section 4.3 requires it to
# be validated on the baseline plus one deliberately broken tree. A parser
# written after seeing arm output is a parser fitted to arm output.
# ============================================================================

suppressPackageStartupMessages({
  library(rcmdcheck); library(jsonlite)
})

args        <- commandArgs(trailingOnly = TRUE)
pkg_dir     <- args[1]
is_baseline <- "--baseline" %in% args   # write baseline/env-check/baseline_categories.json
                                         # instead of subtracting against it (there is nothing
                                         # to subtract against yet on the baseline's own run)
out_dir <- file.path("scoring/results", basename(pkg_dir))
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ---------------------------------------------------------------------------
# Environment-failure signal (section 4.6's FAIL_ENVIRONMENT, generalised)
#
# The original use of this pattern only covered rcmdcheck() throwing an R
# error. Found 2026-09-20 (via the orthopen validation run): a check can also
# COMPLETE successfully while one of its own findings is actually a network
# failure disguised as content -- e.g. "checking CRAN incoming feasibility"
# hitting the now-permanently-blocked cran.r-project.org (invariant 8 blocks
# it for every run, so this recurs on every check from now on) produces a
# NOTE/ERROR that happened to content-match the `description_meta` category
# by coincidence (it mentions "the DESCRIPTION file" in passing). Once that
# lands in baseline_categories.json, the WHOLE category gets subtracted from
# every arm -- silently absorbing any real, different DESCRIPTION/License/
# Maintainer defect an arm introduces, because category-level subtraction
# can't tell "recurring network glitch" from "new genuine finding" apart.
#
# Fix: strip messages matching this BEFORE classification, so they never
# reach `categories` / baseline_categories.json / residual_burden at all.
# Reported separately instead, per section 4.6 ("FAIL_ENVIRONMENT ... no --
# reported separately").
# ---------------------------------------------------------------------------
env_signals <- paste(
  "pdflatex", "texi2dvi", "pandoc", "qpdf", "ghostscript",
  "there is no package", "unable to install", "cannot open URL",
  "Could not resolve host", "unable to access index for repository",
  "Could not connect to server", "Timeout was reached",
  "need Internet access",
  # "checking for future file timestamps ... NOTE / unable to verify current
  # time" -- rcmdcheck's own network time-verification call, unrelated to
  # package content. Confirmed flaky, not content-driven: the baseline check
  # got a clean "OK" on this exact line, and the block-1 pilot (2026-09-25,
  # post-fix rerun) got the NOTE on 4/6 arms (then 6/6 on a later rerun)
  # depending on live network conditions at check time, uncorrelated with
  # which arm or skill ran. strip_env_lines works per-line, so BOTH lines
  # need a pattern here: matching only "unable to verify current time"
  # stripped that line but left "checking for future file timestamps ...
  # NOTE" behind as a bogus surviving "other"-category finding (confirmed by
  # re-running the parser after the first, incomplete version of this fix).
  # Without both, this silently inflates residual_burden with a
  # network-flake coin flip, whichever arm happens to run when the time
  # service is unreachable.
  "unable to verify current time", "checking for future file timestamps",
  sep = "|"
)
is_env_signal <- function(msg) grepl(env_signals, msg, ignore.case = TRUE, perl = TRUE)

# Generic footer pointers that follow many unrelated errors -- not findings on
# their own (this is what made "checking package dependencies" ERRORs land in
# `description_meta` by accident: the footer mentions "the DESCRIPTION file").
# Applied per-line (marker lines) and as a dotall pattern on the joined text
# (the "See section ... manual." pointer routinely line-wraps, so a per-line
# anchor alone misses it and lets the footer leak through as a fake finding).
boilerplate_line <- "^\\s*(NOTE|ERROR|WARNING)\\s*$"
boilerplate_span  <- "(?is)See section '.*?' in the '.*?'\\s*manual\\.?"

# ---------------------------------------------------------------------------
# Line-level environment-noise stripping
#
# rcmdcheck bundles several sub-findings into ONE message per check step --
# "checking CRAN incoming feasibility" carries the network probe AND Maintainer
# format AND "Description field should not start with the package name" AND
# Date-field freshness, all in one string. Stripping the WHOLE message on any
# network signal (the first version of this fix) threw out real, in-scope
# findings along with the noise -- including exactly the kind of thing this
# study mutates for (MUT-C01, MUT-C03). Strip only the network-caused LINES,
# keep the rest as a real finding.
#
# "Package required but not available: 'X'" is ambiguous on its own: it is
# network-caused when the index couldn't be reached to check, but genuinely
# content (a typo'd/nonexistent dependency) when it isn't. Only strip it when
# a network-failure line co-occurs in the SAME message -- otherwise it is a
# real, skill-relevant finding and must not be discarded.
# ---------------------------------------------------------------------------
strip_env_lines <- function(msg) {
  lines <- strsplit(msg, "\n")[[1]]
  network_poisoned <- any(vapply(lines, is_env_signal, logical(1)))
  keep <- vapply(lines, function(ln) {
    if (is_env_signal(ln)) return(FALSE)
    if (network_poisoned &&
        grepl("required but not available", ln, ignore.case = TRUE, perl = TRUE)) return(FALSE)
    if (grepl(boilerplate_line, ln, ignore.case = TRUE, perl = TRUE)) return(FALSE)
    TRUE
  }, logical(1))
  out <- paste(lines[keep], collapse = "\n")
  out <- gsub(boilerplate_span, "", out, perl = TRUE)
  trimws(out)
}

# ---------------------------------------------------------------------------
# Normalisation
#
# Raw check messages embed paths, filenames, sizes, timings and package
# versions. Comparing raw strings would count the same finding as different
# across arms. Hash on the CATEGORY, not the message.
#
# Extend `categories` as you encounter finding types — but only while working
# on the baseline and the deliberately-broken tree, never after seeing arms.
# ---------------------------------------------------------------------------

categories <- list(
  missing_value_tag      = "\\\\value.*missing|Missing .*\\\\value",
  undocumented_args      = "Undocumented arguments|Documented arguments not in",
  example_error          = "Running examples.*ERROR|checking examples \\.\\.\\. ERROR",
  example_timing         = "Examples with CPU .* time",
  vignette_error         = "checking .*vignettes .*ERROR|Errors in running",
  test_failure           = "checking tests \\.\\.\\. ERROR",
  nonstandard_files      = "Non-standard file|hidden files and directories",
  description_meta       = "DESCRIPTION|Authors@R|Maintainer|License",
  title_case             = "Title field|should be in title case",
  desc_field_length      = "Description field|should not start with",
  spelling               = "Possibly misspelled|spell",
  url_invalid            = "URL|DOI|moved permanently|Not Found",
  package_size           = "installed size|sub-directories of 1Mb",
  global_variables       = "no visible binding|no visible global function",
  imports_unused         = "All declared Imports should be used|Namespace in Imports",
  s3_registration        = "S3 methods? shown|not registered",
  compiled_code          = "checking compiled code|Found .*symbols",
  top_level_console      = "Found the following .*calls to|cat\\(|print\\(",
  cran_incoming          = "checking CRAN incoming feasibility",
  other                  = "."          # catch-all — MUST stay last
)

classify <- function(msg) {
  for (nm in names(categories)) {
    if (grepl(categories[[nm]], msg, ignore.case = TRUE, perl = TRUE)) return(nm)
  }
  "other"
}

# `other` accumulating a lot means the category list is incomplete. Fix it
# against the baseline, not against arm output.

# ---------------------------------------------------------------------------
# 1. R CMD check --as-cran
# ---------------------------------------------------------------------------
res <- tryCatch(
  rcmdcheck(pkg_dir, args = "--as-cran", error_on = "never", quiet = TRUE),
  error = function(e) e
)

if (inherits(res, "error")) {
  # Section 4.6: the package/environment split decides whether this scores.
  # FAIL_ENVIRONMENT means the gate leaked and the run is VOID, not a bad arm.
  outcome <- if (is_env_signal(conditionMessage(res))) "FAIL_ENVIRONMENT" else "FAIL_PACKAGE"
  write_json(list(check_outcome = outcome, message = conditionMessage(res)),
             file.path(out_dir, "findings.json"), auto_unbox = TRUE, pretty = TRUE)
  cat(outcome, "\n"); quit(status = 0)
}

raw <- c(
  lapply(res$errors,   function(m) list(sev = "ERROR",   msg = m)),
  lapply(res$warnings, function(m) list(sev = "WARNING", msg = m)),
  lapply(res$notes,    function(m) list(sev = "NOTE",    msg = m))
)

# Strip network-caused lines from every message first, then split on what's
# left: nothing substantive left -> pure environment noise; anything left ->
# a real content finding, scored on the CLEANED text (so a boilerplate footer
# mentioning "DESCRIPTION" can no longer misclassify an unrelated network
# failure into `description_meta`, and a genuine co-located finding like
# "Description field should not start with the package name" still scores).
cleaned      <- lapply(raw, function(x) c(x, list(clean = strip_env_lines(x$msg))))
env_raw      <- Filter(function(x) !nzchar(x$clean), cleaned)
content_raw  <- Filter(function(x) nzchar(x$clean),  cleaned)

environment_findings <- lapply(env_raw, function(x) list(
  tool     = "R_CMD_check",
  severity = x$sev,
  raw      = substr(x$msg, 1, 500)   # original, unstripped -- nothing content-bearing survived
))

findings <- lapply(content_raw, function(x) list(
  tool     = "R_CMD_check",
  severity = x$sev,
  category = classify(x$clean),
  raw      = substr(x$clean, 1, 500)   # cleaned -- this is what was actually classified
))

# ---------------------------------------------------------------------------
# 2. Supplementary tools (section 4.1)
# ---------------------------------------------------------------------------
sp <- tryCatch(spelling::spell_check_package(pkg_dir), error = function(e) NULL)
if (!is.null(sp) && nrow(sp) > 0) {
  findings <- c(findings, list(list(tool = "spelling", severity = "NOTE",
                                    category = "spelling",
                                    raw = paste(sp$word, collapse = ", "))))
}

uc <- tryCatch(urlchecker::url_check(pkg_dir), error = function(e) NULL)
if (!is.null(uc) && nrow(uc) > 0) {
  findings <- c(findings, list(list(tool = "urlchecker", severity = "NOTE",
                                    category = "url_invalid",
                                    raw = paste(uc$URL, collapse = ", "))))
}

# rhub multi-platform: adds cross-platform findings to the detectable class
# (section 4.6). Slow — run once per arm's final tree, not every replicate,
# and record which trees it was run on.

# ---------------------------------------------------------------------------
# 3. Baseline subtraction
#
# The accepted version in this pinned container may itself emit NOTEs CRAN
# tolerated. Scoring is RELATIVE to that, never absolute.
# ---------------------------------------------------------------------------
baseline_path <- "baseline/env-check/baseline_categories.json"

cats <- vapply(findings, `[[`, character(1), "category")

if (is_baseline) {
  dir.create(dirname(baseline_path), recursive = TRUE, showWarnings = FALSE)
  write_json(unique(cats), baseline_path, auto_unbox = TRUE, pretty = TRUE)
  cat(sprintf("baseline categories written: %s (%d unique)\n",
              baseline_path, length(unique(cats))))
}

baseline <- if (file.exists(baseline_path)) fromJSON(baseline_path) else character(0)
residual <- findings[!(cats %in% baseline)]

# ---------------------------------------------------------------------------
# 4. Output
# ---------------------------------------------------------------------------
# content_errors: raw ERRORs minus the ones that were actually network/environment
# noise (see is_env_signal above) -- those must not drive COMPLETE_FINDINGS on
# their own, or every check would show findings forever regardless of the arm.
content_errors <- Filter(function(x) x$sev == "ERROR", content_raw)

write_json(list(
  blind_id              = basename(pkg_dir),
  check_outcome         = if (length(content_errors)) "COMPLETE_FINDINGS" else
                          if (length(residual)) "COMPLETE_FINDINGS" else "COMPLETE_CLEAN",
  n_errors              = length(res$errors),    # raw rcmdcheck counts, for transparency
  n_warnings            = length(res$warnings),
  n_notes               = length(res$notes),
  n_environment_findings = length(environment_findings),  # excluded from every count below
  residual_burden       = length(residual),   # CO-PRIMARY 1 (section 7)
  residual_categories   = unique(vapply(residual, `[[`, character(1), "category")),
  all_findings          = findings,
  environment_findings  = environment_findings   # not scored -- see comment above is_env_signal
), file.path(out_dir, "findings.json"), auto_unbox = TRUE, pretty = TRUE)

cat(sprintf("%s: residual burden = %d\n", basename(pkg_dir), length(residual)))
