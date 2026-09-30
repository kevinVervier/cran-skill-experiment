#' Quick Summary of an orthoMTL Fit
#'
#' @param object A fitted \code{"orthoMTL"} object.
#' @export
quick_summary <- function(object) {
  sum(object$B)
}
