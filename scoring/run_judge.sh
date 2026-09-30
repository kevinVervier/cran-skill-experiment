#!/usr/bin/env bash
# ============================================================================
# Single judge call -- one package tree, one replicate.
# skill-experiment-preregistration.md §5.1.1 mitigations.
#
#   scoring/run_judge.sh <pkg_dir> <out_json_path>
#
# Mitigations applied here (§5.1.1):
#   1. Different model from the arms -- pinned below, distinct from whatever
#      model the arms ran on (recorded per-run in coldstart.json; observed as
#      claude-opus-5-5 across the sampled blocks). Judge uses claude-sonnet-5.
#   2. Judge sees the package and the criteria only -- fresh CLAUDE_CONFIG_DIR
#      (no memory, no CLAUDE.md, no skill file), read-only tool surface
#      (Read/Grep/Glob -- no Edit/Write/Bash), and pkg_dir is always a
#      blinded/<ID> or calibration/ path, never a runs/<RUN_ID> path that
#      would leak arm identity into the cwd or file listing.
#   5. Pinned judge model version -- recorded in provenance below.
# Replicates (mitigation 4) and blinded/order-randomised invocation
# (mitigation 3) are the CALLER's responsibility (see run_calibration.sh /
# run_judge_panel.sh), not this single-call script.
# ============================================================================
set -uo pipefail

PKG_DIR="$1"; OUT_JSON="$2"
EXP_ROOT="${EXP_ROOT:?set EXP_ROOT}"
JUDGE_MODEL="${JUDGE_MODEL:-claude-sonnet-5}"
JUDGE_PROMPT_PATH="${EXP_ROOT}/scoring/JUDGE_PROMPT.txt"

[ -f "${JUDGE_PROMPT_PATH}" ] || { echo "FATAL: ${JUDGE_PROMPT_PATH} missing -- run render_judge_prompt.R first"; exit 1; }
[ -d "${PKG_DIR}" ] || { echo "FATAL: ${PKG_DIR} does not exist"; exit 1; }

JUDGE_CONFIG_DIR=$(mktemp -d)
mkdir -p "${JUDGE_CONFIG_DIR}"
if [ -f "${HOME}/.claude/.credentials.json" ]; then
  cp "${HOME}/.claude/.credentials.json" "${JUDGE_CONFIG_DIR}/.credentials.json"
fi

mkdir -p "$(dirname "${OUT_JSON}")"

(
  cd "${PKG_DIR}" && \
  env -u EXP_ROOT -u RUNS_ROOT -u OLDPWD CLAUDE_CONFIG_DIR="${JUDGE_CONFIG_DIR}" CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 \
  claude -p "$(cat "${JUDGE_PROMPT_PATH}")" \
    --model "${JUDGE_MODEL}" \
    --output-format json \
    --tools "Read,Grep,Glob" \
    --allowedTools "Read,Grep,Glob" \
    --strict-mcp-config \
    --dangerously-skip-permissions \
    < /dev/null
) > "${OUT_JSON}" 2> "${OUT_JSON}.err"

rm -rf "${JUDGE_CONFIG_DIR}"

echo "judge_model=${JUDGE_MODEL}" > "${OUT_JSON}.provenance"
echo "pkg_dir=${PKG_DIR}" >> "${OUT_JSON}.provenance"
echo "judged_utc=$(date -u +%FT%TZ)" >> "${OUT_JSON}.provenance"
