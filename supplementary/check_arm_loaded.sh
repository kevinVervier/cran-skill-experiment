#!/usr/bin/env bash
# ============================================================================
# Manipulation check: did the arm's instructions actually reach the model?
#
#   check_arm_loaded.sh pre  <ARM>...        # before running: file present?
#   check_arm_loaded.sh post <RUN_DIR>...    # after running: context bigger than A0's?
#
# Why this exists: arm A4 was run 10 times with NO instruction file. Its
# first-call context was 7,145 tokens in every run, identical to the A0 control.
# Nothing in the harness noticed. This check would have.
#
# Read-only. Never edits the harness, the arms, or any run directory.
# Needs: EXP_ROOT, RUNS_ROOT, jq.
# ============================================================================
set -uo pipefail
RUNS_ROOT="${RUNS_ROOT:?set RUNS_ROOT}"
MIN_DELTA="${MIN_DELTA:-200}"   # tokens an instructed arm must exceed A0 by
MODE="${1:?usage: pre <ARM>... | post <RUN_DIR>...}"; shift
FAIL=0
RATE=0

first_call_tokens() {  # stream.jsonl -> input+cache tokens of the first assistant call
  jq -r 'select(.type=="assistant" and .message.usage != null)
         | .message.usage
         | ((.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))' \
     "$1" 2>/dev/null | head -n1
}

case "${MODE}" in
  pre)
    for ARM in "$@"; do
      [ "${ARM}" = "A0" ] && continue   # control: must have none (run_arm.sh guards that)
      F="${RUNS_ROOT}/arms/${ARM}/pkg/CLAUDE.md"
      if [ ! -s "${F}" ]; then echo "FAIL ${ARM}: no instruction file at ${F}"; FAIL=1; continue; fi
      if ! grep -q 'CLAUDE' "${RUNS_ROOT}/arms/${ARM}/pkg/.Rbuildignore" 2>/dev/null; then
        echo "FAIL ${ARM}: .Rbuildignore does not exclude CLAUDE.md (R CMD check would see it)"; FAIL=1; continue
      fi
      echo "ok   ${ARM}: $(wc -c < "${F}") bytes, excluded from build"
    done ;;
  post)
    REF=$(for d in "${RUNS_ROOT}"/runs/A0_r*; do [ -f "$d/stream.jsonl" ] && first_call_tokens "$d/stream.jsonl"; done \
          | sort -n | awk '{a[NR]=$1} END{if(NR) print a[int((NR+1)/2)]}')
    [ -n "${REF}" ] || { echo "FATAL: no A0 reference runs under ${RUNS_ROOT}/runs"; exit 2; }
    echo "A0 reference first-call context (median): ${REF} tokens"
    for D in "$@"; do
      ARM=$(basename "$D" | cut -c1-2); T=$(first_call_tokens "$D/stream.jsonl")
      # Rate-limited run (429): not a delivery failure, the run is simply lost. Exit 3 tells the orchestrator to stop.
      if [ "$(jq -r '.api_error_status // empty' "$D/result.json" 2>/dev/null)" = "429" ]; then
        echo "RATE-LIMITED $(basename "$D"): API 429 (first-call tokens: ${T:-none}); run lost, not a delivery failure"; RATE=1; continue
      fi
      if [ -z "${T}" ]; then echo "WARN $(basename "$D"): no first-call usage found"; FAIL=1; continue; fi
      if [ "${ARM}" = "A0" ]; then echo "ok   $(basename "$D"): ${T} (control)"; continue; fi
      if [ $(( T - REF )) -lt "${MIN_DELTA}" ]; then
        echo "FAIL $(basename "$D"): ${T} tokens, only $(( T - REF )) above A0 -- instructions NOT delivered"; FAIL=1
      else
        echo "ok   $(basename "$D"): ${T} tokens, +$(( T - REF )) over A0"
      fi
    done ;;
  *) echo "unknown mode ${MODE}"; exit 2 ;;
esac
[ "${FAIL}" -ne 0 ] && exit 1
[ "${RATE}" -ne 0 ] && exit 3
exit 0
