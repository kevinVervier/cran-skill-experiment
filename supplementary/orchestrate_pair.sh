#!/usr/bin/env bash
# ============================================================================
# SUPPLEMENTARY paired run: fresh A0 control + delivered-A4, interleaved.
# POST-HOC, labels known, newer CLI than the main experiment -- see README.md.
#
#   ./supplementary/orchestrate_pair.sh 11 12 13 ...    # blocks 11-20 suggested
#
# Same scheduling logic as ../orchestrate.sh (which is untouched), but ARMS is
# (A0 A4) so each block is one contemporaneous control/treatment pair, and the
# manipulation check runs before and after every run.
# ============================================================================
set -uo pipefail
EXP_ROOT="${EXP_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
RUNS_ROOT="${RUNS_ROOT:?set RUNS_ROOT}"
export EXP_ROOT RUNS_ROOT
ARMS=(A0 A4)
export MAX_TURNS=120 WALL_CLOCK_CAP=7200
export IMAGE_DIGEST="REPLACE_WITH_DIGEST" PPM_SNAPSHOT_DATE="REPLACE_YYYY-MM-DD"
CHECK="${EXP_ROOT}/supplementary/check_arm_loaded.sh"

for b in "$@"; do [ "$b" -ge 11 ] || { echo "FATAL: blocks 1-10 are the main experiment; use >= 11"; exit 1; }; done
"${CHECK}" pre "${ARMS[@]}" || { echo "FATAL: A4 not delivered; refusing to start"; exit 1; }

for BLOCK in "$@"; do
  echo "=== SUPPLEMENTARY BLOCK ${BLOCK} ==="
  ORDER=$(printf '%s\n' "${ARMS[@]}" | shuf --random-source=<(yes "supp-${BLOCK}"))
  for ARM in ${ORDER}; do
    RUN_DIR="${RUNS_ROOT}/runs/${ARM}_r${BLOCK}_b${BLOCK}"
    if [ -d "${RUN_DIR}" ]; then
      [ -f "${RUN_DIR}/.complete" ] && { echo "skip ${ARM} block ${BLOCK} -- already run"; continue; }
      echo "discarding interrupted ${ARM} block ${BLOCK}"; rm -rf "${RUN_DIR}"   # invariant 2: never reuse a tree
    fi
    echo "--- ${ARM} (block ${BLOCK}) ---"
    "${EXP_ROOT}/run_arm.sh" "${ARM}" "${BLOCK}" "${BLOCK}"
    "${CHECK}" post "${RUN_DIR}" || echo "!! manipulation check FAILED for ${ARM} block ${BLOCK}: do not count this run"
  done
done
