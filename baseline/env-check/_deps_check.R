d <- desc::desc_get_deps('baseline/pkg')
p <- setdiff(unique(d$package), c('R', rownames(installed.packages())))
if (length(p)) install.packages(p)
p2 <- setdiff(unique(d$package), c('R', rownames(installed.packages())))
if (length(p2)) { cat('MISSING:', paste(p2, collapse=', '), '\n'); quit(status=1) }
