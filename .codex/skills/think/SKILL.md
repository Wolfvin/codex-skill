---
name: think
description: Deliberate reasoning gate for non-trivial tasks. Use before planning/routing/execution to reduce hallucination risk, detect context gaps, and choose the minimal correct next action.
---

# Think

Skill ini adalah gate berpikir terstruktur sebelum aksi.
Tujuan utama: pilih aksi yang tepat, bukan cepat menulis output.

## Trigger

Gunakan `think` ketika:
- task non-trivial, ambigu, atau high-risk
- perlu memilih skill/tool yang paling tepat
- ada kemungkinan konteks kurang atau sumber belum cukup
- ada risiko halusinasi atau over-claim

## Core Contract

Sebelum eksekusi, lakukan urutan ini:
1. `judgment`: nilai fakta, constraint, risiko, dan gap konteks.
2. `decision`: pilih 1 aksi terbaik (skill mana, tool mana, atau perlu cari konteks dulu).
3. `generation`: baru hasilkan plan/patch/output setelah decision jelas.

Larangan:
- jangan lompat ke generation tanpa judgment + decision
- jangan klaim fakta tanpa sumber/evidence yang bisa diverifikasi
- jangan over-answer di luar scope user
- jangan simpan chain-of-thought mentah ke memory

Token discipline:
- jawab seperlunya, struktur > narasi
- gunakan prompt sesingkat mungkin yang tetap cukup untuk aksi berikutnya

## Permission Checkpoint Gate

Sebelum generation untuk aksi berisiko, tetapkan permission lane:
1. `safe_read`: baca/search/analyze tanpa efek samping
2. `controlled_write`: edit file/konfigurasi dengan boundary scope jelas
3. `elevated_ops`: network/run command sensitif/operasi release

Aturan:
- jika lane belum ditentukan, tahan generation
- jika lane bergeser naik di tengah task, lakukan decision ulang singkat

## Context Sufficiency Gate

Checklist minimum sebelum lanjut:
1. objective user jelas
2. batas scope jelas
3. input teknis penting tersedia
4. sumber fakta cukup untuk klaim kritis

Jika salah satu gagal:
- route ke `intelect-inject`
- fallback ke `web-search` bila sub-skill domain belum cukup
- tandai status `blocked_by_context` sampai konteks memadai

Pre-hydration check:
- cek apakah `AGENTS.md` dan thread/issue context utama sudah dipakai
- jika belum, treat as context gap dan tahan decision final

## Uncertainty and Abstain Policy (Wajib)

Saat confidence rendah atau source bertentangan:
1. nyatakan ketidakpastian secara eksplisit
2. jangan beri klaim final seolah pasti benar
3. route ke `web-search` untuk melengkapi konteks
4. bila tetap belum cukup, jawab `unknown_yet` + langkah verifikasi berikutnya

## Evidence Ladder (Wajib)

Sebelum menyimpulkan, beri level evidence:
1. `L1_official`: dokumentasi resmi / paper primer / source code utama
2. `L2_primary`: repositori atau artikel teknis kredibel
3. `L3_secondary`: opini/ringkasan non-primer

Aturan:
- klaim kritis harus minimal `L1_official` atau `L2_primary`
- jika hanya `L3_secondary`, tandai `uncertainty: high`
- jika tidak ada evidence memadai, jangan lanjut ke final claim

## Skill/Tool Selection Rule

Gunakan rule ini secara deterministik:
1. jika task operasional sederhana -> skill tunggal paling relevan
2. jika task kompleks multi-fase -> `smart-plan` + skill domain
3. jika butuh data eksternal terbaru -> `web-search` dengan `time_window: last_30_days`
4. jika butuh workflow deterministik berulang -> pertimbangkan `tool+skill`
5. jika MCP sudah memadai -> integrasi MCP, bukan bangun ulang tool baru

Decision-owner gate:
- sebelum generation, tentukan owner keputusan (`product|design|engineering|dx|security|release`)
- jika owner belum jelas, tahan generation dan minta klarifikasi ringkas

Jika task butuh freshness tinggi (news/trend/perubahan cepat):
- jangan lanjut decision final sebelum web-search selesai dengan sumber bertanggal

Tool-scope lock:
1. tetapkan `allowed_tools[]` minimum sebelum generation
2. jangan menambah tool baru di tengah langkah tanpa alasan eksplisit
3. jika scope tool melebar, ulangi decision singkat dulu

Surface matrix (agent runtime):
1. `cli_surface`: untuk tugas cepat, command-driven, deterministik
2. `sdk_surface`: untuk orkestrasi terprogram/reusable
3. `gui_surface`: untuk observability interaktif/handoff manusia

Aturan:
- pilih satu surface utama per fase
- jangan campur banyak surface tanpa `surface_handoff` yang jelas

## Simple Loop Bias

Untuk mengurangi drift pada task panjang:
1. prefer loop linear: `observe -> decide -> act -> verify`
2. simpan aksi per langkah sekecil mungkin
3. jika langkah gagal, ulang dari `observe` (bukan lompat ke solusi besar)

## MCP Sampling Human Gate

Jika decision melibatkan MCP sampling/tools request:
1. cek capability `sampling` + `tools` tersedia
2. tandai risiko request (`low|medium|high`)
3. untuk `medium|high`, wajib ada human approval gate sebelum generation final

## Toolkit Least-Privilege Gate

Jika decision melibatkan tool-platform aggregator (contoh Composio):
1. pilih toolkit minimum sesuai objective task
2. jangan load seluruh toolkit hanya karena tersedia
3. validasi provider adapter cocok dengan framework runtime aktif
4. jika auth/toolkit readiness belum pasti, set `knowledge_state: unknown_yet` dan tahan decision final

## Curated-List Disambiguation Gate

Jika input berasal dari curated index/list besar:
1. treat list sebagai discovery surface, bukan evidence final
2. pilih kandidat minimum yang relevan (top-N) lalu validasi ke sumber primer
3. hindari keputusan create_tool/create_skill sebelum evidence primer cukup
4. jika ranking kandidat ambigu, set `uncertainty: high` dan minta 1 klarifikasi fokus

## Operator Surface Decision Gate

Sebelum memilih command/tool, cek dulu:
1. apakah ini `default delivery flow`?
2. atau `operator/troubleshooting flow`?

Rule:
- default flow: pilih jalur skill/workflow utama
- operator flow: pilih doctor/hud/inspect surface yang sempit
- jangan arahkan user ke operator surface jika objective normal execution sudah cukup

## Post-Generation Self-Check

Sebelum output final:
1. cek tiap klaim penting punya evidence level
2. cek output tetap dalam scope user
3. cek apakah ada gap konteks yang belum ditutup
4. jika ada mismatch, turunkan confidence dan route `web-search`

Tambahan check:
5. jika ada konflik antar sumber, tampilkan dua sisi dengan atribusi
6. jika sumber kunci kosong, set `knowledge_state: unknown_yet`

## Compaction Drift Check

Jika sesi baru selesai compaction:
1. cek term/domain penting masih ada
2. cek constraint user tidak hilang
3. jika ada indikasi drift, set `uncertainty: high` dan `knowledge_state: unknown_yet`
4. route ke `checkpoint` untuk recovery context sebelum lanjut

## Memory Evidence Sufficiency Gate

Sebelum mengandalkan memory sebagai dasar keputusan:
1. cek ada rule memory yang relevan ke objective saat ini
2. cek rule masih didukung evidence terbaru (lokal atau web-search)
3. jika tidak cukup, set `knowledge_state: unknown_yet`
4. tambahkan label `insufficient-memory-evidence` dan route ke `web-search`/source primer

## Subagent Isolation Decision Rule

Untuk task panjang/berisik konteks:
1. jika investigasi membutuhkan banyak read/log yang tidak penting untuk jawaban akhir, spawn subagent
2. subagent mengembalikan ringkasan high-signal saja
3. jangan delegasikan langkah yang langsung memblokir aksi kritis berikutnya

## Proactive Compaction Gate

Sebelum masuk topik baru atau fase besar berikutnya:
1. nilai pressure context dari scope aktif
2. jika pressure tinggi, lakukan compact dulu (`/compact`) lalu lanjut
3. setelah compact, jalankan ulang context sufficiency check singkat

## State-Transition Decision Gate

Untuk workflow stateful (graph/long-running):
1. validasi transisi dari `current_state` ke `next_state` memang legal
2. jika transisi tidak valid, set `knowledge_state: unknown_yet` dan tahan generation
3. jika sesi sempat terputus, pakai `resume_point` sebagai basis decision
4. jangan memaksa lanjut ke state baru tanpa evidence state sebelumnya selesai

## Intervention Signal Gate

Sebelum finalize decision pada workflow panjang:
1. cek sinyal intervensi runtime (stale worker, cost spike, loop tanpa progres)
2. jika sinyal high-risk aktif, tahan generation dan turunkan `confidence`
3. keluarkan `next_step` untuk recovery observability dulu (audit replay/session evidence)

## Complexity Drift Alarm

Untuk task panjang/berconstraint banyak:
1. lakukan checksum ringkas per fase (`objective`, `constraints`, `current_state`, `next_step`)
2. jika checksum berubah tanpa alasan jelas, tandai `drift_risk: high`
3. saat `drift_risk: high`, stop generation dan route ke replan singkat

## Replay Determinism Gate

Untuk keputusan pada workflow durable:
1. pastikan keputusan kompatibel dengan replay state dari event history
2. jika replay outcome tidak konsisten, set `knowledge_state: unknown_yet`
3. tahan generation sampai mismatch determinism diselesaikan

## Invasive Hook Last-Resort Policy

Jika opsi solusi melibatkan hook invasif/testhook:
1. utamakan mocking/dependency injection lebih dulu
2. pilih hook invasif hanya jika dua opsi pertama tidak memadai
3. tandai keputusan dengan `risk: high` dan alasan eksplisit

## Task Chunking Rule

Untuk menjaga performa dan token:
1. pecah task jadi slice kecil dengan output tunggal yang jelas
2. hindari gabung investigasi + implementasi + debug dalam satu langkah besar
3. jika slice terlalu besar, turunkan ke sub-slice sebelum generation

## Thinking Memory Loop

Simpan pembelajaran ringkas ke `.codex/memory/MEMORY.md` (single-file policy):
- `task_pattern`
- `context_gap_detected`
- `search_query_used`
- `evidence_level`
- `decision_taken`
- `failure_mode`
- `reusable_rule`

Gunakan helper script bila perlu:
```bash
bash .codex/skills/think/scripts/think-memory-log.sh \\
  --pattern "<task-pattern>" \\
  --gap "<context-gap>" \\
  --query "<search-query-or-none>" \\
  --evidence "<L1_official|L2_primary|L3_secondary>" \\
  --decision "<decision>" \\
  --failure "<failure-or-none>" \\
  --rule "<reusable-rule>"
```

## Output Wajib

- `judgment_summary`
- `chosen_action`
- `why_not_other_options`
- `context_gap` (jika ada)
- `next_step`
- `confidence` (`high` | `medium` | `low`)
- `uncertainty` (`none` | `low` | `high`)
- `evidence_level` (`L1_official` | `L2_primary` | `L3_secondary` | `insufficient`)
- `knowledge_state` (`known` | `unknown_yet`)

Format harus ringkas, high-signal, tanpa prose dekoratif.
