#!/usr/bin/env bash
# ============================================================================
# Calibration run -- §5.1.2. Judge blind over the 10 mutants + unmutated
# control, randomised order, 3 replicates each (§5.1.1 mitigation 4).
#
#   EXP_ROOT=... scoring/run_calibration.sh
#
# Output: calibration/judge_results/<label>/rep<N>.json (+ .err/.provenance)
# for label in {control, MUT-R01, MUT-R02, MUT-L30, MUT-L31, MUT-L29,
# MUT-L23, MUT-C01, MUT-C03, MUT-L28, MUT-C16}.
# ============================================================================
set -uo pipefail

EXP_ROOT="${EXP_ROOT:?set EXP_ROOT}"
cd "${EXP_ROOT}"

# A file existing is not enough to call a job done -- a harness failure (rate
# limit, a killed process leaving a 0-byte file) writes to the same path as a
# real verdict. Same guard added to run_judge_panel.sh after 41/60 of its
# outputs turned out to be session-limit stubs marked "already judged"
# (2026-09-30). Treat anything that isn't a parseable, non-error JSON object
# as not done.
is_valid_judge_output() {
  local f="$1"
  [ -s "${f}" ] || return 1
  python3 -c "
import json, sys
try:
    d = json.load(open(sys.argv[1]))
except Exception:
    sys.exit(1)
sys.exit(1 if d.get('is_error') else 0)
" "${f}"
}

# The first 10 mutants are the ledger's general oracle-validation candidates
# (mostly ORACLE=STATIC, not judge-relevant -- see build_calibration_set.R's
# "EXTENSION" comment). The 11 after MUT-C16 are judge-targeted: one per
# remaining ORACLE=JUDGE criterion in judge_criteria.json (MUT-L23 above
# already covers L23 and, by overlap, C18).
LABELS=(control MUT-R01 MUT-R02 MUT-L30 MUT-L31 MUT-L29 MUT-L23 MUT-C01 MUT-C03 MUT-L28 MUT-C16 \
        MUT-C04 MUT-C08 MUT-C13 MUT-L06 MUT-L08 MUT-L09 MUT-L10 MUT-L12 MUT-L21 MUT-L27)
REPS=3

# Build the (label, rep) job list, then shuffle it -- randomised order across
# BOTH trees and replicates, not just tree order with reps done back-to-back.
JOBS=()
for label in "${LABELS[@]}"; do
  for r in $(seq 1 "${REPS}"); do
    JOBS+=("${label}:${r}")
  done
done
# Array-based, not `while read <<< heredoc`: the child `claude` process
# inherits this shell's stdin, and a heredoc-fed while-loop shares that same
# fd with `read` -- if the child so much as probes stdin, the loop's `read`
# can hit EOF after one iteration while still exiting 0. Confirmed live: a
# first attempt at this script reported "calibration run complete: 33 judge
# calls" having actually run exactly 1. An array + `for` never touches
# stdin, so there is no fd to share.
mapfile -t JOBS_SHUFFLED < <(printf '%s\n' "${JOBS[@]}" | shuf --random-source=<(yes calibration-seed))

TOTAL=${#JOBS_SHUFFLED[@]}
i=0
DONE=0
for job in "${JOBS_SHUFFLED[@]}"; do
  i=$((i+1))
  label="${job%%:*}"
  rep="${job##*:}"
  if [ "${label}" = "control" ]; then
    pkg_dir="${EXP_ROOT}/calibration/control/pkg"
  else
    pkg_dir="${EXP_ROOT}/calibration/mutants/${label}/pkg"
  fi
  out="${EXP_ROOT}/calibration/judge_results/${label}/rep${rep}.json"
  if is_valid_judge_output "${out}"; then
    echo "[${i}/${TOTAL}] skip ${label} rep${rep} — already judged"
    DONE=$((DONE+1))
    continue
  fi
  echo "[${i}/${TOTAL}] judging ${label} rep${rep}"
  bash "${EXP_ROOT}/scoring/run_judge.sh" "${pkg_dir}" "${out}"
  is_valid_judge_output "${out}" && DONE=$((DONE+1))
done

echo "calibration run: ${DONE}/${TOTAL} judge calls produced output"
[ "${DONE}" -eq "${TOTAL}" ] || { echo "INCOMPLETE -- rerun this script, it skips what already succeeded"; exit 1; }
