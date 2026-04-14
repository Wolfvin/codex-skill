#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CODEX_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$CODEX_DIR/.." && pwd)"
MCP_FILE_DEFAULT="$PROJECT_ROOT/.vscode/mcp.json"
PLUGIN_MEMORY_FILE="$CODEX_DIR/memory/plugins_connectors.md"

usage() {
  cat <<USAGE
Agentic Hub CLI

Usage:
  bash .codex/tools/agentic-hub.sh doctor
  bash .codex/tools/agentic-hub.sh bootstrap [project-root]
  bash .codex/tools/agentic-hub.sh intake <repo-url|local-path> [repo-url|local-path ...]
  bash .codex/tools/agentic-hub.sh sync [reports-dir]
  bash .codex/tools/agentic-hub.sh checkpoint --goal <text> --done <text> --next <text> [--blockers <text>]
  bash .codex/tools/agentic-hub.sh skill suggest <prompt text>
  bash .codex/tools/agentic-hub.sh skill list [category]

  bash .codex/tools/agentic-hub.sh mcp list [mcp-file]
  bash .codex/tools/agentic-hub.sh mcp add-http <name> <url> [mcp-file]
  bash .codex/tools/agentic-hub.sh mcp add-stdio <name> <command> [arg ...] [--file <mcp-file>]

  bash .codex/tools/agentic-hub.sh connector list [mcp-file]
  bash .codex/tools/agentic-hub.sh connector add-http <name> <url> [mcp-file]
  bash .codex/tools/agentic-hub.sh connector add-stdio <name> <command> [arg ...] [--file <mcp-file>]
  bash .codex/tools/agentic-hub.sh connector preset claude-core [mcp-file]

  bash .codex/tools/agentic-hub.sh plugin note <name> <source>
  bash .codex/tools/agentic-hub.sh plugin import-openclaw <openclaw.plugin.json>
  bash .codex/tools/agentic-hub.sh plugin recommend buildwithclaude
  bash .codex/tools/agentic-hub.sh plugin recommend ariff

Examples:
  bash .codex/tools/agentic-hub.sh intake https://github.com/openai/skills https://github.com/Enderfga/openclaw-claude-code
  bash .codex/tools/agentic-hub.sh mcp add-http openaiDeveloperDocs https://developers.openai.com/mcp
  bash .codex/tools/agentic-hub.sh connector add-stdio codeReviewGraph .tools/code-review-graph-venv/bin/code-review-graph serve
  bash .codex/tools/agentic-hub.sh connector preset claude-core
  bash .codex/tools/agentic-hub.sh plugin import-openclaw .tmp/repo-intake/openclaw-claude-code-20260414-112001/openclaw.plugin.json
  bash .codex/tools/agentic-hub.sh plugin recommend buildwithclaude
  bash .codex/tools/agentic-hub.sh plugin recommend ariff
  bash .codex/tools/agentic-hub.sh skill suggest "fix regression auth and verify claim with citations"
  bash .codex/tools/agentic-hub.sh checkpoint --goal "Intake clawspring" --done "Parsed architecture" --next "Update skill" --blockers "-"
USAGE
}

ensure_file_parent() {
  local file="$1"
  mkdir -p "$(dirname "$file")"
}

ensure_mcp_file() {
  local mcp_file="$1"
  ensure_file_parent "$mcp_file"
  if [ ! -f "$mcp_file" ]; then
    cat > "$mcp_file" <<'JSON'
{
  "servers": {}
}
JSON
  fi
}

backup_file() {
  local file="$1"
  if [ -f "$file" ]; then
    cp "$file" "$file.bak.$(date +%Y%m%d%H%M%S)"
  fi
}

mcp_list() {
  local mcp_file="${1:-$MCP_FILE_DEFAULT}"
  if [ ! -f "$mcp_file" ]; then
    echo "[agentic-hub] mcp file not found: $mcp_file"
    return 1
  fi

  python3 - "$mcp_file" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
obj = json.loads(path.read_text())
servers = obj.get("servers", {})
if not servers:
    print("(no servers)")
    raise SystemExit(0)

for name in sorted(servers.keys()):
    cfg = servers[name]
    typ = cfg.get("type", "?")
    if typ == "http":
        detail = cfg.get("url", "")
    else:
        cmd = cfg.get("command", "")
        args = " ".join(cfg.get("args", []))
        detail = f"{cmd} {args}".strip()
    print(f"- {name} [{typ}] {detail}")
PY
}

mcp_add_http() {
  local name="$1"
  local url="$2"
  local mcp_file="${3:-$MCP_FILE_DEFAULT}"

  ensure_mcp_file "$mcp_file"
  backup_file "$mcp_file"

  python3 - "$mcp_file" "$name" "$url" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
name = sys.argv[2]
url = sys.argv[3]
obj = json.loads(path.read_text())
obj.setdefault("servers", {})
obj["servers"][name] = {
    "type": "http",
    "url": url,
}
path.write_text(json.dumps(obj, indent=2) + "\n")
print(f"[agentic-hub] upserted http MCP '{name}' -> {url}")
PY
}

mcp_add_stdio() {
  local name="$1"
  local command="$2"
  shift 2

  local mcp_file="$MCP_FILE_DEFAULT"
  local args=()
  while [ $# -gt 0 ]; do
    if [ "$1" = "--file" ]; then
      mcp_file="${2:-$MCP_FILE_DEFAULT}"
      shift 2
      continue
    fi
    args+=("$1")
    shift
  done

  ensure_mcp_file "$mcp_file"
  backup_file "$mcp_file"

  python3 - "$mcp_file" "$name" "$command" "${args[@]}" <<'PY'
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
name = sys.argv[2]
command = sys.argv[3]
args = sys.argv[4:]
obj = json.loads(path.read_text())
obj.setdefault("servers", {})
obj["servers"][name] = {
    "type": "stdio",
    "command": command,
    "args": args,
}
path.write_text(json.dumps(obj, indent=2) + "\n")
print(f"[agentic-hub] upserted stdio MCP '{name}' -> {command} {' '.join(args)}")
PY
}

plugin_note() {
  local name="$1"
  local source="$2"
  local today
  today="$(date +%Y-%m-%d)"
  ensure_file_parent "$PLUGIN_MEMORY_FILE"

  if [ ! -f "$PLUGIN_MEMORY_FILE" ]; then
    cat > "$PLUGIN_MEMORY_FILE" <<'MD'
# Plugin and Connector Notes

Track plugin/connector references that should remain visible for future sessions.
MD
  fi

  if ! grep -Fq -- "- $name | $source" "$PLUGIN_MEMORY_FILE"; then
    printf '\n- %s | %s | %s\n' "$name" "$source" "$today" >> "$PLUGIN_MEMORY_FILE"
  fi
  echo "[agentic-hub] noted plugin reference: $name"
}

checkpoint_note() {
  local goal=""
  local done=""
  local next=""
  local blockers="-"

  while [ $# -gt 0 ]; do
    case "$1" in
      --goal)
        goal="${2:-}"
        shift 2
        ;;
      --done)
        done="${2:-}"
        shift 2
        ;;
      --next)
        next="${2:-}"
        shift 2
        ;;
      --blockers)
        blockers="${2:-}"
        shift 2
        ;;
      *)
        echo "[agentic-hub] unknown checkpoint arg: $1" >&2
        return 1
        ;;
    esac
  done

  if [ -z "$goal" ] || [ -z "$done" ] || [ -z "$next" ]; then
    echo "[agentic-hub] checkpoint requires --goal --done --next" >&2
    return 1
  fi

  local mem_dir="$CODEX_DIR/memory"
  local snap_dir="$mem_dir/session_snapshots"
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  local now
  now="$(date '+%Y-%m-%d %H:%M:%S %z')"
  mkdir -p "$snap_dir"

  local file="$snap_dir/snapshot_$ts.md"
  local latest="$mem_dir/session_snapshot_latest.md"

  cat > "$file" <<MD
# Session Snapshot

- Timestamp: $now
- Goal: $goal
- Done: $done
- Next: $next
- Blockers: $blockers
MD

  cp "$file" "$latest"
  echo "[agentic-hub] checkpoint saved:"
  echo "- $file"
  echo "- $latest"
}

connector_preset_claude_core() {
  local mcp_file="${1:-$MCP_FILE_DEFAULT}"
  echo "[agentic-hub] applying connector preset: claude-core"

  mcp_add_http "openaiDeveloperDocs" "https://developers.openai.com/mcp" "$mcp_file"
  mcp_add_stdio "context7" "npx" "-y" "@upstash/context7-mcp" "--file" "$mcp_file"
  mcp_add_stdio "filesystem" "npx" "-y" "@modelcontextprotocol/server-filesystem" "\${workspaceFolder}" "--file" "$mcp_file"
  mcp_add_stdio "git" "npx" "-y" "@modelcontextprotocol/server-git" "--repository" "\${workspaceFolder}" "--file" "$mcp_file"
  mcp_add_stdio "fetch" "npx" "-y" "@modelcontextprotocol/server-fetch" "--file" "$mcp_file"
  mcp_add_stdio "time" "npx" "-y" "@modelcontextprotocol/server-time" "--local-timezone=Asia/Pontianak" "--file" "$mcp_file"
  mcp_add_stdio "memory" "npx" "-y" "@modelcontextprotocol/server-memory" "--file" "$mcp_file"

  plugin_note "claude-core-connectors" "preset://claude-core"
  echo "[agentic-hub] preset applied into: $mcp_file"
}

plugin_import_openclaw() {
  local plugin_json="$1"
  if [ ! -f "$plugin_json" ]; then
    echo "[agentic-hub] openclaw plugin file not found: $plugin_json" >&2
    return 1
  fi

  local profiles_dir="$CODEX_DIR/memory/plugin_profiles"
  mkdir -p "$profiles_dir"
  local out_file="$profiles_dir/openclaw_claude_code_sdk.md"
  local today
  today="$(date +%Y-%m-%d)"

  python3 - "$plugin_json" "$out_file" <<'PY'
import json
import sys
from pathlib import Path

plugin_path = Path(sys.argv[1])
out_file = Path(sys.argv[2])
obj = json.loads(plugin_path.read_text())

plugin_id = obj.get("id", "unknown")
name = obj.get("name", "unknown")
description = obj.get("description", "")
tools = obj.get("contracts", {}).get("tools", [])
skills = obj.get("skills", [])
enabled = obj.get("enabledByDefault", False)
caps = obj.get("capabilities", {})

lines = []
lines.append("# OpenClaw Plugin Profile")
lines.append("")
lines.append(f"- id: {plugin_id}")
lines.append(f"- name: {name}")
lines.append(f"- enabledByDefault: {enabled}")
lines.append(f"- source: {plugin_path}")
if description:
    lines.append(f"- description: {description}")
if caps:
    lines.append(f"- capabilities: {json.dumps(caps)}")
lines.append("")
lines.append("## Tools")
if tools:
    for t in tools:
        lines.append(f"- {t}")
else:
    lines.append("- (none)")
lines.append("")
lines.append("## Skills")
if skills:
    for s in skills:
        lines.append(f"- {s}")
else:
    lines.append("- (none)")
lines.append("")
lines.append("## Integration Note")
lines.append("- This profile is for orchestration reference in Codex workspace.")
lines.append("- It does not automatically make Claude plugins executable in Codex runtime.")

out_file.write_text("\n".join(lines) + "\n")
print(out_file)
PY

  plugin_note "openclaw-claude-code" "$plugin_json"
  {
    echo ""
    echo "- openclaw-claude-code-profile | $out_file | $today"
  } >> "$PLUGIN_MEMORY_FILE"
  echo "[agentic-hub] imported openclaw plugin profile: $out_file"
}

plugin_recommend() {
  local source="${1:-}"
  case "$source" in
    buildwithclaude)
      cat <<'TXT'
[agentic-hub] recommended plugins (buildwithclaude)
1. codex-hud
   /plugin install codex-hud@buildwithclaude
2. cc-best
   /plugin install cc-best@buildwithclaude
3. shipwright
   /plugin install shipwright@buildwithclaude

Add marketplace first:
  /plugin marketplace add davepoon/buildwithclaude
TXT
      plugin_note "buildwithclaude-curated" "marketplace://davepoon/buildwithclaude"
      ;;
    ariff)
      cat <<'TXT'
[agentic-hub] recommended plugins (ariff-claude-plugins)
1. anti-hallucination suite (targeted)
   - hallucination-guard (hook)
   - answer-validator (hook)
   - truth-finder (agent)
   - answer-analyzer (agent)
   - anti-hallucination, cross-checker, source-verifier,
     confidence-scorer, citation-enforcer, uncertainty-detector,
     output-auditor, context-grounding (skills)

Marketplace (Claude REPL):
  /plugin marketplace add a-ariff/ariff-claude-plugins
TXT
      plugin_note "ariff-anti-hallucination-suite" "marketplace://a-ariff/ariff-claude-plugins"
      ;;
    *)
      echo "[agentic-hub] unknown recommendation source: $source" >&2
      return 1
      ;;
  esac
}

cmd="${1:-}"
if [ -z "$cmd" ]; then
  usage
  exit 1
fi
shift || true

case "$cmd" in
  doctor)
    echo "[agentic-hub] doctor"
    echo "- project: $PROJECT_ROOT"
    for bin in bash python3 git npx code codex; do
      if command -v "$bin" >/dev/null 2>&1; then
        echo "- $bin: OK"
      else
        echo "- $bin: missing"
      fi
    done
    if [ -f "$MCP_FILE_DEFAULT" ]; then
      echo "- mcp: $MCP_FILE_DEFAULT"
      mcp_list "$MCP_FILE_DEFAULT" || true
    else
      echo "- mcp: missing ($MCP_FILE_DEFAULT)"
    fi
    ;;
  bootstrap)
    target="${1:-$PROJECT_ROOT}"
    bash "$CODEX_DIR/bootstrap.sh" "$target"
    ;;
  intake)
    if [ $# -lt 1 ]; then
      usage
      exit 1
    fi
    bash "$SCRIPT_DIR/agentic-cli.sh" intake "$@"
    ;;
  sync)
    src="${1:-.tmp/repo-intake/reports}"
    bash "$SCRIPT_DIR/agentic-cli.sh" sync "$src"
    ;;
  checkpoint)
    checkpoint_note "$@"
    ;;
  skill)
    sub="${1:-}"
    shift || true
    case "$sub" in
      suggest)
        if [ $# -lt 1 ]; then
          usage
          exit 1
        fi
        bash "$SCRIPT_DIR/skill-navigator.sh" suggest "$@"
        ;;
      list)
        bash "$SCRIPT_DIR/skill-navigator.sh" list "${1:-}"
        ;;
      *)
        usage
        exit 1
        ;;
    esac
    ;;
  mcp)
    sub="${1:-}"
    shift || true
    case "$sub" in
      list)
        mcp_list "${1:-$MCP_FILE_DEFAULT}"
        ;;
      add-http)
        if [ $# -lt 2 ]; then
          usage
          exit 1
        fi
        mcp_add_http "$1" "$2" "${3:-$MCP_FILE_DEFAULT}"
        ;;
      add-stdio)
        if [ $# -lt 2 ]; then
          usage
          exit 1
        fi
        mcp_add_stdio "$@"
        ;;
      preset)
        preset_name="${1:-}"
        case "$preset_name" in
          claude-core)
            connector_preset_claude_core "${2:-$MCP_FILE_DEFAULT}"
            ;;
          *)
            echo "[agentic-hub] unknown preset: $preset_name" >&2
            exit 1
            ;;
        esac
        ;;
      *)
        usage
        exit 1
        ;;
    esac
    ;;
  connector)
    # connector is an alias for MCP operations
    sub="${1:-}"
    shift || true
    case "$sub" in
      list)
        mcp_list "${1:-$MCP_FILE_DEFAULT}"
        ;;
      add-http)
        if [ $# -lt 2 ]; then
          usage
          exit 1
        fi
        mcp_add_http "$1" "$2" "${3:-$MCP_FILE_DEFAULT}"
        ;;
      add-stdio)
        if [ $# -lt 2 ]; then
          usage
          exit 1
        fi
        mcp_add_stdio "$@"
        ;;
      preset)
        preset_name="${1:-}"
        case "$preset_name" in
          claude-core)
            connector_preset_claude_core "${2:-$MCP_FILE_DEFAULT}"
            ;;
          *)
            echo "[agentic-hub] unknown preset: $preset_name" >&2
            exit 1
            ;;
        esac
        ;;
      *)
        usage
        exit 1
        ;;
    esac
    ;;
  plugin)
    sub="${1:-}"
    shift || true
    case "$sub" in
      note)
        if [ $# -lt 2 ]; then
          usage
          exit 1
        fi
        plugin_note "$1" "$2"
        ;;
      import-openclaw)
        if [ $# -lt 1 ]; then
          usage
          exit 1
        fi
        plugin_import_openclaw "$1"
        ;;
      recommend)
        if [ $# -lt 1 ]; then
          usage
          exit 1
        fi
        plugin_recommend "$1"
        ;;
      *)
        usage
        exit 1
        ;;
    esac
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    usage
    exit 1
    ;;
esac
