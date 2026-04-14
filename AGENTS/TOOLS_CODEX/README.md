# TOOLS_CODEX - Debug Toolkit Index

Tujuan: Kumpulan tool debug (PS1/MJS) agar cepat memilih tanpa membaca isi file di sesi berikutnya.

## Index

### A. Backend / API Health & Gate
- `backend-cargo.ps1`
  - Manfaat: build/run backend dengan env + data dir terkontrol.
- `server-port-diag.ps1`
  - Manfaat: diagnosa cepat port listen (PID/port) + probe HTTP 127.0.0.1/LAN.
- `env-preprod-check.ps1`
  - Manfaat: cek env wajib, data dir layout, health, dan checklist preprod.
- `run-debug-cycle.ps1`
  - Manfaat: cycle E2E (health, POST, verifikasi, cleanup) standar.
- `run-phase-e3-gate.ps1`
  - Manfaat: gate E3 (backend stability) + log ringkas.
- `run-phase-f5-gate.ps1`
  - Manfaat: gate F5 (online/offline/recovery) otomatis.
- `run-phase-g5-write-gate.ps1`
  - Manfaat: gate write?path (PATCH/DELETE) untuk deteksi crash.
- `run-phase-g6-ingest-gate.ps1`
  - Manfaat: gate ingest internal (files_index related).
- `run-api-coverage-smoke.ps1`
  - Manfaat: smoke test coverage API (auth/session, devices, anggota, peers, ops) dengan report OK/FAIL/SKIP.
- `waiting-room-status.ps1`
  - Manfaat: cek status `waiting_room.db` (count, retry, detail queue). Butuh `duckdb` (direkomendasikan) atau `sqlite3`.
- `run-waiting-room-e2e.ps1`
  - Manfaat: trigger bootstrap allowlist + polling waiting_room sampai clear (verifikasi retry).
- `run-server-monitor-auth-diag.ps1`
  - Manfaat: diagnosa 401/403 pada endpoint Server Monitor (identity conflicts + slot add) dengan header auth.

### B. Anggota / Data Integrity
- `tools-anggota-render.ps1`
  - Manfaat: render/seed anggota untuk debugging UI anggota.
- `debug-anggota-rootcause.ps1`
  - Manfaat: root cause anggota tidak render (cache, DOM, server).
- `debug-anggota-patch-crash-loop.ps1`
  - Manfaat: loop PATCH untuk reproduksi crash server.
- `cleanup-f5-seeds.ps1`
  - Manfaat: soft cleanup (PATCH nonaktif) + fallback delete data seed.

### C. Node Simulation / Sync
- `node-sim-lib.ps1`
  - Manfaat: helper start/stop node, health, peers, sync.
- `node-sim-start.ps1`
  - Manfaat: start multi?node lokal (port + UDP stride).
- `node-sim-stop.ps1`
  - Manfaat: stop node berdasarkan pid/port/udp.
- `node-sim-healthcheck.ps1`
  - Manfaat: health + restart check node.
- `node-sim-crash-diag.ps1`
  - Manfaat: diagnosa crash node + tail log.
- `node-sim-sync-diag.ps1`
  - Manfaat: ringkas sync/index + anggota count antar node.
- `run-node-sim.ps1`
  - Manfaat: simulasi penuh (start -> seed -> sync -> failover -> cleanup).
- `run-node-sim-diag.ps1`
  - Manfaat: diag cepat PASS/FAIL (health + peers + sync).

### D. Dashboard / UI Panels
- `run-dashboard-panels-smoke.ps1`
  - Manfaat: smoke test endpoint dashboard panels.
- `diagnose-ui-data.ps1`
  - Manfaat: ringkas status data UI dari API/cache.

### E. Frontend/API Smoke
- `frontend-api-smoke.mjs`
  - Manfaat: smoke test API via node (GET/POST/verify/cleanup).
- `run-frontend-api-smoke.ps1`
  - Manfaat: wrapper PS1 untuk menjalankan smoke MJS.

### F. Window/Titlebar Debug
- `trigger-titlebar.ps1`
  - Manfaat: generate snippet DevTools untuk trigger tombol window (min/max/close) + state debug.

### G. Console Snippets (DevTools)
- `snippets/titlebar-test-snippet.js`
  - Manfaat: cek binding tombol titlebar, state maximize, dan panggil Tauri window API langsung.

### H. Misc / Utility
- `tools.ps1`
  - Manfaat: utility tasks (legacy; update encoding/version index).

## Cara pakai umum
- Jalankan PS1:
  `powershell -ExecutionPolicy Bypass -File .\AGENTS\TOOLS_CODEX\<tool>.ps1`
- Untuk tool snippet UI: buka DevTools Console, paste snippet dari folder `snippets/`, lalu kirim output log.

## Catatan
- Semua tool di sini fokus **debug** dan **validasi**.
- Gunakan BaseUrl/Port yang sesuai environment.
