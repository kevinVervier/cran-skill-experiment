# Static rule R01 -- a hardcoded seed inside an exported function in R/.
# See rejection-ledger.md for the finding this catches.
#
# Two forms are flagged:
#   (a) literal   -- set.seed(<number>) inside a function body.
#   (b) default   -- a function formal with a numeric default (e.g. `seed = 42`)
#                    whose value reaches set.seed(), directly or inside an
#                    expression (set.seed(seed), set.seed(seed + i)). This is
#                    the form the CRAN reviewer actually objected to; guarding
#                    the call with `if (!is.null(seed))` does not help, because
#                    a numeric default is never NULL.
#
# REVISION 2026-10-06: form (b) added. The original rule only implemented (a),
# so it returned zero hits on the seed tree, which does carry (b) in four
# exported functions. Original results (scoring/results/*/seed_audit.json) are
# left untouched; re-scored output lives in scoring/results_r01v2/.
#
# Excludes tests/, vignettes/, inst/, and top-level scripts by construction:
# this only walks files under <pkg_dir>/R.
flag_seed_in_function <- function(pkg_dir) {
  files <- list.files(file.path(pkg_dir, "R"), pattern = "[.][Rr]$", full.names = TRUE)
  hits <- list()

  # Names of formals of `fn_call` (a `function` call) that have a numeric default.
  numeric_default_formals <- function(fn_call) {
    fm <- fn_call[[2]]
    if (is.null(fm)) return(character(0))
    nm <- names(fm)
    # Index rather than pass `fm` to vapply(): formals without a default are the
    # empty symbol, and handing that to a FUN argument crashes R.
    nm[vapply(seq_along(fm), function(i) is.numeric(fm[[i]]), logical(1))]
  }

  # All symbols mentioned in an expression.
  symbols <- function(e) all.vars(e)

  for (f in files) {
    exprs <- tryCatch(parse(f, keep.source = TRUE), error = function(e) NULL)
    if (is.null(exprs)) next

    # `hard`: formals with numeric defaults, inherited by nested functions.
    walk <- function(e, in_fn = FALSE, hard = character(0)) {
      if (!is.call(e)) return(invisible())
      if (identical(e[[1]], quote(`function`))) {
        in_fn <- TRUE
        hard <- union(hard, numeric_default_formals(e))
      }
      if (identical(e[[1]], quote(set.seed)) && in_fn && length(e) > 1) {
        arg <- e[[2]]
        if (is.numeric(arg)) {
          hits[[length(hits) + 1]] <<- list(file = basename(f), form = "literal",
                                            call = deparse(e))
        } else if (length(hard) > 0 && any(symbols(arg) %in% hard)) {
          hits[[length(hits) + 1]] <<- list(file = basename(f), form = "default",
                                            call = deparse(e))
        }
      }
      for (i in seq_along(e)) if (i > 1 || !is.name(e[[i]])) {
        tryCatch(walk(e[[i]], in_fn, hard), error = function(err) NULL)
      }
    }
    for (e in exprs) walk(e)
  }
  hits
}

# Companion check (added 2026-10-06): seed-named formals with a numeric default
# anywhere in R/, regardless of how the value reaches the RNG. A tree can avoid
# flag_seed_in_function() hits yet keep `seed = 42` (e.g. by routing it through
# a helper that restores .Random.seed). That is not the canonical fix (`seed =
# NULL`), so it is reported separately and judged by a human, not scored as a
# direct R01 hit.
seed_numeric_defaults <- function(pkg_dir) {
  files <- list.files(file.path(pkg_dir, "R"), pattern = "[.][Rr]$", full.names = TRUE)
  out <- list()
  for (f in files) {
    exprs <- tryCatch(parse(f, keep.source = TRUE), error = function(e) NULL)
    if (is.null(exprs)) next
    walk <- function(e) {
      if (!is.call(e)) return(invisible())
      if (identical(e[[1]], quote(`function`)) && !is.null(e[[2]])) {
        fm <- e[[2]]; nm <- names(fm)
        for (i in seq_along(fm)) {
          if (grepl("seed", nm[i], ignore.case = TRUE) && is.numeric(fm[[i]]))
            out[[length(out) + 1]] <<- list(file = basename(f), formal = nm[i])
        }
      }
      for (i in seq_along(e)) if (i > 1 || !is.name(e[[i]])) {
        tryCatch(walk(e[[i]]), error = function(err) NULL)
      }
    }
    for (e in exprs) walk(e)
  }
  out
}
