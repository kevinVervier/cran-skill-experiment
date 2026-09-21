#!/usr/bin/env bash
# ============================================================================
# Single experimental run. One arm, one replicate.
#
#   ./run_arm.sh A2 3 1        # arm, replicate index, block index
#
# Produces  runs/<ARM>_r<REP>_b<BLOCK>/  containing everything needed to score
# the run and to prove it was isolated.
# ============================================================================
set -uo pipefail

ARM="$1"; REP="$2"; BLOCK="$3"

# --- Roots -------------------------------------------------------------------
# Two separate trees, deliberately. EXP_ROOT holds the harness and its CLAUDE.md;
# RUNS_ROOT holds the arm trees and must have NO instruction file anywhere between
# it and the filesystem root. See KICKOFF.md.
EXP_ROOT="${EXP_ROOT:?set EXP_ROOT to the cran-skill-experiment directory}"
RUNS_ROOT="${RUNS_ROOT:?set RUNS_ROOT to the cran-exp-runs directory}"

RUN_ID="${ARM}_r${REP}_b${BLOCK}"
RUN_DIR="${RUNS_ROOT}/runs/${RUN_ID}"
mkdir -p "${RUN_DIR}"

# --- Isolation (pre-registration section 6.5) --------------------------------
# Fresh config dir per run: relocates the entire ~/.claude surface — CLAUDE.md,
# skills, rules, settings, hooks, subagents, auto memory — somewhere disposable.
# Without this, a global CLAUDE.md or user-level skill leaks into every arm,
# including the control.
export CLAUDE_CONFIG_DIR="${RUN_DIR}/claude-config"
mkdir -p "${CLAUDE_CONFIG_DIR}"
export CLAUDE_CODE_DISABLE_AUTO_MEMORY=1

# Login state lives on this host as an OAuth credential file under the normal
# ~/.claude surface, not an API key. Relocating CLAUDE_CONFIG_DIR isolates
# memory/skills/CLAUDE.md/settings/hooks as intended, but it also orphans that
# credential file, leaving every run logged out. Carry over only the
# credential file itself -- everything else stays freshly isolated per-run.
if [ -f "${HOME}/.claude/.credentials.json" ]; then
  cp "${HOME}/.claude/.credentials.json" "${CLAUDE_CONFIG_DIR}/.credentials.json"
fi

# Fresh tree from the frozen export. Never reuse a previous run's tree.
rm -rf "${RUN_DIR}/pkg"
cp -r "${RUNS_ROOT}/arms/${ARM}/pkg" "${RUN_DIR}/pkg"

# --- Leakage assertions ------------------------------------------------------
# Fail loudly rather than silently contaminating a run.

# ANCESTRY CHECK — the one that matters most.
# Claude Code walks UP the directory tree collecting every CLAUDE.md it finds.
# An instruction file in ANY parent directory loads into every arm, including
# the control. If the arm tree sits under the experiment folder, the arm
# inherits the experiment's own CLAUDE.md — which names the ledger, the
# criteria and the whole design.
CHECK_DIR="$(cd "${RUN_DIR}/pkg" && pwd)"
while [ "${CHECK_DIR}" != "/" ]; do
  case "${CHECK_DIR}" in
    /[A-Za-z]) break ;;   # drive root (e.g. /c on Git-Bash/MSYS) -- dirname's
  esac                    # "/" above it is an unrelated mount (MSYS's own
                          # install dir), not a real Windows ancestor; walking
                          # into it produces "//<file>", which MSYS resolves as
                          # a UNC path that always reports as an existing
                          # (phantom) directory, a false positive on every run.
  CHECK_DIR="$(dirname "${CHECK_DIR}")"
  for f in CLAUDE.md AGENTS.md CLAUDE.local.md; do
    if [ -e "${CHECK_DIR}/${f}" ]; then
      echo "FATAL: ${CHECK_DIR}/${f} is an ancestor of the arm tree."
      echo "It will load into every arm. Move the run root somewhere with clean ancestry."
      exit 1
    fi
  done
done

if find "${RUN_DIR}/pkg" -name 'CLAUDE.md' -o -name 'AGENTS.md' | grep -q . ; then
  if [ "${ARM}" = "A0" ]; then
    echo "FATAL: instruction file present in control arm tree"; exit 1
  fi
fi
for f in cran-comments.md NEWS.md NEWS TODO; do
  [ -e "${RUN_DIR}/pkg/${f}" ] && { echo "FATAL: leakage file ${f}"; exit 1; }
done
[ -d "${RUN_DIR}/pkg/.git" ] && { echo "FATAL: .git present — history is readable"; exit 1; }

# --- Submission block (hard control, not a prompt instruction) ---------------
# A2 (cran-submit) ends by instructing the agent to submit via
# devtools::submit_cran(). The run is headless with --dangerously-skip-permissions,
# so nothing else would stop it. Five replicates of a real submission would put
# actual work on CRAN's volunteer reviewers.
#
# Package installs go to the pinned PPM snapshot, not cran.r-project.org, so
# blocking the submission host does not break dependency resolution.
if curl -s --max-time 5 -o /dev/null -w '%{http_code}' \
     https://cran.r-project.org/submit.html 2>/dev/null | grep -qE '^[23]'; then
  echo "FATAL: cran.r-project.org is reachable from this container."
  echo "Block egress to it before running. A prompt instruction is not a control."
  exit 1
fi

# The maintainer address in DESCRIPTION is left as-is deliberately: a stray
# submission triggers a confirmation email, which is a useful tripwire. CRAN
# submissions are not complete until that link is clicked — do not click it.

# --- Provenance --------------------------------------------------------------
{
  echo "run_id=${RUN_ID}"
  echo "arm=${ARM}  replicate=${REP}  block=${BLOCK}"
  echo "started_utc=$(date -u +%FT%TZ)"
  echo "image_digest=${IMAGE_DIGEST:-UNSET}"
  echo "ppm_snapshot=${PPM_SNAPSHOT_DATE:-UNSET}"
  echo "claude_code_version=$(claude --version 2>&1)"
  echo "r_version=$(R --version | head -1)"
} > "${RUN_DIR}/provenance.txt"

# --- Arm dependency layer ----------------------------------------------------
# Installs whatever the arm's DESCRIPTION declares, from the pinned snapshot.
# Versions identical across arms; dependency SET may differ.
# Written to a temp .R file and run with Rscript rather than `R -q -e "<multi-line>"`:
# a multi-line -e argument crashes native Windows R when invoked via Git Bash (MSYS
# argv translation bug, unrelated to R or the package) -- see verify_env.sh, which
# hit the same issue first.
DEPS_R="${RUN_DIR}/_deps_install.R"
cat > "${DEPS_R}" <<EOF
d <- tryCatch(desc::desc_get_deps('${RUN_DIR}/pkg'), error = function(e) NULL)
if (!is.null(d)) {
  p <- setdiff(unique(d\$package), c('R', rownames(installed.packages())))
  if (length(p)) install.packages(p)
}
EOF
Rscript "${DEPS_R}" > "${RUN_DIR}/dep_install.log" 2>&1

# ============================================================================
# COLD-START CALIBRATION  — do not skip
# ----------------------------------------------------------------------------
# A cold headless run loads the full context (skill file included) before doing
# any work. That fixed cost scales with skill file length, so raw token totals
# partly measure how VERBOSE an arm's skill file is, not how effective it is.
#
# Measure it: a null prompt in this exact arm configuration. Report tokens both
# raw and net of this floor. See pre-registration section 12.
# ============================================================================
claude -p "Reply with the single word: ready" \
  --output-format json \
  > "${RUN_DIR}/coldstart.json" 2> "${RUN_DIR}/coldstart.err"

jq -r '{
  coldstart_input_tokens:  (.usage.input_tokens // null),
  coldstart_output_tokens: (.usage.output_tokens // null),
  coldstart_cost_usd:      (.total_cost_usd // null)
}' "${RUN_DIR}/coldstart.json" > "${RUN_DIR}/coldstart_summary.json" 2>/dev/null

# Evidence of what actually loaded — this is your isolation proof slide.
cp -r "${CLAUDE_CONFIG_DIR}" "${RUN_DIR}/config-snapshot-preflight" 2>/dev/null || true

# --- Main run ----------------------------------------------------------------
cd "${RUN_DIR}/pkg"
START_EPOCH=$(date +%s)
WALL_CLOCK_CAP="${WALL_CLOCK_CAP:-7200}"
MAX_TURNS="${MAX_TURNS:-120}"
# STUCK_LOOP (section 6, redesigned 2026-09-21 after the live pilot killed all
# 6/6 arms in their first 8-11 turns -- see git log for the postmortem).
# Original design counted ANY 8 consecutive non-Edit/Write turns from turn 1,
# which is indistinguishable from normal opening exploration (survey the
# package, check for NAMESPACE/man, read DESCRIPTION) and fired on every run
# before it did anything. Redesigned with two changes:
#   1. GATED: the detector does not arm until the agent's first Edit/Write, or
#      its first "R CMD check"/"rcmdcheck" invocation -- i.e. only after the
#      run has actually started working. Pure exploration never trips it.
#   2. REPETITION, not silence: once armed, it fires on the same tool+input
#      (same file re-read, same command re-run) repeating STUCK_LOOP_TURNS
#      times in a row -- the literal "re-reading the same file, repeating the
#      same failing check, no forward progress" scenario the original comment
#      described, rather than merely the absence of an edit.
STUCK_LOOP_TURNS="${STUCK_LOOP_TURNS:-8}"

# stream-json requires --verbose. tee the raw bytes before parsing: if a parse
# fails you want the original stream to debug against.
# Do NOT use --bare: it skips loading project instructions, which would nullify
# every skill arm.
#
# Backgrounded via process substitution (not a plain pipe) so $! below is
# claude's own PID, not tee's or jq's -- the watcher needs to signal the right
# process. This replaces the old `timeout` wrapper: the watcher enforces
# WALL_CLOCK_CAP itself so it can also set a definitive termination reason
# (previously inferred after the fact from `timeout`'s exit code 124, which
# could not distinguish "ran out of time" from "stuck").
claude -p "$(cat "${EXP_ROOT}/FROZEN_PROMPT.txt")" \
  --output-format stream-json \
  --verbose \
  --max-turns "${MAX_TURNS}" \
  --allowedTools "Bash,Read,Edit,Write,Glob,Grep,WebFetch" \
  --dangerously-skip-permissions \
  > >(tee "${RUN_DIR}/stream.jsonl" | jq -c 'select(.type=="result")' > "${RUN_DIR}/result.json") \
  2> "${RUN_DIR}/agent.err" &
CLAUDE_PID=$!

# Independent backstop, disowned: if the watcher subshell below dies for any
# reason (a jq crash, a bug), this still bounds a run at CAP+60s so a harness
# bug cannot hang a 3-week schedule. Cancelled once the run ends normally.
( sleep "$(( WALL_CLOCK_CAP + 60 ))"; kill -9 "${CLAUDE_PID}" 2>/dev/null ) &
BACKSTOP_PID=$!
disown "${BACKSTOP_PID}" 2>/dev/null || true

# Live watcher: polls stream.jsonl as it grows. Two things it can end the run
# early for, each recorded to .termination_live so the classification below
# doesn't have to re-derive them from an exit code.
rm -f "${RUN_DIR}/.termination_live"
(
  armed=0
  last_sig=""
  repeat_count=0
  last_line_count=0
  while kill -0 "${CLAUDE_PID}" 2>/dev/null; do
    sleep 5
    now=$(date +%s)
    if [ "$(( now - START_EPOCH ))" -ge "${WALL_CLOCK_CAP}" ]; then
      echo "BUDGET_EXHAUSTED_WALLCLOCK" > "${RUN_DIR}/.termination_live"
      kill "${CLAUDE_PID}" 2>/dev/null
      break
    fi
    [ -f "${RUN_DIR}/stream.jsonl" ] || continue
    line_count=$(wc -l < "${RUN_DIR}/stream.jsonl" 2>/dev/null || echo 0)
    [ "${line_count}" -gt "${last_line_count}" ] || continue
    new_lines=$(tail -n "+$(( last_line_count + 1 ))" "${RUN_DIR}/stream.jsonl" 2>/dev/null)
    last_line_count=${line_count}
    # One record per assistant turn: a signature of its tool calls (name+input,
    # so a re-read of the same file or a re-run of the same command matches),
    # and whether that turn itself counts as "progress" (Edit/Write, or a
    # check invocation) for arming purposes.
    new_records=$(printf '%s' "${new_lines}" | jq -c '
      select(.type=="assistant") |
      {
        sig: ([.message.content[]? | select(.type=="tool_use") | (.name + ":" + (.input | tostring))] | join("|")),
        progress: (
          ([.message.content[]? | select(.type=="tool_use") | .name] | any(. == "Edit" or . == "Write"))
          or
          ([.message.content[]? | select(.type=="tool_use" and .name=="Bash") | (.input.command // "")]
           | any(test("R CMD check|rcmdcheck"; "i")))
        )
      }' 2>/dev/null)
    [ -n "${new_records}" ] || continue
    while IFS= read -r rec; do
      [ -n "${rec}" ] || continue
      sig=$(printf '%s' "${rec}" | jq -r '.sig' 2>/dev/null)
      prog=$(printf '%s' "${rec}" | jq -r '.progress' 2>/dev/null)
      [ "${prog}" = "true" ] && armed=1
      if [ "${armed}" -eq 1 ] && [ -n "${sig}" ] && [ "${sig}" = "${last_sig}" ]; then
        repeat_count=$(( repeat_count + 1 ))
      else
        repeat_count=1
      fi
      last_sig="${sig}"
      if [ "${armed}" -eq 1 ] && [ "${repeat_count}" -ge "${STUCK_LOOP_TURNS}" ]; then
        echo "STUCK_LOOP" > "${RUN_DIR}/.termination_live"
        kill "${CLAUDE_PID}" 2>/dev/null
        break 2
      fi
    done <<< "${new_records}"
  done
) &
WATCHER_PID=$!

wait "${CLAUDE_PID}" 2>/dev/null
EXIT_CODE=$?
kill "${WATCHER_PID}" "${BACKSTOP_PID}" 2>/dev/null
wait "${WATCHER_PID}" 2>/dev/null

END_EPOCH=$(date +%s)
cd - > /dev/null

# --- Usage extraction --------------------------------------------------------
# The result line carries cost and session metadata. The JSONL transcript under
# CLAUDE_CONFIG_DIR carries per-message usage if you need finer granularity.
jq -r '{
  total_cost_usd:   (.total_cost_usd // null),
  duration_ms:      (.duration_ms // null),
  num_turns:        (.num_turns // null),
  input_tokens:     (.usage.input_tokens // null),
  output_tokens:    (.usage.output_tokens // null),
  cache_read:       (.usage.cache_read_input_tokens // null),
  cache_creation:   (.usage.cache_creation_input_tokens // null),
  subtype:          (.subtype // null),
  is_error:         (.is_error // null)
}' "${RUN_DIR}/result.json" > "${RUN_DIR}/usage.json" 2>/dev/null

cp -r "${CLAUDE_CONFIG_DIR}" "${RUN_DIR}/config-snapshot-final" 2>/dev/null || true

# --- Termination reason (section 6, mandatory) -------------------------------
# Without this, a run stuck in a check-fix loop and a run that finished in ten
# turns are indistinguishable by turn count alone.
SUBTYPE=$(jq -r '.subtype // "unknown"' "${RUN_DIR}/result.json" 2>/dev/null)
TURNS=$(jq -r '.num_turns // 0' "${RUN_DIR}/result.json" 2>/dev/null)
# When the watcher kills the run early, result.json never gets a final "result"
# event -- num_turns is unavailable from it. Fall back to counting assistant
# turns directly from the transcript so TURNS still means something.
if [ "${TURNS}" = "0" ] || [ -z "${TURNS}" ]; then
  TURNS=$(jq -rs '[.[] | select(.type=="assistant")] | length' "${RUN_DIR}/stream.jsonl" 2>/dev/null || echo 0)
fi

if [ -f "${RUN_DIR}/.termination_live" ]; then
  TERMINATION=$(cat "${RUN_DIR}/.termination_live")   # BUDGET_EXHAUSTED_WALLCLOCK or STUCK_LOOP
elif [ "${SUBTYPE}" = "error_max_turns" ]; then
  TERMINATION="BUDGET_EXHAUSTED_TURNS"
elif [ "${SUBTYPE}" = "success" ]; then
  TERMINATION="DECLARED_DONE"          # refine to CONVERGED_CLEAN / _DIRTY at scoring
else
  TERMINATION="OTHER_${SUBTYPE}"
fi

# --- Mechanism endpoint: first check invocation ------------------------------
# Turn index at which the agent first ran R CMD check. Early-check vs
# build-then-check is the most plausible single mechanism for a skill effect,
# and it is one number per run.
FIRST_CHECK=$(jq -rs '
  [ to_entries[]
    | select(.value.type=="assistant")
    | select(.value | tostring | test("R CMD check|rcmdcheck|check\\("))
    | .key ] | first // "NA"
' "${RUN_DIR}/stream.jsonl" 2>/dev/null)

CHECK_INVOCATIONS=$(grep -c "R CMD check\|rcmdcheck" "${RUN_DIR}/stream.jsonl" 2>/dev/null || echo 0)

{
  echo "ended_utc=$(date -u +%FT%TZ)"
  echo "wall_clock_s=$((END_EPOCH - START_EPOCH))"
  echo "exit_code=${EXIT_CODE}"
  echo "termination=${TERMINATION}"
  echo "turns=${TURNS}"
  echo "first_check_event_index=${FIRST_CHECK}"
  echo "check_invocations=${CHECK_INVOCATIONS}"
} >> "${RUN_DIR}/provenance.txt"

# --- Submission-attempt tripwire ---------------------------------------------
# Flags an ATTEMPT even though egress was blocked. An attempt is a reportable
# behaviour of that skill, and it means the block did its job.
if grep -qiE 'submit_cran|release\(\)|cran\.r-project\.org/submit|ftp.*cran' \
     "${RUN_DIR}/stream.jsonl" 2>/dev/null; then
  echo "SUBMISSION_ATTEMPT_DETECTED" >> "${RUN_DIR}/provenance.txt"
  echo "!! ${RUN_ID}: agent attempted a CRAN submission (blocked). Review transcript."
  grep -inE 'submit_cran|cran\.r-project\.org/submit' "${RUN_DIR}/stream.jsonl" \
    | head -20 > "${RUN_DIR}/submission_attempt.log"
fi

# --- Archive the output tree, blinded ---------------------------------------
# Scoring happens on the opaque ID. Break the mapping only after all scores are
# recorded and committed (section 9).
BLIND_ID="RUN-$(echo -n "${RUN_ID}" | sha256sum | cut -c1-6)"
mkdir -p "${RUNS_ROOT}/blinded"
cp -r "${RUN_DIR}/pkg" "${RUNS_ROOT}/blinded/${BLIND_ID}"
# Keep the mapping OUT of the scoring directory (section 9).
echo "${BLIND_ID},${RUN_ID}" >> "${EXP_ROOT}/.blind_map.csv"

echo "done: ${RUN_ID} -> ${BLIND_ID} (${TERMINATION}, ${TURNS} turns)"
