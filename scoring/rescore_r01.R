#!/usr/bin/env Rscript
# Re-score R01 only, using the revised rule (literal + numeric-default forms).
#
#   Rscript scoring/rescore_r01.R <blinded_root> <out_csv>
#
# Written 2026-10-06 after the original R01 rule was found to miss the form the
# CRAN reviewer actually objected to (see the REVISION note in
# static_rules/R01_seed_in_function.R). Reads blinded tree IDs only and writes
# a new file; it never touches scoring/results/*/seed_audit.json.
# Pass Windows-style paths (C:/...): R on this host cannot read /c/... paths.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) stop("usage: rescore_r01.R <blinded_root> <out_csv>")
root <- args[1]; out <- args[2]
source("scoring/static_rules/R01_seed_in_function.R")

ids <- sort(list.dirs(root, recursive = FALSE, full.names = FALSE))
res <- do.call(rbind, lapply(ids, function(b) {
  h <- flag_seed_in_function(file.path(root, b))
  data.frame(blind = b,
             r01_hits = length(h),
             r01_literal = sum(vapply(h, function(x) x$form == "literal", logical(1))),
             r01_default = sum(vapply(h, function(x) x$form == "default", logical(1))),
             r01_files = paste(sort(unique(vapply(h, `[[`, "", "file"))), collapse = ";"),
             seed_numeric_default = length(seed_numeric_defaults(file.path(root, b))),
             stringsAsFactors = FALSE)
}))
write.csv(res, out, row.names = FALSE)
cat(nrow(res), "trees;", sum(res$r01_hits > 0), "with direct R01 hits ->", out, "\n")
