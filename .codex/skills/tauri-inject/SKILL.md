---
name: tauri-inject
description: Tauri domain context injector for desktop/mobile app tasks. Use to inject high-signal Tauri setup, templates, plugins, IPC, and integration constraints before implementation.
---

# Tauri Inject

Skill ini menyuntikkan konteks domain Tauri agar implementasi tidak trial-and-error.

## Trigger
- Task menyebut Tauri desktop/mobile app.
- Task butuh pilihan template/plugin/integration Tauri.
- Task butuh guardrail IPC/typesafe bridge/update/security pada Tauri.

## Workflow

1. Klasifikasikan kebutuhan:
- bootstrap/template
- plugin capability
- integration/IPC
- delivery/update/security
2. Prioritaskan sumber official Tauri dulu, lalu curated source kredibel.
3. Tetapkan rekomendasi minimum viable stack:
- 1 template
- 1-3 plugin relevan
- 1 strategy IPC/typesafety
4. Validasi risiko operasional:
- version compatibility
- permission/security surface
- update strategy
5. Jika perlu tool-call integration, route ke `mcp-builder` untuk profil `tauri-mcp-server`.

## Output Wajib
- `tauri_scope`
- `recommended_template`
- `recommended_plugins[]`
- `integration_notes`
- `compatibility_risks`
- `next_step`
