res <- rcmdcheck::rcmdcheck('baseline/pkg',
         args = c('--as-cran'),
         error_on = 'never')
saveRDS(res, 'baseline/env-check/baseline_check.rds')
cat('ERRORS:',   length(res$errors),   '\n')
cat('WARNINGS:', length(res$warnings), '\n')
cat('NOTES:',    length(res$notes),    '\n')
writeLines(c(res$errors, res$warnings, res$notes), 'baseline/env-check/baseline_findings.txt')
