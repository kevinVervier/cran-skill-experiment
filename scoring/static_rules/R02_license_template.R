# Static rule R02 -- License field names a GPL variant with "+ file LICENSE"
# but the LICENSE file is a bare usethis::use_mit_license()-style template
# (YEAR / COPYRIGHT HOLDER only, no substantive additional restriction).
# See rejection-ledger.md for the finding this catches.
flag_license_template <- function(pkg_dir) {
  lic <- tryCatch(desc::desc_get_field("License", file = pkg_dir), error = function(e) NA)
  if (is.na(lic) || !grepl("\\+ *file LICENSE", lic)) return(list())
  if (!grepl("^GPL|^AGPL|^LGPL", lic)) return(list())
  lf <- file.path(pkg_dir, "LICENSE")
  if (!file.exists(lf)) return(list())
  txt <- readLines(lf, warn = FALSE)
  body <- trimws(txt[nzchar(trimws(txt))])
  looks_template <- all(grepl("^(YEAR|COPYRIGHT HOLDER)\\s*:", body, ignore.case = TRUE))
  if (looks_template) list(list(license = lic, lines = body)) else list()
}
