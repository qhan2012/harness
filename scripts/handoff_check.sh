#!/usr/bin/env bash
# Stop hook for Claude Code and Codex: block the end of a turn while handoff
# state is not saved. Exit 2 with a reason on stderr blocks; exit 0 allows.
input=$(cat)
# Let the agent stop on the second try, so the hook can never loop.
if printf '%s' "$input" | grep -Eq '"stop_hook_active"[[:space:]]*:[[:space:]]*true'; then
  exit 0
fi
root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$root" || exit 0
state=(reports memory MEMORY.md codebases/REPOS.md)
problems=()
if [ -n "$(git status --porcelain -- "${state[@]}" 2>/dev/null)" ]; then
  problems+=("uncommitted changes in reports/, memory/, MEMORY.md, or codebases/REPOS.md")
fi
if git rev-parse --abbrev-ref '@{u}' >/dev/null 2>&1 \
  && [ -n "$(git log --oneline '@{u}..HEAD' -- "${state[@]}" 2>/dev/null)" ]; then
  problems+=("commits that change handoff files are not pushed")
fi
if [ -f scripts/memory_index.py ] && ! python3 scripts/memory_index.py --check >/dev/null 2>&1; then
  problems+=("MEMORY.md is out of date or a memory file is invalid; run python3 scripts/memory_index.py")
fi
if [ ${#problems[@]} -gt 0 ]; then
  {
    echo "Handoff state is not saved (see AGENTS.md § Session handoff):"
    printf -- '- %s\n' "${problems[@]}"
    echo "Commit and push these files, then stop."
  } >&2
  exit 2
fi
exit 0
