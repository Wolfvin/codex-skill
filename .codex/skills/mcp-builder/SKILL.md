---
name: mcp-builder
description: Unified MCP integration and MCP server construction workflow. Use when the user wants to connect a new tool/service via MCP, configure connectors, or build a custom MCP server from API contracts with stable schemas and validation gates. Trigger for prompts like "connect to X", "add MCP", "build MCP server", "integrate tool", and "MCP setup".
---

# MCP Builder

Skill gabungan dari `mcp-manager` dan `mcp-server-builder`.

## Merged Sources
- `mcp-manager`
- `mcp-server-builder`

## Mode 1 - Integrate Existing MCP

Gunakan saat user ingin menambah konektor/service baru.

1. Pahami kebutuhan
- Service/tool apa yang diintegrasikan.
- Kapabilitas yang diinginkan (read/write/automation/monitoring).

2. Cari MCP yang tersedia
- Prioritaskan MCP resmi.
- Jika tidak ada, cek opsi komunitas yang kredibel.

3. Install dan konfigurasi
- Tambah server MCP via CLI/config.
- Pastikan konfigurasi konsisten di project.

4. Verifikasi
- Jalankan check bahwa server enabled dan bisa dipakai.

5. Dokumentasi
- Catat konektor baru dan alasan integrasi.

## Mode 2 - Build New MCP Server

Gunakan saat belum ada MCP yang cocok.

1. Contract first
- Mulai dari OpenAPI atau kontrak endpoint eksplisit.

2. Tool schema design
- Nama tool intent-driven dan konsisten.
- Input schema jelas, output/error terstruktur.

3. Scaffold runtime
- Implementasi Python atau TypeScript.

4. Validate
- Cek duplikasi tool, deskripsi kurang jelas, schema lemah.

5. Security and reliability
- Hindari secret di schema.
- Gunakan allowlist host, timeout, rate limit.

6. Versioning
- Perubahan additive untuk kompatibilitas.
- Breaking behavior gunakan tool ID baru.

## Decision Rule

- Jika MCP sudah tersedia dan memenuhi kebutuhan: pakai Mode 1.
- Jika tidak ada atau tidak memadai: pakai Mode 2.

## Output Wajib

- Keputusan mode (integrate/build) + alasan.
- Konfigurasi MCP yang dipasang/dibuat.
- Hasil verifikasi koneksi/tool.
- Catatan risiko + next step.

## Runtime Contract and Preflight Rules

Saat integrasi/build MCP untuk automation workflow:
1. Definisikan lifecycle session/client secara eksplisit (start, status, stop, recovery).
2. Jangan anggap "start sukses" berarti koneksi benar-benar aktif; selalu cek status aktif.
3. Dokumentasikan failure mode utama + wrong/right command pattern.
4. Tegaskan kontrak output tool (contoh: output file vs payload inline) agar tidak disalahgunakan.
5. Bedakan failure komponen:
- session issue (cukup reconnect)
- daemon/runtime process issue (perlu restart service)
- plugin/bridge issue (perlu validasi install/registration)

## Selective Install Lifecycle for MCP Surface

Jika integrasi MCP punya banyak komponen:
1. Plan dulu paket yang dipasang (profile/module/component), jangan pasang semua.
2. Terapkan bertahap dan catat install-state per target environment.
3. Tambahkan doctor check untuk deteksi missing/drift konfigurasi.
4. Tambahkan repair path agar state bisa dipulihkan cepat tanpa reset total.

## Cross-Harness MCP Packaging

Untuk dukungan banyak harness:
- kelola spesifikasi MCP di sumber canonical
- generate/adapt file konfigurasi per harness dari spesifikasi tersebut
- jalankan consistency check berkala agar metadata tool/command tidak drift antar surface
