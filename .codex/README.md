# .codex Portable Bundle

Tujuan: cukup copy folder `.codex/` ke root project baru, lalu trigger `$setup` supaya agent langsung bisa pakai semua skill/tools/config di dalam `.codex`.

## Quick Start (Portable)

1. Copy folder `.codex` ke root project target.
2. Jalankan bootstrap sekali:

```bash
bash .codex/bootstrap.sh
```

Atau di Windows PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .codex/bootstrap.ps1
```

3. Di session agent, cukup bilang:

```text
[$setup](.codex/skills/setup/SKILL.md)
```

## Minimal Trigger Prompt

Untuk dipakai lintas project/session, pakai prompt ini:

```text
pakai $setup, lanjut otomatis sesuai .codex/AGENTS.md + skill-router
```

## Yang Wajib Ada di Bundle

- `.codex/AGENTS.md`
- `.codex/memory/MEMORY.md`
- `.codex/skills/`
- `.codex/tools/`
- `.codex/bootstrap.sh`
- `.codex/bootstrap.ps1`
- `.codex/config.toml`

## Verification Checklist

Setelah bootstrap:

1. `.vscode/mcp.json` terbuat/terupdate.
2. `bash .codex/tools/agentic-hub.sh doctor` berjalan.
3. Skill dapat ditemukan dari `skills/`.
4. Memory hanya memakai `.codex/memory/MEMORY.md`.

## Operating Notes

- Single-file memory policy: gunakan hanya `.codex/memory/MEMORY.md`.
- Untuk routing otomatis non-trivial task: `think` + `skill-router`.
- Untuk gap konteks eksternal: pakai `web-search` (quick mode dulu).

