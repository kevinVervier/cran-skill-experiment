#!/usr/bin/env bash
# PreToolUse guard confining an arm to its own run directory.
#
# WHY: this host has no container (ENVIRONMENT.md -- Docker dropped, native
# toolchain instead). The --tools allowlist in run_arm.sh restricts which
# TOOL NAMES an arm can call, not which PATHS those tools can reach. Bash,
# Read, Glob and Grep all have full filesystem access by default. Confirmed
# directly in the block-1 pilot: A2 ran
#   ls /c/Users/Shadow/Bricoles/cran-skill-experiment
# from inside its own pkg tree and got back a real listing including
# criterion-corpus.md and criterion-corpus-longtail.md -- the answer key
# this project's own CLAUDE.md says must never reach an arm -- plus
# FROZEN_PROMPT.txt and frozen-tests/. It didn't go further this run, but
# nothing stopped it, and A2's own skill explicitly encourages adversarial
# probing.
#
# This hook denies Read/Edit/Write/Glob/Grep calls whose target resolves
# outside the run's own RUN_DIR, and denies Bash commands that reference
# EXP_ROOT (the harness -- an arm never has a legitimate reason to touch it)
# or reference RUNS_ROOT outside the run's own RUN_DIR (other arms, other
# replicates, blinded/, arms/). It is a second, deterministic layer, in the
# same spirit as bash_destructive_guard.sh -- not a full sandbox. A regex/
# substring check on a free-form Bash command string cannot catch every
# encoding of "escape my own tree" (obfuscated paths, a subprocess that
# re-execs with a rewritten argv, etc.). It catches the direct, unobfuscated
# form that actually occurred, and costs nothing on the arms that never try.
#
# The allowed root is the WHOLE run directory, not just pkg/ -- caught live
# in the first fixed-harness pilot: A2 and A4 both tried to write a one-off
# helper script (fix_cat.R, fix_msg.py) one level above pkg/, a completely
# ordinary scratch-file pattern, still fully inside their own isolated tree.
# Restricting to pkg/ alone blocked that as a false positive and cost both
# arms extra turns working around it. RUN_DIR/claude-config is the one
# exception carved back OUT of that allowed root: it holds this arm's OAuth
# credential plus the settings.json/hook source that implement this very
# guard, and letting an arm read its own hook implementation would invite a
# targeted bypass.
#
# Applies identically to every arm (A0-A5) via the same settings.json shape,
# so it cannot bias the comparison.
set -u

input=$(cat)
tool_name=$(printf '%s' "${input}" | jq -r '.tool_name // empty' 2>/dev/null)

: "${RUN_DIR_ROOT:?path_confinement_guard.sh: RUN_DIR_ROOT not set}"
: "${FORBIDDEN_EXP_ROOT:?path_confinement_guard.sh: FORBIDDEN_EXP_ROOT not set}"
: "${FORBIDDEN_RUNS_ROOT:?path_confinement_guard.sh: FORBIDDEN_RUNS_ROOT not set}"

allow() { echo '{}'; exit 0; }
deny() {
  jq -n --arg reason "$1" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
  exit 0
}

# Normalize for comparison only: backslashes -> forward slashes, lowercase
# (Windows paths are case-insensitive), a bare drive letter canonicalized to
# git-bash's /c/ form (realpath does NOT do this -- `realpath -m` on a
# Windows-style input returns it unchanged, e.g. "C:/Users/..." stays
# "C:/Users/...", it does not become "/c/Users/..."; EXP_ROOT/RUNS_ROOT are
# themselves posix-style per CLAUDE.md, so without this an arm referencing
# its own tree in Windows form would silently bypass every check below),
# then strip a trailing slash. Never used for an actual filesystem
# operation, only for the containment check.
norm() {
  printf '%s' "$1" | tr 'A-Z\\' 'a-z/' \
    | sed -E 's#(^|[^a-z0-9])([a-z]):/#\1/\2/#g' \
    | sed -e 's:/*$::'
}

ALLOWED_NORM=$(norm "${RUN_DIR_ROOT}")
CLAUDE_CONFIG_NORM="${ALLOWED_NORM}/claude-config"
EXP_ROOT_NORM=$(norm "${FORBIDDEN_EXP_ROOT}")
RUNS_ROOT_NORM=$(norm "${FORBIDDEN_RUNS_ROOT}")

path_is_forbidden() {
  # $1 = normalized absolute path to check
  local cand="$1"
  # Off-limits even though it's inside our own RUN_DIR -- see header comment.
  case "${cand}" in
    "${CLAUDE_CONFIG_NORM}"|"${CLAUDE_CONFIG_NORM}"/*) return 0 ;;
  esac
  case "${cand}" in
    "${ALLOWED_NORM}"|"${ALLOWED_NORM}"/*) return 1 ;;   # rest of our own run dir: fine
  esac
  case "${cand}" in
    "${EXP_ROOT_NORM}"|"${EXP_ROOT_NORM}"/*) return 0 ;; # the harness itself
    "${RUNS_ROOT_NORM}"|"${RUNS_ROOT_NORM}"/*) return 0 ;; # sibling arms/runs/blinded
  esac
  return 1
}

case "${tool_name}" in
  Read|Edit|Write)
    fp=$(printf '%s' "${input}" | jq -r '.tool_input.file_path // empty' 2>/dev/null)
    [ -z "${fp}" ] && allow
    resolved=$(realpath -m -- "${fp}" 2>/dev/null) || allow
    if path_is_forbidden "$(norm "${resolved}")"; then
      deny "Blocked: '${fp}' resolves outside your run's own directory. Work only inside your own tree."
    fi
    allow
    ;;
  Glob|Grep)
    p=$(printf '%s' "${input}" | jq -r '.tool_input.path // empty' 2>/dev/null)
    [ -z "${p}" ] && allow   # no path given -- defaults to cwd, already inside our tree
    resolved=$(realpath -m -- "${p}" 2>/dev/null) || allow
    if path_is_forbidden "$(norm "${resolved}")"; then
      deny "Blocked: '${p}' resolves outside your run's own directory. Work only inside your own tree."
    fi
    allow
    ;;
  Bash)
    command=$(printf '%s' "${input}" | jq -r '.tool_input.command // empty' 2>/dev/null)
    cmd_norm=$(norm "${command}")
    if printf '%s' "${cmd_norm}" | grep -qF -- "${EXP_ROOT_NORM}"; then
      deny "Blocked: command references the harness directory (EXP_ROOT), which is off-limits to every arm. Work only inside your own run directory."
    fi
    # claude-config checked BEFORE the RUN_DIR scrub below -- it's nested
    # inside our own allowed root, so the scrub would otherwise erase every
    # reference to it and let it slip through the RUNS_ROOT check untouched.
    if printf '%s' "${cmd_norm}" | grep -qF -- "${CLAUDE_CONFIG_NORM}"; then
      deny "Blocked: command references claude-config (this run's own credentials/hooks), which is off-limits. Work only inside your own package directory."
    fi
    # Scrub references to our OWN run directory before checking for
    # RUNS_ROOT -- an absolute path anywhere in our own RUN_DIR is fine; a
    # bare RUNS_ROOT reference (siblings, arms/, blinded/) is not.
    # '#' as the sed delimiter, not ':' -- normalized Windows paths contain a
    # drive-letter colon (c:/...), which would otherwise terminate the s///
    # early and silently skip the scrub.
    scrubbed=$(printf '%s' "${cmd_norm}" | sed "s#${ALLOWED_NORM}[^ '\"]*##g")
    if printf '%s' "${scrubbed}" | grep -qF -- "${RUNS_ROOT_NORM}"; then
      deny "Blocked: command references paths outside your own run directory under RUNS_ROOT (other arms, replicates, or blinded output). Work only inside your own package directory."
    fi
    allow
    ;;
  *)
    allow
    ;;
esac
