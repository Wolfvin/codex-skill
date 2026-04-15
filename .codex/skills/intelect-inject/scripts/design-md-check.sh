#!/usr/bin/env bash
set -euo pipefail

file=""
usage(){
  cat <<'EOF'
Usage:
  design-md-check.sh --file <DESIGN.md path>
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) file="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage >&2; exit 2 ;;
  esac
done

[[ -n "$file" ]] || { echo "missing --file" >&2; exit 2; }
[[ -f "$file" ]] || { echo "status=fail\nreason=file_not_found"; exit 1; }

required=(
  "Visual Theme"
  "Color"
  "Typography"
  "Component"
  "Responsive"
  "Do's and Don'ts"
)

missing=()
for r in "${required[@]}"; do
  if ! rg -qi "$r" "$file"; then
    missing+=("$r")
  fi
done

if [[ ${#missing[@]} -gt 0 ]]; then
  printf "status=fail\nmissing_sections=%s\n" "$(IFS=,; echo "${missing[*]}")"
  exit 1
fi

printf "status=pass\nfile=%s\n" "$file"
