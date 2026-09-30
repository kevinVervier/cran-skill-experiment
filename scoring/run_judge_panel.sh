#!/usr/bin/env bash
# ============================================================================
# Judge panel over the real arm trees -- §5.1, run only after calibration
# (scoring/run_calibration.sh) has passed the §5.1.2 decision rule. That gate
# passed 2026-09-30: 91.67% detection, 8.33% FP rate on control -- USABLE.
#
#   EXP_ROOT=... RUNS_ROOT=... scoring/run_judge_panel.sh
#
# 1 replicate per tree (Kevin, 2026-09-30 -- budget-conscious after the
# calibration run hit a weekly usage-limit window; more replicates can be
# added later the same way run_calibration.sh's decision-rule rerun was: the
# job list is idempotent, so bumping REPS and rerunning only fills gaps).
#
# Output: scoring/results/<BLIND_ID>/judge_rep<N>.json (+.err/.provenance),
# alongside that tree's existing findings.json / seed_audit.json.
# ============================================================================
set -uo pipefail

EXP_ROOT="${EXP_ROOT:?set EXP_ROOT}"
RUNS_ROOT="${RUNS_ROOT:?set RUNS_ROOT}"
REPS="${REPS:-1}"
cd "${EXP_ROOT}"

# A file existing is not enough to call a job done -- a harness failure (rate
# limit, a killed process leaving a 0-byte file) writes to the same path as a
# real verdict. Same class of bug analyze_calibration.py already guards
# against for is_error; this script had no equivalent check, which let 41/60
# session-limit stubs sit marked "already judged" until caught by hand
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

mapfile -t IDS < <(ls "${RUNS_ROOT}/blinded")

JOBS=()
for id in "${IDS[@]}"; do
  for r in $(seq 1 "${REPS}"); do
    JOBS+=("${id}:${r}")
  done
done
mapfile -t JOBS_SHUFFLED < <(printf '%s\n' "${JOBS[@]}" | shuf --random-source=<(yes arm-panel-seed))

TOTAL=${#JOBS_SHUFFLED[@]}
i=0
DONE=0
for job in "${JOBS_SHUFFLED[@]}"; do
  i=$((i+1))
  id="${job%%:*}"
  rep="${job##*:}"
  pkg_dir="${RUNS_ROOT}/blinded/${id}"
  out="${EXP_ROOT}/scoring/results/${id}/judge_rep${rep}.json"
  if is_valid_judge_output "${out}"; then
    echo "[${i}/${TOTAL}] skip ${id} rep${rep} — already judged"
    DONE=$((DONE+1))
    continue
  fi
  echo "[${i}/${TOTAL}] judging ${id} rep${rep}"
  bash "${EXP_ROOT}/scoring/run_judge.sh" "${pkg_dir}" "${out}"
  is_valid_judge_output "${out}" && DONE=$((DONE+1))
done

echo "judge panel run: ${DONE}/${TOTAL} judge calls produced output"
[ "${DONE}" -eq "${TOTAL}" ] || { echo "INCOMPLETE -- rerun this script, it skips what already succeeded"; exit 1; }
