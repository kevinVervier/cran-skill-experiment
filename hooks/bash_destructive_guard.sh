#!/usr/bin/env bash
# PreToolUse guard for the Bash tool, injected into every arm's fresh
# CLAUDE_CONFIG_DIR by run_arm.sh. Blocks `rm` with a combined recursive+force
# flag (-rf/-fr/-Rf/-fR) whose target is an unscoped wildcard, current/parent
# dir, filesystem root, home dir, or a drive root -- the shapes that can reach
# outside the run's own directory. A named, scoped path (e.g.
# `rm -rf /c/Users/.../runs/A2_r1_b1/pkg/build`) is left alone.
#
# Applies identically to every arm (A0-A5), so it cannot bias the comparison.
# Hooks fire regardless of --dangerously-skip-permissions -- that flag only
# skips the allow/ask/deny prompt flow, not lifecycle hooks.
set -u

input=$(cat)
tool_name=$(printf '%s' "${input}" | jq -r '.tool_name // empty' 2>/dev/null)
if [ "${tool_name}" != "Bash" ]; then
  echo '{}'
  exit 0
fi
command=$(printf '%s' "${input}" | jq -r '.tool_input.command // empty' 2>/dev/null)

pattern='(^|[;&|(`[:space:]])rm[[:space:]]+-[A-Za-z]*[rRfF]{2}[A-Za-z]*[[:space:]]+(\*|\.\.|\.|/|~/\*?|~|/c/?\*?|C:[\\/]\*?|\$HOME/?\*?)([[:space:]]|[;&|)`]|$)'

if printf '%s' "${command}" | grep -qE "${pattern}"; then
  match=$(printf '%s' "${command}" | grep -oE "${pattern}" | head -1)
  jq -n --arg reason "Blocked: '${match}' -- rm with a recursive+force flag must target an explicit path inside your own run/tmp directory, not a bare wildcard or filesystem root. Rewrite with the full path you intend to delete." '
    {hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: "deny", permissionDecisionReason: $reason}}'
else
  echo '{}'
fi
exit 0
