#!/usr/bin/env Rscript
# ============================================================================
# Seed audit -- seed-and-pilot.md section 3, "Seed audit -- establishing the
# before-state".
#
#   Rscript scoring/audit_seed.R <seed_pkg_dir> <blinded_dir> [<blinded_dir> ...]
#
# Classifies every criterion relative to the SEED (the common tree every arm
# was copied from), not the accepted-CRAN baseline that extract_findings.R
# subtracts against:
#
#   seed violates  -> output fixed      REPAIR       (credit)
#   seed violates  -> output violates   unrepaired   (burden)
#   seed satisfies -> output violates   broke_or_new (burden -- see caveat)
#   seed satisfies -> output satisfies  held         (--)
#
# CAVEAT -- read before trusting the numbers: the pre-registration's full
# table splits "seed satisfies -> output violates" into REGRESSION (arm broke
# existing content) and NOVEL (arm's own new content is the violation). That
# split needs per-instance identity -- e.g. knowing whether the specific
# undocumented function already existed in the seed -- which category-level
# classification cannot recover. This script classifies at the CATEGORY
# level (the same granularity extract_findings.R already uses for baseline
# subtraction), so REGRESSION and NOVEL are reported together as
# `broke_or_new`. Splitting them properly is future work, not done here.
#
# The rcmdcheck categories/classify/env-stripping block below is a
# DELIBERATE VERBATIM COPY of extract_findings.R's own logic -- not a shared
# refactor -- specifically so that building or running this script can never
# change extract_findings.R's behaviour or invalidate the findings.json
# results it already produced for all 30 blinded trees. Keep the two blocks
# in sync by hand if either ever needs to change.
#
# MISSING NAMESPACE (discovered 2026-09-27): the seed itself has no
# NAMESPACE file, so rcmdcheck cannot even get past install to produce
# categorised findings for it (or for any output tree that also never added
# one -- see RUN-e1dfb2 / RUN-e4e2fd). missing_namespace is therefore
# checked structurally (file existence) as its own first-class criterion,
# ahead of and independent from the rcmdcheck-derived categories below. For
# the finer-grained category comparison ONLY, the seed is first documented
# via roxygen2::roxygenise() on a throwaway copy (never touching
# arms/A0/pkg) -- the same trivial step 28/30 arms themselves took -- so
# rcmdcheck has something to check at all. That synthesised state is
# reported as `seed_documented`, explicitly distinct from the literal seed,
# so it is never confused with an actual arm result.
# ============================================================================

suppressPackageStartupMessages({
  library(rcmdcheck); library(jsonlite); library(desc)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) stop("usage: audit_seed.R <seed_pkg_dir> <blinded_dir> [<blinded_dir> ...]")
seed_dir    <- args[1]
output_dirs <- args[-1]

source("scoring/static_rules/R01_seed_in_function.R")
source("scoring/static_rules/R02_license_template.R")

# ---------------------------------------------------------------------------
# Verbatim copy from extract_findings.R -- see header caveat above.
# ---------------------------------------------------------------------------
env_signals <- paste(
  "pdflatex", "texi2dvi", "pandoc", "qpdf", "ghostscript",
  "there is no package", "unable to install", "cannot open URL",
  "Could not resolve host", "unable to access index for repository",
  "Could not connect to server", "Timeout was reached",
  "need Internet access",
  "unable to verify current time", "checking for future file timestamps",
  sep = "|"
)
is_env_signal <- function(msg) grepl(env_signals, msg, ignore.case = TRUE, perl = TRUE)

boilerplate_line <- "^\\s*(NOTE|ERROR|WARNING)\\s*$"
boilerplate_span  <- "(?is)See section '.*?' in the '.*?'\\s*manual\\.?"

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
  spelling                = "Possibly misspelled|spell",
  url_invalid             = "URL|DOI|moved permanently|Not Found",
  package_size            = "installed size|sub-directories of 1Mb",
  global_variables        = "no visible binding|no visible global function",
  imports_unused           = "All declared Imports should be used|Namespace in Imports",
  s3_registration           = "S3 methods? shown|not registered",
  compiled_code             = "checking compiled code|Found .*symbols",
  top_level_console         = "Found the following .*calls to|cat\\(|print\\(",
  cran_incoming              = "checking CRAN incoming feasibility",
  other                       = "."
)

classify <- function(msg) {
  for (nm in names(categories)) {
    if (grepl(categories[[nm]], msg, ignore.case = TRUE, perl = TRUE)) return(nm)
  }
  "other"
}

# ---------------------------------------------------------------------------
# Structural criteria checked directly, no rcmdcheck needed.
# ---------------------------------------------------------------------------
check_missing_namespace <- function(pkg_dir) !file.exists(file.path(pkg_dir, "NAMESPACE"))

r01_hits <- function(pkg_dir) tryCatch(flag_seed_in_function(pkg_dir), error = function(e) list())
r02_hit  <- function(pkg_dir) tryCatch(flag_license_template(pkg_dir), error = function(e) list())

# ---------------------------------------------------------------------------
# rcmdcheck-derived categories for one tree. Returns NULL (not an empty list)
# when the check couldn't run at all (e.g. no NAMESPACE), so callers can
# distinguish "checked, found nothing" from "never got to check".
# ---------------------------------------------------------------------------
get_check_findings <- function(pkg_dir) {
  res <- tryCatch(
    rcmdcheck(pkg_dir, args = "--as-cran", error_on = "never", quiet = TRUE),
    error = function(e) e
  )
  if (inherits(res, "error")) return(NULL)

  raw <- c(
    lapply(res$errors,   function(m) list(sev = "ERROR",   msg = m)),
    lapply(res$warnings, function(m) list(sev = "WARNING", msg = m)),
    lapply(res$notes,    function(m) list(sev = "NOTE",    msg = m))
  )
  cleaned     <- lapply(raw, function(x) c(x, list(clean = strip_env_lines(x$msg))))
  content_raw <- Filter(function(x) nzchar(x$clean), cleaned)
  findings <- lapply(content_raw, function(x) list(
    tool = "R_CMD_check", severity = x$sev,
    category = classify(x$clean), raw = substr(x$clean, 1, 500)
  ))

  # Supplementary tools -- verbatim mirror of extract_findings.R section 2, so
  # a tree profiled fresh here (currently only the seed_documented copy) is
  # checked on the SAME criteria as every output tree's cached findings.json,
  # which already includes these from extract_findings.R's own run. Without
  # this, the seed would look artificially clean on spelling/URLs relative to
  # every output tree -- not because arms introduced anything, but because
  # the seed was simply never tested on those two tools.
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
  findings
}

# ---------------------------------------------------------------------------
# Full criterion profile for a tree: structural + R01/R02 + rcmdcheck
# categories (NULL categories if the check never ran).
# ---------------------------------------------------------------------------
profile_tree <- function(pkg_dir, cached_findings = NULL) {
  missing_ns <- check_missing_namespace(pkg_dir)
  r01        <- r01_hits(pkg_dir)
  r02        <- r02_hit(pkg_dir)

  findings <- if (!is.null(cached_findings)) cached_findings else get_check_findings(pkg_dir)

  cats <- character(0)
  if (missing_ns)            cats <- c(cats, "missing_namespace")
  if (length(r01) > 0)       cats <- c(cats, "seed_in_function")
  if (length(r02) > 0)       cats <- c(cats, "license_template")
  if (!is.null(findings))    cats <- c(cats, vapply(findings, `[[`, character(1), "category"))

  list(
    checked           = !is.null(findings) || missing_ns,
    check_ran         = !is.null(findings),
    missing_namespace = missing_ns,
    r01_hits          = r01,
    r02_hit           = r02,
    findings          = findings,
    categories        = unique(cats),
    n_instances_by_category = if (length(cats)) table(cats) else table(character(0))
  )
}

# ---------------------------------------------------------------------------
# 1. Seed profile -- structural criteria on the literal seed, rcmdcheck
#    categories on a throwaway roxygenised copy (see header caveat).
# ---------------------------------------------------------------------------
cat("=== profiling seed:", seed_dir, "===\n")
seed_structural <- list(
  missing_namespace = check_missing_namespace(seed_dir),
  r01_hits          = r01_hits(seed_dir),
  r02_hit           = r02_hit(seed_dir)
)

seed_tmp <- file.path(tempdir(), paste0("seed_documented_", as.integer(Sys.time())))
dir.create(seed_tmp)
file.copy(list.files(seed_dir, full.names = TRUE), seed_tmp, recursive = TRUE)
doc_ok <- TRUE
if (!file.exists(file.path(seed_tmp, "NAMESPACE"))) {
  doc_ok <- tryCatch({
    suppressPackageStartupMessages(library(roxygen2))
    roxygenise(seed_tmp)
    TRUE
  }, error = function(e) { cat("roxygenise() on seed copy failed:", conditionMessage(e), "\n"); FALSE })
}
seed_documented_findings <- if (doc_ok) get_check_findings(seed_tmp) else NULL

seed_cats <- character(0)
if (seed_structural$missing_namespace) seed_cats <- c(seed_cats, "missing_namespace")
if (length(seed_structural$r01_hits) > 0) seed_cats <- c(seed_cats, "seed_in_function")
if (length(seed_structural$r02_hit) > 0)  seed_cats <- c(seed_cats, "license_template")
if (!is.null(seed_documented_findings)) {
  seed_cats <- c(seed_cats, vapply(seed_documented_findings, `[[`, character(1), "category"))
}
seed_cats <- unique(seed_cats)
cat("seed violates:", if (length(seed_cats)) paste(seed_cats, collapse = ", ") else "(nothing detectable)", "\n\n")

seed_out <- list(
  seed_dir                 = seed_dir,
  missing_namespace        = seed_structural$missing_namespace,
  r01_hits                 = seed_structural$r01_hits,
  r02_hit                  = seed_structural$r02_hit,
  seed_documented_check_ran = !is.null(seed_documented_findings),
  seed_documented_findings  = seed_documented_findings,
  violated_categories       = seed_cats
)
dir.create("scoring/results/_seed", recursive = TRUE, showWarnings = FALSE)
write_json(seed_out, "scoring/results/_seed/seed_audit.json", auto_unbox = TRUE, pretty = TRUE)

# ---------------------------------------------------------------------------
# 2. Per-output-tree classification against the seed.
# ---------------------------------------------------------------------------
summary_rows <- list()

for (out_dir in output_dirs) {
  id <- basename(out_dir)
  cat("=== auditing", id, "===\n")

  cached_path <- file.path("scoring/results", id, "findings.json")
  cached_json <- if (file.exists(cached_path)) fromJSON(cached_path, simplifyVector = FALSE) else NULL
  cached_outcome <- if (!is.null(cached_json)) cached_json$check_outcome else NA

  cached_findings <- NULL
  if (!is.null(cached_json) && !is.null(cached_json$all_findings) &&
      cached_outcome %in% c("COMPLETE_CLEAN", "COMPLETE_FINDINGS")) {
    cached_findings <- lapply(cached_json$all_findings, function(x) list(
      tool = x$tool, severity = x$severity, category = x$category, raw = x$raw
    ))
  }

  prof <- profile_tree(out_dir, cached_findings = cached_findings)

  universe <- union(seed_cats, prof$categories)
  repaired     <- setdiff(seed_cats, prof$categories)
  unrepaired   <- intersect(seed_cats, prof$categories)
  broke_or_new <- setdiff(prof$categories, seed_cats)
  held_clean   <- character(0)  # categories never violated by either side are not enumerable generically

  n_burden <- if (prof$check_ran || prof$missing_namespace) {
    sum(prof$n_instances_by_category[names(prof$n_instances_by_category) %in% c(unrepaired, broke_or_new)])
  } else NA_integer_

  row <- list(
    blind_id            = id,
    check_ran            = prof$check_ran,
    missing_namespace    = prof$missing_namespace,
    check_outcome_cached = cached_outcome,
    repaired_categories   = repaired,
    unrepaired_categories = unrepaired,
    broke_or_new_categories = broke_or_new,
    residual_burden_seed_relative = n_burden
  )
  write_json(row, file.path("scoring/results", id, "seed_audit.json"), auto_unbox = TRUE, pretty = TRUE)
  summary_rows[[id]] <- row

  cat(sprintf("  repaired=%d unrepaired=%d broke_or_new=%d burden=%s\n",
              length(repaired), length(unrepaired), length(broke_or_new),
              if (is.na(n_burden)) "NA" else n_burden))
}

write_json(summary_rows, "scoring/results/_seed_audit_summary.json", auto_unbox = TRUE, pretty = TRUE)
cat("\nwrote scoring/results/_seed_audit_summary.json (", length(summary_rows), "trees )\n")
