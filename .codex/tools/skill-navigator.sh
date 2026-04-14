#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAP_FILE="$SCRIPT_DIR/../skills/_navigation/skill-map.tsv"

usage() {
  cat <<USAGE
Usage:
  bash .codex/tools/skill-navigator.sh suggest <prompt text>
  bash .codex/tools/skill-navigator.sh list [category]
USAGE
}

if [ ! -f "$MAP_FILE" ]; then
  echo "[skill-navigator] map file missing: $MAP_FILE" >&2
  exit 1
fi

cmd="${1:-}"
shift || true

case "$cmd" in
  suggest)
    if [ $# -lt 1 ]; then
      usage
      exit 1
    fi
    prompt="$(printf '%s ' "$@" | tr '[:upper:]' '[:lower:]')"
    awk -F '\t' -v q="$prompt" 'NR>1 {
      score=0;
      n=split($3, kw, " ");
      for (i=1; i<=n; i++) {
        if (kw[i] != "" && index(q, kw[i]) > 0) score++;
      }
      if (score > 0) printf "%d\t%s\t%s\n", score, $1, $2;
    }' "$MAP_FILE" | sort -t $'\t' -k1,1nr -k2,2 -k3,3 | head -n 8 | awk -F '\t' '{printf "- %s (%s) score=%s\n", $2, $3, $1}'
    ;;
  list)
    category="${1:-}"
    if [ -z "$category" ]; then
      awk -F '\t' 'NR>1 {printf "- %s (%s)\n", $1, $2}' "$MAP_FILE"
    else
      awk -F '\t' -v c="$category" 'NR>1 && $2==c {printf "- %s (%s)\n", $1, $2}' "$MAP_FILE"
    fi
    ;;
  *)
    usage
    exit 1
    ;;
esac
