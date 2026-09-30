#!/usr/bin/env Rscript
# Renders scoring/JUDGE_PROMPT.txt from scoring/judge_criteria.json.
# Re-run only if judge_criteria.json changes -- the prompt must stay frozen
# once calibration starts, exactly like FROZEN_PROMPT.txt for the arms.
suppressPackageStartupMessages(library(jsonlite))

crit <- fromJSON("scoring/judge_criteria.json", simplifyDataFrame = TRUE)$criteria

rows <- sprintf("%s. [%s] %s", crit$id, crit$prov, crit$text)

prompt <- paste0(
"You are reviewing an R package source tree for compliance with a fixed list of CRAN ",
"submission criteria. The current working directory is the package root. Use Read, Grep ",
"and Glob to inspect its files as needed.\n\n",
"For EACH criterion below, decide: COMPLIANT, NON_COMPLIANT, or NOT_APPLICABLE (the ",
"criterion does not apply to this package -- e.g. it has no examples to evaluate). If you ",
"cannot determine an answer from the tree, use UNCLEAR rather than guessing.\n\n",
"Criteria:\n", paste(rows, collapse = "\n"), "\n\n",
"For every criterion, you MUST provide evidence: either a file path and line number, or the ",
"exact text at issue quoted from the tree. A verdict with no evidence is invalid.\n\n",
"Respond with ONLY a JSON array, one object per criterion, in this exact shape and no other ",
"text before or after it:\n",
'[{"id": "C04", "verdict": "COMPLIANT", "evidence": "DESCRIPTION lines 8-14, three-sentence paragraph"}, ...]\n'
)

writeLines(prompt, "scoring/JUDGE_PROMPT.txt")
cat("wrote scoring/JUDGE_PROMPT.txt (", nchar(prompt), "chars)\n")
