# Static rule R01 -- set.seed() with a literal numeric argument inside a
# function body in R/. See rejection-ledger.md for the finding this catches.
# Excludes tests/, vignettes/, inst/, and top-level scripts by construction:
# this only walks files under <pkg_dir>/R.
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
