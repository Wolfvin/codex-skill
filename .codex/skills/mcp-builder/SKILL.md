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

### Memory MCP Integration Profile

Untuk `@modelcontextprotocol/server-memory` gunakan baseline ini:
1. stdio command: `npx -y @modelcontextprotocol/server-memory`
2. verifikasi server terdaftar dan bisa dipanggil sebelum workflow utama
3. validasi output memory read/write sesuai kontrak tool
4. jika gagal konek: cek command path, session status, lalu restart komponen yang relevan

### Lightpanda MCP Integration Profile

Untuk Lightpanda MCP:
1. command: `<path-ke-lightpanda>`
2. args: `["mcp"]`
3. verifikasi tool terdaftar dan handshake berhasil
4. bila perlu mode CDP, jalankan `lightpanda serve --host 127.0.0.1 --port 9222`
5. validasi readiness cepat via:
```bash
bash .codex/skills/setup/scripts/browser-preflight.sh
```

### Tauri MCP Integration Profile

Untuk `tauri-mcp-server`:
1. gunakan server yang sesuai versi Tauri project (`v2` prioritas untuk workspace ini)
2. validasi handshake dan daftar tool minimal yang dibutuhkan sebelum eksekusi utama
3. cek kompatibilitas plugin/IPC bridge agar tool contract tetap stabil
4. jika handshake gagal, fallback ke mode non-MCP dan keluarkan `validation_status: fail`
5. route ke `tauri-inject` untuk rekomendasi template/plugin bila scope masih ambigu

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
- Untuk task non-trivial, jalankan `think` dulu agar keputusan `skill-only` vs `tool+skill` vs `MCP integrate/build` tidak spekulatif.

## Boundary Model (Command vs Tool vs Service)

Saat mendesain integrasi MCP, bedakan surface secara tegas:
1. `command_layer`: command setup/ops yang dijalankan operator
2. `tool_layer`: kontrak MCP tool (schema input/output)
3. `service_layer`: adapter runtime/API di belakang tool

Aturan:
- perubahan satu layer tidak boleh diam-diam mengubah layer lain tanpa kontrak
- jika ada coupling lintas layer, laporkan sebagai `contract_warnings`

Composition-first rule:
- sebelum build surface baru, cek apakah kebutuhan bisa dicapai dengan compose/extend surface existing + middleware contract.

## Surface Decision Matrix (MCP vs Daemon vs Skill-Only)

Gunakan matrix ini sebelum implementasi:
1. `MCP` jika butuh tool-call contract lintas agent dan interface stabil.
2. `local daemon/proxy` jika target utama adalah penghematan token runtime lintas call.
3. `skill-only` jika workflow cukup instruksional tanpa runtime service baru.

Wajib laporkan:
- `surface_choice`
- `why_not_other_surfaces`
- `install_verify_steps`
- `failure_fallback`

## Output Wajib

- Keputusan mode (integrate/build) + alasan.
- Konfigurasi MCP yang dipasang/dibuat.
- Hasil verifikasi koneksi/tool.
- Catatan risiko + next step.

Schema output validate MCP (deterministik):
1. `mode` (`integrate`|`build`)
2. `target_service`
3. `config_summary`
4. `validation_status` (`pass`|`fail`|`blocked`)
5. `failure_reason` (jika tidak pass)
6. `next_action`
7. `provider_adapter`
8. `toolkits_selected[]`
9. `callable_probe_status` (`pass`|`fail`)

Step-gating integrasi:
1. `config_applied` (`yes`|`no`)
2. `handshake_status` (`pass`|`fail`)
3. `schema_check` (`pass`|`fail`)
4. `callable_probe_status` (`pass`|`fail`)
5. lanjut tahap berikutnya hanya jika seluruh gate sebelumnya `pass`

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

## Sampling + Tools Capability Gate

Untuk MCP yang mendukung sampling dengan tools:
1. cek capability server/client untuk `sampling`
2. cek dukungan `tools` dan `toolChoice`
3. jika capability tidak lengkap, set `validation_status: blocked`
4. untuk request berisiko, tandai kebutuhan `human_approval_required: yes`

## ACI Quality Gate (Agent-Computer Interface)

Sebelum finalize integrasi MCP, nilai kualitas interface agent-komputer:
1. `browse_quality`: agent bisa menelusuri context dengan stabil
2. `edit_quality`: perubahan file/tool-call dapat diaudit dan aman diulang
3. `exec_quality`: eksekusi command/tool punya feedback jelas
4. `verify_quality`: hasil dapat diverifikasi deterministik

Jika salah satu `quality` lemah:
- status `validation_status: blocked`
- lanjutkan hanya setelah perbaikan kontrak interface

## Integration Contract Template

Setiap integrasi MCP baru wajib mendefinisikan:
1. input schema minimum
2. output schema minimum
3. trace/observation id (jika tersedia)
4. failure taxonomy (`auth`|`transport`|`schema`|`runtime`)

Tambahkan field reliability untuk operasi yang bisa dipanggil ulang:
5. `retry_policy`
6. `idempotency_level` (`strong`|`partial`|`none`)

## Transport Capability Matrix (Arcade-style MCP)

Saat memilih transport server MCP, isi matrix ini:
1. `transport_stdio`:
- support local auth/secret injection: `yes`
- cocok untuk desktop/CLI harness
2. `transport_http`:
- support local auth/secret injection: `limited`
- untuk auth/secret tool biasanya butuh mode deploy/managed server
3. jika kebutuhan tool adalah `requires_auth` atau `requires_secrets`, prioritaskan stdio atau managed deployment yang mendukung

Output tambahan wajib:
- `selected_transport` (`stdio`|`http`)
- `auth_secret_support` (`full`|`limited`|`none`)
- `deployment_requirement` (`none`|`managed_required`)

## Deprecated Runtime Guard (Team MCP Legacy)

Jika menemukan runtime team MCP legacy yang deprecated:
1. tandai `validation_status: blocked`
2. arahkan ke jalur pengganti berbasis CLI/team canonical
3. simpan mode legacy sebagai `compat_only` (manual opt-in), bukan default deployment

## Retry-Safe Tooling Contract

Untuk tool/integrasi yang mungkin dieksekusi ulang:
1. pastikan operasi write punya idempotency strategy atau compensating action
2. jika tidak idempotent, tandai sebagai non-retryable dengan guard eksplisit
3. jangan aktifkan retry default untuk operasi yang efek sampingnya tidak aman

## Safe Rollout Gate (Saat Refactor Menyentuh MCP Integration)

Jika refactor mengubah kode integrasi MCP/tooling:
1. lakukan perubahan bertahap per fase kecil, bukan sekaligus
2. verifikasi kontrak tool setelah tiap fase (schema, argumen, output shape)
3. jika phase check gagal, rollback fase terakhir dan stop rollout
4. lanjut fase berikutnya hanya setelah gate sebelumnya hijau

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

## Agent-Assisted Integration Contract

Untuk setup MCP yang dieksekusi agent (IDE/copilot/agent mode):
1. preflight dependency wajib lolos dulu (runtime, package manager, auth env var)
2. cek konflik SDK lama dan bersihkan sebelum install baru
3. gunakan config snippet deterministik (command/args/env) lalu verifikasi server benar-benar aktif
4. jalankan post-check minimal:
- server terdaftar
- minimal 1 tool callable
- error path terdokumentasi
5. jika salah satu gagal, status `validation_status: fail` dan jangan lanjut ke fase implementasi

## Composio / Rube Integration Profile

Untuk stack Composio SDK + Rube MCP:
1. tetapkan `provider_adapter` sesuai framework runtime (OpenAI/Anthropic/LangChain/LangGraph/dll).
2. pilih `toolkits[]` minimum yang benar-benar dibutuhkan task (least privilege), jangan load semua toolkit.
3. jika memakai Rube sebagai MCP surface:
- verifikasi server aktif
- verifikasi auth/connected account siap
- verifikasi minimal 1 action/tool dari toolkit target callable
4. jika salah satu verifikasi gagal, fallback ke mode non-MCP dan catat `failure_reason`.

Adapter matrix minimum yang wajib diisi di output:
- `provider_adapter`
- `toolkits_selected[]`
- `auth_state` (`ready|missing|expired`)
- `callable_probe_status` (`pass|fail`)
