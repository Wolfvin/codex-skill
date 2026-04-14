#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$CODEX_DIR/.." && pwd)"
TMP_ROOT="$PROJECT_ROOT/.tmp/repo-intake"
MEMORY_DIR="$CODEX_DIR/memory"

usage() {
  cat <<USAGE
Usage:
  bash .codex/tools/agentic-cli.sh intake <repo-url|local-path> [repo-url|local-path ...]
  bash .codex/tools/agentic-cli.sh sync <source-dir>

Examples:
  bash .codex/tools/agentic-cli.sh intake https://github.com/openai/skills
  bash .codex/tools/agentic-cli.sh intake https://github.com/openai/skills https://github.com/Enderfga/openclaw-claude-code
  bash .codex/tools/agentic-cli.sh sync .tmp/repo-intake/reports
USAGE
}

is_dir_writable() {
  local dir="$1"
  mkdir -p "$dir" 2>/dev/null || return 1
  local probe="$dir/.write_probe_$$"
  if ( : > "$probe" ) 2>/dev/null; then
    rm -f "$probe" 2>/dev/null || true
    return 0
  fi
  return 1
}

cmd="${1:-}"
shift || true

if [ -z "$cmd" ]; then
  usage
  exit 1
fi

case "$cmd" in
  intake)
    if [ $# -lt 1 ]; then
      usage
      exit 1
    fi
    ts="$(date +%Y%m%d-%H%M%S)"
    report_root="$MEMORY_DIR"
    if ! is_dir_writable "$MEMORY_DIR"; then
      report_root="$TMP_ROOT/reports"
      mkdir -p "$report_root"
      echo "[agentic-cli] warning: $MEMORY_DIR not writable, using $report_root"
    fi
    summary="$report_root/summary_$ts.md"
    synth="$report_root/synthesis_$ts.md"

    echo "# Multi Repo Intake Summary" > "$summary"
    echo "" >> "$summary"
    echo "- Generated: $ts" >> "$summary"
    echo "- Workspace: $PROJECT_ROOT" >> "$summary"
    echo "" >> "$summary"
    echo "## Sources" >> "$summary"

    for url in "$@"; do
      echo "[agentic-cli] intake $url"
      report_path="$(bash "$SCRIPT_DIR/repo-intake-cli.sh" "$url" | awk -F': ' '/report:/{print $2}')"
      if [ -n "$report_path" ]; then
        echo "- $url" >> "$summary"
        echo "  - Report: $report_path" >> "$summary"
      else
        echo "- $url" >> "$summary"
        echo "  - Report: (unknown)" >> "$summary"
      fi
    done

    cat > "$synth" <<SYNTH
# Intake Synthesis

## Guidance
- Keep only high-signal patterns that improve agentic coding quality.
- Prefer official/curated sources when available.
- Do not import leaked or questionable IP.

## Next Steps
- Curate reports listed in summary into:
  - .codex/skills/*
  - .codex/README.md
  - .codex/memory/akp2i_projects.md
SYNTH

    echo "[agentic-cli] summary: $summary"
    echo "[agentic-cli] synthesis: $synth"
    if [ "$report_root" != "$MEMORY_DIR" ]; then
      echo "[agentic-cli] sync later:"
      echo "  bash .codex/tools/agentic-cli.sh sync $report_root"
    fi
    ;;
  sync)
    src="${1:-}"
    if [ -z "$src" ]; then
      usage
      exit 1
    fi
    if ! is_dir_writable "$MEMORY_DIR"; then
      echo "[agentic-cli] memory dir not writable: $MEMORY_DIR"
      exit 1
    fi
    mkdir -p "$MEMORY_DIR"
    cp -f "$src"/*.md "$MEMORY_DIR/" 2>/dev/null || true
    echo "[agentic-cli] synced reports into $MEMORY_DIR"
    ;;
  *)
    usage
    exit 1
    ;;
esac
