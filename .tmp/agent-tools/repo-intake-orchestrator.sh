#!/usr/bin/env bash
set -euo pipefail

WORKDIR="${1:-$(pwd)}"
shift || true
if [ "$WORKDIR" = "--help" ] || [ "$WORKDIR" = "-h" ]; then
  echo "Usage: bash .tmp/agent-tools/repo-intake-orchestrator.sh [workdir] <repo-url> [repo-url ...]"
  exit 0
fi

if [ $# -lt 1 ]; then
  echo "Need at least one repo URL"
  echo "Usage: bash .tmp/agent-tools/repo-intake-orchestrator.sh [workdir] <repo-url> [repo-url ...]"
  exit 1
fi

TS="$(date +%Y%m%d-%H%M%S)"
ROOT="$WORKDIR/.tmp/repo-intake"
CLONES="$ROOT/clones-$TS"
REPORTS="$ROOT/reports"
SUMMARY="$ROOT/summary_$TS.md"
mkdir -p "$CLONES" "$REPORTS"

slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | sed -E 's#[^a-z0-9]+#-#g; s#(^-|-$)##g'
}

extract_signal() {
  local clone_dir="$1"
  local out_file="$2"
  local url="$3"

  local readmes
  local workflows
  local manifests
  local skills
  local agent_files

  readmes="$(find "$clone_dir" -maxdepth 2 -type f \( -iname 'readme.md' -o -iname 'readme*' \) | sed "s#^$clone_dir/##" | sort || true)"
  workflows="$(find "$clone_dir/.github/workflows" -maxdepth 2 -type f \( -name '*.yml' -o -name '*.yaml' \) 2>/dev/null | sed "s#^$clone_dir/##" | sort || true)"
  manifests="$(find "$clone_dir" -maxdepth 4 -type f \( -name 'package.json' -o -name 'pyproject.toml' -o -name 'requirements.txt' -o -name 'Cargo.toml' -o -name 'go.mod' -o -name 'Dockerfile' -o -name 'docker-compose.yml' -o -name '.mcp.json' -o -name 'mcp.json' -o -name 'AGENTS.md' -o -name 'CLAUDE.md' \) | sed "s#^$clone_dir/##" | sort || true)"
  skills="$(find "$clone_dir" -maxdepth 6 -type f -name 'SKILL.md' | sed "s#^$clone_dir/##" | sort || true)"
  agent_files="$(find "$clone_dir" -maxdepth 6 -type f \( -path '*/.codex/*' -o -path '*/.cursor/*' -o -name 'AGENTS.md' -o -name 'CLAUDE.md' \) | sed "s#^$clone_dir/##" | sort || true)"

  local skill_count="0"
  if [ -n "$skills" ]; then
    skill_count="$(echo "$skills" | grep -c . || true)"
  fi

  cat > "$out_file" <<REPORT
# Repo Intake Report

- Source: $url
- Clone: $clone_dir
- SKILL.md count: $skill_count

## README
$(if [ -n "$readmes" ]; then echo "$readmes" | sed 's/^/- /'; else echo "- none"; fi)

## CI Workflows
$(if [ -n "$workflows" ]; then echo "$workflows" | sed 's/^/- /'; else echo "- none"; fi)

## Key Manifests/Instructions
$(if [ -n "$manifests" ]; then echo "$manifests" | sed 's/^/- /'; else echo "- none"; fi)

## Agent/Skill Files
$(if [ -n "$agent_files" ]; then echo "$agent_files" | sed 's/^/- /'; else echo "- none"; fi)

## Skill Files (sample)
$(if [ -n "$skills" ]; then echo "$skills" | head -n 40 | sed 's/^/- /'; else echo "- none"; fi)
REPORT
}

{
  echo "# Multi Repo Intake Summary"
  echo
  echo "- Generated: $TS"
  echo "- Workspace: $WORKDIR"
  echo
  echo "## Sources"
} > "$SUMMARY"

for url in "$@"; do
  base="$(basename "$url")"
  base="${base%.git}"
  slug="$(slugify "$base")"
  dest="$CLONES/$slug"
  report="$REPORTS/${slug}_$TS.md"

  echo "[intake] cloning $url"
  git clone --depth 1 "$url" "$dest" >/dev/null 2>&1
  echo "[intake] extracting $slug"
  extract_signal "$dest" "$report" "$url"

  {
    echo "- $url"
    echo "  - Report: $report"
  } >> "$SUMMARY"
done

{
  echo
  echo "## Next"
  echo "- Curate only high-signal patterns into .codex (when writable)."
  echo "- If .codex is read-only, keep reports in .tmp/repo-intake/reports first."
} >> "$SUMMARY"

echo "[intake] done"
echo "[intake] summary: $SUMMARY"
