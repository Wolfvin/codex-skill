# Skill Mapping - Workspace `D:\Workspace\projects\Skill`

## Ringkasan
- Total skill terdeteksi: 11
- Skill modern (`SKILL.md`): 11 (unique name)
- Skill legacy (`AGENTS/SKILLS/*.md`): 0
- Catatan: single source of truth modern skill ada di `D:\Workspace\projects\Skill\.codex\skills`.

## A. Skill Modern (SKILL.md)
1. `checkpoint` -> Skill gabungan memory checkpoint + codebase onboarding untuk simpan learnings sekaligus peta engineering cepat.
2. `command-center` -> Skill gabungan command center dari `agentic-cli` + `agentic-hub` untuk bootstrap, intake, MCP connector, dan plugin notes.
3. `debug-n-check` -> Skill gabungan `debug-console` + `skill_ps1` + `focused-fix` dengan 2 mode anak: `console` (frontend/js) dan `terminal` (backend), trigger saat plan selesai check atau saat bug ditemukan.
4. `evolve` -> Skill gabungan `repo-intake` + `official-skill-sync` + `cc-plugins-ops` + `skill-consolidator` untuk evolusi ekosistem skill.
5. `frontend-design` -> Bangun UI frontend berkualitas produksi dengan kualitas desain tinggi dan non-generic.
6. `mcp-builder` -> Skill gabungan `mcp-manager` + `mcp-server-builder` untuk integrasi MCP existing atau build server MCP baru.
7. `review` -> Skill gabungan `code-simplifier` + `pr-review-expert` + `tech-debt-tracker` untuk simplifikasi aman, review PR high-signal, dan prioritas debt.
8. `setup` -> Skill gabungan `bootstrap` + `skill_sop` untuk setup environment sekaligus builder SOP operasional run/stop/check/debug.
9. `skill-router` -> Skill gabungan router + skills-search untuk memilih kombinasi skill (1..N sesuai kompleksitas smart-plan) dan manajemen discovery/install.
10. `smart-plan` -> Skill gabungan planning + delivery pipeline + verification + intake + framework context-plan-execute-verify-finish.
11. `intelect_inject` -> Skill parent context-injection dengan 2 anak (`frontend-design`, `typescript_inject`) untuk membantu smart-plan saat butuh konteks implementasi tambahan.

## B. Skill Legacy (AGENTS/SKILLS)
Tidak ada.

## C. Lokasi Inventori
- `D:\Workspace\projects\Skill\.codex\skills\`
- `D:\Workspace\projects\Skill\AGENTS\SKILLS\`
