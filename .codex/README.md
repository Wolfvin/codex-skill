# .codex — Portable AI Dev Environment

Tujuan: copy folder `.codex/` ke project baru, jalankan bootstrap sekali, lalu semua tool inti + skill agentic langsung siap.

## Quick Start

```bash
bash .codex/bootstrap.sh
powershell -ExecutionPolicy Bypass -File .codex/bootstrap.ps1
```

Lalu reload VS Code window.

## Struktur

```text
.codex/
  bootstrap.sh
  bootstrap.ps1
  tools/
    repo-intake-cli.sh
    repo-intake-cli.ps1
    agentic-cli.sh
    agentic-cli.ps1
    agentic-hub.sh
    agentic-hub.ps1
    skill-navigator.sh
    skill-navigator.ps1
  memory/
    akp2i_projects.md
  skills/
    agentic-hub/
    agent-runtime-advanced/
    anti-hallucination-suite/
    bootstrap/
    cc-plugins-ops/
    checkpoint/
    code-simplifier/
    debug-tauri/
    delivery-pipeline/
    frontend-design/
    mcp-manager/
    mcp-server-builder/
    official-skill-sync/
    pr-review-expert/
    repo-intake/
    skill-router/
    skills-search/
    tagged-work-intake/
    tech-debt-tracker/
    user_propt/
```

## Agentic Coding Stack (Import dari `alirezarezvani/claude-skills`)

Skill yang difokuskan untuk performa coding agentic:

- `pr-review-expert`: review PR berbasis risiko (security/contracts/test delta)
- `tech-debt-tracker`: inventory + prioritas debt berbasis dampak
- `mcp-server-builder`: desain MCP server dari kontrak API
- `repo-intake`: canonical intake + onboarding (`external-intake` dan `internal-onboarding`)
- `official-skill-sync`: sinkronisasi skill terkurasi resmi dari `openai/skills`
- `agentic-hub`: canonical command center untuk intake + connector/plugin ops
- `skill-router`: routing prompt -> skill set paling relevan
- `agent-runtime-advanced`: dependency graph + compaction + worker loop + recovery
- `delivery-pipeline`: canonical flow (mode `spec`, `rpi`, `delivery`)
- `tagged-work-intake`: trigger `[]` tag menjadi mode kerja terstruktur
- `anti-hallucination-suite`: canonical verification suite + behavioral guardrails
- `skills-search`: search/install skill Claude Code via CCPM registry
- `cc-plugins-ops`: marketplace + plugin ops untuk Claude Code (cc-plugins)

## Repo Intake CLI (Agent Comfort Mode)

Saat kamu kirim link repo/GitHub, agent bisa pakai CLI ini untuk intake cepat:

```bash
bash .codex/tools/repo-intake-cli.sh <repo-url>
```

Contoh:

```bash
bash .codex/tools/repo-intake-cli.sh https://github.com/openai/skills
```

Output:
- menghasilkan laporan intake mentah di `.codex/memory/repo_intake_report_*.md` (hapus setelah kurasi, memory policy single-file)
- clone temporary otomatis dihapus (pakai `--keep` kalau mau disimpan)

## Agentic CLI (Multi-Repo Orchestrator)

`agentic-cli` sekarang alias compatibility. Canonical command center: `agentic-hub`.
Gunakan ini jika butuh command lama untuk intake beberapa repo sekaligus + auto ringkas:

```bash
bash .codex/tools/agentic-cli.sh intake <repo-url> [repo-url ...]
```

Sync report jika `.codex` sempat tidak writable:

```bash
bash .codex/tools/agentic-cli.sh sync .tmp/repo-intake/reports
```

## Agentic Hub CLI (All-in-One)

CLI utama supaya workflow agentic lebih nyaman, termasuk style plugin/connector:

```bash
bash .codex/tools/agentic-hub.sh doctor
bash .codex/tools/agentic-hub.sh intake <repo-url|local-path> [repo-url|local-path ...]
bash .codex/tools/agentic-hub.sh skill suggest "<prompt text>"
bash .codex/tools/agentic-hub.sh skill list [category]
bash .codex/tools/agentic-hub.sh mcp list
bash .codex/tools/agentic-hub.sh connector add-http <name> <url>
bash .codex/tools/agentic-hub.sh connector add-stdio <name> <command> [arg ...]
bash .codex/tools/agentic-hub.sh connector preset claude-core
bash .codex/tools/agentic-hub.sh plugin import-openclaw <openclaw.plugin.json>
bash .codex/tools/agentic-hub.sh plugin recommend buildwithclaude
bash .codex/tools/agentic-hub.sh plugin recommend ariff
bash .codex/tools/agentic-hub.sh plugin note <name> <source>
bash .codex/tools/agentic-hub.sh checkpoint --goal "<...>" --done "<...>" --next "<...>" --blockers "<...>"
```

## Skill Navigation

Untuk menemukan skill paling tepat dari prompt user:

```bash
bash .codex/tools/skill-navigator.sh suggest "<prompt user>"
bash .codex/tools/skill-navigator.sh list
bash .codex/tools/skill-navigator.sh list quality
```

Catalog navigasi:
- `.codex/skills/_navigation/skill-map.tsv`

Contoh:

```bash
bash .codex/tools/agentic-hub.sh connector add-http openaiDeveloperDocs https://developers.openai.com/mcp
bash .codex/tools/agentic-hub.sh connector add-stdio codeReviewGraph .tools/code-review-graph-venv/bin/code-review-graph serve
```

## Workflow Templates (Archon-style)

Template workflow deterministik untuk loop plan -> implement -> verify:

```text
.codex/tools/workflows/plan-implement-verify.yaml
.codex/tools/workflows/idea-to-pr.yaml
```

## Source Hygiene

- Jangan mengimpor code dari repo yang berisi source leak atau hak cipta meragukan.
- Ambil hanya pola arsitektur dan workflow yang jelas legal dan documented.

## Official Skills Source

Referensi resmi skill Codex:

- https://github.com/openai/skills

Prinsip pakai:
- Pakai curated skill seperlunya (jangan bulk install).
- Dahulukan skill yang langsung meningkatkan quality coding agentic.
- Kalau ada overlap dengan skill lokal, pilih satu yang jadi canonical.

## Yang Disetup Otomatis

- VS Code extensions (best effort):
  - `openai.chatgpt`
  - `eamodio.gitlens`
  - `dbaeumer.vscode-eslint`
  - `esbenp.prettier-vscode`
  - `usernamehw.errorlens`
  - Copilot dicoba sebagai optional
- `code-review-graph` ke virtualenv lokal project: `.tools/code-review-graph-venv`
- Project MCP config di `.vscode/mcp.json`:
  - `context7`
  - `openaiDeveloperDocs`
  - `filesystem`
  - `git`
  - `fetch`
  - `time`
  - `memory`
  - `tauri`
  - `codeReviewGraph`
- Link skill project ke `~/.codex/skills` (best effort)
- Inisialisasi `.codex/memory/akp2i_projects.md` (name, stack, tanggal)

## Rule Docs-First (Context7)

Tambahkan preferensi ini di instruksi proyek (`AGENTS.md`) kalau mau selalu docs-first:

```txt
Always use Context7 MCP when I need library/API documentation, code generation,
setup, or configuration steps before implementation.
```

## Cara Pakai `code-review-graph`

Binary ada di:

```bash
.tools/code-review-graph-venv/bin/code-review-graph
```

Command umum:

```bash
.tools/code-review-graph-venv/bin/code-review-graph --version
.tools/code-review-graph-venv/bin/code-review-graph build
.tools/code-review-graph-venv/bin/code-review-graph status
.tools/code-review-graph-venv/bin/code-review-graph serve
```

Output graph disimpan di:

```bash
.code-review-graph/
```

## Copy ke Project Baru

```bash
cp -r /path/sumber/.codex /path/project-baru/
cd /path/project-baru
bash .codex/bootstrap.sh
powershell -ExecutionPolicy Bypass -File .codex/bootstrap.ps1
```

## Catatan

- Copy `.codex` saja tidak bisa auto-run sendiri (batasan keamanan OS/editor).
- Setup aman dijalankan ulang (idempotent).
- Tiap project punya `.tools` dan `.code-review-graph` sendiri (isolated).

## Windows PowerShell Commands

Gunakan file `.ps1` berikut saat di Windows:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/bootstrap.ps1
powershell -ExecutionPolicy Bypass -File .codex/tools/repo-intake-cli.ps1 https://github.com/openai/skills
powershell -ExecutionPolicy Bypass -File .codex/tools/agentic-cli.ps1 intake https://github.com/openai/skills
powershell -ExecutionPolicy Bypass -File .codex/tools/agentic-hub.ps1 doctor
powershell -ExecutionPolicy Bypass -File .codex/tools/skill-navigator.ps1 suggest auth regression
```


## All Skills (Current)

- agentic-hub
- agent-runtime-advanced
- anti-hallucination-suite
- bootstrap
- cc-plugins-ops
- checkpoint
- code-simplifier
- debug-tauri
- delivery-pipeline
- frontend-design
- mcp-manager
- mcp-server-builder
- official-skill-sync
- pr-review-expert
- repo-intake
- skill-router
- skills-search
- tagged-work-intake
- tech-debt-tracker
- user_propt

