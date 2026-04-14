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
