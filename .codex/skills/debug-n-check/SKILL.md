---
name: debug-n-check
description: Unified debug and verification workflow for frontend and backend issues. Use after plan completion for validation, or immediately when user reports a bug. Combines console loop (frontend/js/ui) and terminal loop (backend/api/runtime) with evidence-first iteration.
---

# Debug-n-Check

Skill gabungan dari:
- `debug-console`
- `skill_ps1`
- `focused-fix`

## Trigger Utama
1. Setelah sebuah plan selesai dan harus check.
2. Saat user menemukan bug.

## Anak Skill / Mode

### 1) `console`
Gunakan jika issue dominan di frontend/js/ui.

Workflow:
1. capture evidence (screenshot/DOM/console log)
2. reproduce bug dengan langkah minimum
3. apply fix secara surgical
4. verify per iteration (maks 5 loop)
5. laporkan pass/fail + delta visual/behavior

Tambahan untuk TS/JS:
- pakai signal tooling (`typescript-lsp`) untuk cek:
- diagnostics/type error cepat
- symbol/reference impact setelah perubahan
- indikasi refactor break sebelum lanjut iterasi berikutnya

Output minimal:
- changed files
- screenshot/log evidence
- iteration count
- remaining risks

### 2) `terminal`
Gunakan jika issue dominan di backend/api/runtime.

Workflow:
1. preflight health
2. run debug cycle script (health, GET/POST, verify, cleanup)
3. isolate root cause (dependency/contract/logic/integration)
4. fix bertahap + retest
5. simpulkan status dan blocker

Output minimal:
- command yang dijalankan
- hasil health/check/test
- root cause summary
- next action

## Routing Rule
- Kalau bug di UI/interaction -> mode `console`.
- Kalau bug di API/server/process -> mode `terminal`.
- Kalau mixed issue -> mulai `terminal` (stabilkan backend), lalu `console`.

## Guardrails
- Evidence first, no blind fix.
- One issue at a time.
- No unrelated refactor.
- Stop and escalate jika setelah 5 iterasi belum stabil.
