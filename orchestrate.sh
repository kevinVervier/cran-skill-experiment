#!/usr/bin/env bash
# ============================================================================
# Block-randomised scheduling — pre-registration section 6.2
#
#   ./orchestrate.sh 1        # pilot block
#   ./orchestrate.sh 2 3 4 5  # measurement blocks
#
# One block = every arm run once, in randomised order.
#
# WHY NOT ARM-BY-ARM: over a three-week window the model version, CLI version,
# or infrastructure may change. Running all of A0, then all of A1, would
# confound any such drift perfectly with arm identity. Interleaving spreads it
# across arms so drift becomes noise rather than a systematic effect.
# ============================================================================
set -uo pipefail

EXP_ROOT="${EXP_ROOT:-$(pwd)}"
RUNS_ROOT="${RUNS_ROOT:?set RUNS_ROOT to the arm-runs directory (see CLAUDE.md for the resolved path)}"
export EXP_ROOT RUNS_ROOT

ARMS=(A0 A1 A2 A3 A4 A5)       # A5 = raw-handbook arm; drop last if budget forces it
export MAX_TURNS=120
export WALL_CLOCK_CAP=7200
export IMAGE_DIGEST="REPLACE_WITH_DIGEST"
export PPM_SNAPSHOT_DATE="REPLACE_YYYY-MM-DD"

[ -f "${EXP_ROOT}/FROZEN_PROMPT.txt" ] || { echo "FATAL: FROZEN_PROMPT.txt missing"; exit 1; }
grep -q "DRAFT — NOT YET FROZEN" "${EXP_ROOT}/FROZEN_PROMPT.txt" && \
  { echo "FATAL: prompt still marked DRAFT. Freeze it first."; exit 1; }
[ -f "${EXP_ROOT}/baseline/env-check/baseline_findings.txt" ] || \
  { echo "FATAL: environment gate not passed. Run verify_env.sh"; exit 1; }

for BLOCK in "$@"; do
  echo "=== BLOCK ${BLOCK} ==="

  # Randomise arm order within the block. Seed on the block so the schedule is
  # reproducible and can be published alongside the results.
  ORDER=$(printf '%s\n' "${ARMS[@]}" | shuf --random-source=<(yes "${BLOCK}"))

  REP=${BLOCK}
  for ARM in ${ORDER}; do
    RUN_DIR="${RUNS_ROOT}/runs/${ARM}_r${REP}_b${BLOCK}"
    if [ -d "${RUN_DIR}" ]; then
      if [ -f "${RUN_DIR}/.complete" ]; then
        echo "skip ${ARM} block ${BLOCK} — already run"
        continue
      fi
      # No keep-awake mechanism is used on this host (see git history / memory
      # for why): Shadow's idle timeout can kill a session mid-run. A RUN_DIR
      # without .complete means a prior attempt was interrupted, not finished
      # -- discard it and start over. Never resume a partial agent transcript
      # in place; that would reuse an output tree (invariant 2).
      echo "resuming ${ARM} block ${BLOCK} — prior attempt was interrupted, discarding and rerunning"
      rm -rf "${RUN_DIR}"
    fi
    echo "--- ${ARM}  (block ${BLOCK}) ---"
    "${EXP_ROOT}/run_arm.sh" "${ARM}" "${REP}" "${BLOCK}"
  done

  echo "block ${BLOCK} complete: $(date -u +%FT%TZ)"

  # PILOT STOP. Block 1 is a harness test, not a measurement. If anything
  # changed as a result of it — prompt, budget, strip list, parser, container —
  # block 1 is discarded, not pooled. Pre-committed in section 6.1.
  if [ "${BLOCK}" -eq 1 ]; then
    echo
    echo "PILOT COMPLETE. Review before continuing:"
    echo "  - did every arm terminate DECLARED_DONE, or did some exhaust budget?"
    echo "  - did the finding parser run end to end on all trees?"
    echo "  - any FAIL_ENVIRONMENT check outcomes? (gate leaked -> void the block)"
    echo "  - config-snapshot-preflight: did A0 load anything it shouldn't have?"
    echo
    echo "If you change ANYTHING, delete ${RUNS_ROOT}/runs and ${RUNS_ROOT}/blinded before block 2."
    exit 0
  fi
done
