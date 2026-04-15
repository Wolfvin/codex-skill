#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"

pass() { printf "[PASS] %s\n" "$1"; }
fail() { printf "[FAIL] %s\n" "$1"; exit 1; }

check_file() {
  local f="$1"
  [[ -f "$f" ]] || fail "missing file: $f"
}

check_contains() {
  local f="$1"
  local p="$2"
  rg -q "$p" "$f" || fail "$f missing pattern: $p"
}

check_file "AGENTS.md"
check_file ".codex/AGENTS.md"
check_file ".codex/skills/skill-router/SKILL.md"
check_file ".codex/skills/think/SKILL.md"
check_file ".codex/skills/intelect-inject/SKILL.md"
check_file ".codex/skills/typescript-inject/SKILL.md"

check_contains "AGENTS.md" "skill-router.*think"
pass "AGENTS gate skill-router + think"

check_contains ".codex/AGENTS.md" "skill-router.*think"
pass ".codex/AGENTS gate skill-router + think"

check_contains ".codex/skills/skill-router/SKILL.md" "Canonical owner map"
check_contains ".codex/skills/skill-router/SKILL.md" "intelect-inject"
check_contains ".codex/skills/skill-router/SKILL.md" "typescript-inject"
pass "skill-router canonical owner map"

check_contains ".codex/skills/intelect-inject/SKILL.md" "name: intelect-inject"
check_contains ".codex/skills/typescript-inject/SKILL.md" "name: typescript-inject"
pass "hyphen-case skill names"

echo "Routing smoke test OK."
