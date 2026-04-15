# Skill Mapping - Workspace `D:\Workspace\projects\Skill`

## Ringkasan
- Total skill terdeteksi: 17
- Skill modern (`SKILL.md`): 17 (unique name)
- Skill legacy (`AGENTS/SKILLS/*.md`): 0
- Catatan: single source of truth modern skill ada di `D:\Workspace\projects\Skill\.codex\skills`.

## A. Skill Modern (SKILL.md)
1. `checkpoint` -> Skill gabungan memory checkpoint + codebase onboarding untuk simpan learnings sekaligus peta engineering cepat.
2. `command-center` -> Skill gabungan command center dari `agentic-cli` + `agentic-hub` untuk bootstrap, intake, MCP connector, dan plugin notes.
3. `debug-n-check` -> Skill gabungan `debug-console` + `skill_ps1` + `focused-fix` dengan 2 mode anak: `console` (frontend/js) dan `terminal` (backend), trigger saat plan selesai check atau saat bug ditemukan.
4. `evolve` -> Skill gabungan `repo-intake` + `official-skill-sync` + `cc-plugins-ops` + `skill-consolidator` untuk evolusi ekosistem skill.
5. `frontend-inject` -> Skill merge frontend-design + design-md-inject untuk injeksi kontrak desain UI (`DESIGN.md`) plus fallback brief.
6. `github` -> Skill operasional GitHub end-to-end dengan guardrail sync/no-merge tak sengaja dan alur commit/push terkontrol.
7. `mcp-builder` -> Skill gabungan `mcp-manager` + `mcp-server-builder` untuk integrasi MCP existing atau build server MCP baru.
8. `review` -> Skill gabungan `code-simplifier` + `pr-review-expert` + `tech-debt-tracker` untuk simplifikasi aman, review PR high-signal, dan prioritas debt.
9. `setup` -> Skill gabungan `bootstrap` + `skill_sop` untuk setup environment sekaligus builder SOP operasional run/stop/check/debug.
10. `skill-router` -> Skill gabungan router + skills-search untuk memilih kombinasi skill (1..N sesuai kompleksitas smart-plan) dan manajemen discovery/install.
11. `smart-plan` -> Skill gabungan planning + delivery pipeline + verification + intake + framework context-plan-execute-verify-finish.
12. `intelect-inject` -> Skill parent context-injection dengan fallback `web-search`; anak aktif: `frontend-inject`, `typescript-inject`, `tauri-inject`, `web-search`.
13. `web-search` -> Skill akuisisi konteks eksternal berbasis browse/search web (Google/search tool) untuk mengisi kekurangan konteks sebelum planning/eksekusi.
14. `typescript-inject` -> Skill injeksi konteks TypeScript/JavaScript untuk diagnostics, impact symbol/reference, dan refactor-safety gate.
15. `think` -> Skill gate berpikir terstruktur (judgment -> decision -> generation) sebelum routing/planning/eksekusi agar minim halusinasi dan tepat memilih skill/tool.
16. `token-optimizer` -> Skill audit tekanan token + compaction survival + benchmark gate agar hemat token tanpa menurunkan kualitas output.
17. `tauri-inject` -> Skill injeksi konteks domain Tauri (template/plugin/integration/compatibility) sebelum implementasi.

## B. Skill Legacy (AGENTS/SKILLS)
Tidak ada.

## C. Lokasi Inventori
- `D:\Workspace\projects\Skill\.codex\skills\`
- `D:\Workspace\projects\Skill\AGENTS\SKILLS\`
