#!/usr/bin/env bash
# ============================================================================
# ENVIRONMENT GATE — pre-registration section 4.2
#
#   ./verify_env.sh baseline/pkg
#
# Establishes that the accepted CRAN version checks cleanly in this container,
# with the PDF manual and vignettes actually building.
#
# If this fails, NO EXPERIMENTAL RUN MAY START. An under-provisioned container
# makes every arm burn turns on the same toolchain failure, and that noise
# swamps any skill signal you are trying to measure.
# ============================================================================
set -uo pipefail

PKG_DIR="${1:-baseline/pkg}"
OUT_DIR="baseline/env-check"
mkdir -p "${OUT_DIR}"

FAIL=0
ok()   { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; FAIL=1; }

echo "== System dependencies =="
for cmd in pdflatex pandoc qpdf gs R; do
  command -v "$cmd" >/dev/null 2>&1 && ok "$cmd" || fail "$cmd not found"
done
# checkbashisms (Debian devscripts) has no native Windows build and is not part of
# this hard gate: it only matters for a package with configure/cleanup shell scripts,
# and orthoMTL has none. Declared platform gap -- see ENVIRONMENT.md.
if command -v checkbashisms >/dev/null 2>&1; then
  ok "checkbashisms"
else
  echo "  SKIP  checkbashisms not available on this platform (no configure/cleanup scripts to check)"
fi

echo "== Check tooling =="
for p in rcmdcheck urlchecker spelling rhub desc jsonlite; do
  R -q -e "if (!requireNamespace('$p', quietly=TRUE)) quit(status=1)" >/dev/null 2>&1 \
    && ok "$p" || fail "R package $p missing"
done

echo "== Offline documentation snapshot =="
if [ -d "${CRAN_DOCS_PATH:-/opt/cran-docs}" ] && \
   [ -n "$(ls -A "${CRAN_DOCS_PATH:-/opt/cran-docs}" 2>/dev/null)" ]; then
  ok "snapshot present at ${CRAN_DOCS_PATH:-/opt/cran-docs}"
else
  fail "CRAN docs snapshot missing or empty — every arm needs it, including A0"
fi

echo "== Baseline package dependencies =="
# Written to a temp .R file and run with Rscript rather than `R -q -e "<multi-line>"`:
# a multi-line -e argument crashes native Windows R when invoked via Git Bash (MSYS
# argv translation bug, unrelated to R or the package) -- temp-file invocation is
# portable and safe everywhere, not a Windows-only workaround.
DEPS_R="${OUT_DIR}/_deps_check.R"
cat > "${DEPS_R}" <<EOF
d <- desc::desc_get_deps('${PKG_DIR}')
p <- setdiff(unique(d\$package), c('R', rownames(installed.packages())))
if (length(p)) install.packages(p)
p2 <- setdiff(unique(d\$package), c('R', rownames(installed.packages())))
if (length(p2)) { cat('MISSING:', paste(p2, collapse=', '), '\n'); quit(status=1) }
EOF
Rscript "${DEPS_R}" > "${OUT_DIR}/deps.log" 2>&1 && ok "all declared deps installable" \
  || fail "dependency install failed — see ${OUT_DIR}/deps.log"

echo "== Baseline R CMD check --as-cran =="
CHECK_R="${OUT_DIR}/_check.R"
cat > "${CHECK_R}" <<EOF
res <- rcmdcheck::rcmdcheck('${PKG_DIR}',
         args = c('--as-cran'),
         error_on = 'never')
saveRDS(res, '${OUT_DIR}/baseline_check.rds')
cat('ERRORS:',   length(res\$errors),   '\n')
cat('WARNINGS:', length(res\$warnings), '\n')
cat('NOTES:',    length(res\$notes),    '\n')
writeLines(c(res\$errors, res\$warnings, res\$notes), '${OUT_DIR}/baseline_findings.txt')
EOF
Rscript "${CHECK_R}" > "${OUT_DIR}/check.log" 2>&1

if [ -f "${OUT_DIR}/baseline_check.rds" ]; then
  ok "check completed end to end"
  grep -E '^(ERRORS|WARNINGS|NOTES):' "${OUT_DIR}/check.log" | sed 's/^/        /'
else
  fail "check did not complete — see ${OUT_DIR}/check.log"
fi

echo "== Artifacts that prove the toolchain works =="
# A check can "complete" while silently skipping the manual or vignettes. Read this
# straight out of check.log rather than searching for a leftover file on disk:
# rcmdcheck builds in a tempdir and cleans it up by default, so a filesystem search
# after the fact is a race against that cleanup on every platform, not just Windows.
grep -q "checking PDF version of manual ... OK" "${OUT_DIR}/check.log" 2>/dev/null \
  && ok "PDF manual built" \
  || fail "no PDF manual produced — LaTeX likely incomplete (see ${OUT_DIR}/check.log)"

if ls "${PKG_DIR}/vignettes"/*.Rmd >/dev/null 2>&1; then
  R -q -e "tools::buildVignettes(dir='${PKG_DIR}')" > "${OUT_DIR}/vignettes.log" 2>&1 \
    && ok "vignettes build" || fail "vignettes failed — see ${OUT_DIR}/vignettes.log"
else
  echo "  SKIP  no vignettes in baseline"
fi

echo
if [ "${FAIL}" -eq 0 ]; then
  echo "GATE PASSED. Baseline findings recorded in ${OUT_DIR}/baseline_findings.txt"
  echo "These are subtracted from every arm. Commit them before any run."
else
  echo "GATE FAILED. Fix the container. Do not start runs."
  exit 1
fi
