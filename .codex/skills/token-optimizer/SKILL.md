---
name: token-optimizer
description: Optimize context usage and compaction resilience for long Codex CLI sessions. Use when context is bloated, compaction quality drops, or token costs must be reduced without sacrificing answer quality.
---

# Token Optimizer

Skill ini adalah owner untuk optimasi token, compaction survival, dan quality guard pasca kompresi konteks.

## Trigger

Gunakan `token-optimizer` ketika:
- konteks sesi membengkak dan kualitas mulai turun
- ada indikasi kehilangan konteks setelah compaction
- user minta hemat token lintas call/session
- perlu evaluasi proxy/filter/daemon compression tools

## Mode 1 - Session Audit

1. Ukur sinyal risiko:
- prompt bloat
- duplikasi instruksi
- memory noise
- skill overlap yang tidak dipakai
2. Catat baseline:
- `estimated_token_pressure`
- `critical_terms`
- `active_constraints`
3. Tentukan intervensi minimum yang aman.

Prompt budget cap per fase:
1. tetapkan `phase_prompt_budget` (`tight|balanced|expanded`)
2. default `tight` untuk phase investigasi ringan
3. naikkan budget hanya jika evidence menunjukkan perlu konteks tambahan

## Mode 2 - Compaction Survival

Sebelum compaction:
- buat `pre_compact_snapshot` (objective, constraints, files in-flight, next step)

Sesudah compaction:
- jalankan `post_compact_audit`:
  - `ghost_lexicon`
  - `drift_score` (`low|medium|high`)
  - `behavioral_fingerprint_match`

Jika `drift_score: high`:
- stop finalize
- route ke `checkpoint` + `think`
- recovery konteks dari memory lokal dulu, baru web-search bila perlu

## Three-Layer Compaction Policy (Canonical)

Gunakan urutan ini sebagai default lintas sesi:
1. `micro_compact` (setiap turn): pangkas output tool lama yang tidak lagi dibutuhkan
2. `auto_compact` (threshold): kompres saat tekanan context melewati batas operasional
3. `manual_compact` (phase switch): compact proaktif saat pindah fase besar/topik

Rule kualitas:
- sesudah layer 2/3, wajib audit `ghost_lexicon` + `drift_score`
- jika kualitas turun, rollback ke snapshot ringkas terakhir dan recovery context dulu

## Native Compaction Seam Boundary

Untuk integrasi lintas runtime/hook:
1. jangan asumsikan parity `precompact` antar surface jika seam native belum jelas
2. jika parity belum terbukti, tandai `compaction_quality: warning`
3. wajib gunakan recovery path berbasis checkpoint sebelum lanjut optimize lebih agresif

## Mode 3 - Tooling Path Decision

Pilih surface paling tepat:
1. `proxy/filter` untuk pemotongan token request/response
2. `local daemon compression` untuk optimasi lintas call
3. `persistent memory/codegraph` untuk mengurangi re-explaining codebase
4. `skill-only` jika cukup dengan disiplin context dan routing

Lazy-load policy:
1. load docs/reference hanya saat diperlukan langkah aktif
2. hindari eager-load modul/konteks besar di awal
3. drop context yang sudah selesai diverifikasi agar footprint tetap kecil

## Retrieval Mode Budget Mapping

Untuk skill `web-search`, map mode ke budget:
1. `quick`:
- target latency rendah
- sumber minimum yang cukup untuk next step
2. `default`:
- keseimbangan kualitas vs biaya token
3. `deep`:
- gunakan hanya saat conflict tinggi, query kompleks, atau risk tinggi
- wajib justifikasi biaya token ekstra

Design retrieval compression:
1. untuk konteks UI, simpan output dalam bentuk keputusan ringkas (`style`, `palette`, `typography`, `checklist`)
2. hindari membawa daftar style panjang ke thread aktif
3. simpan katalog panjang di luar jalur reasoning utama bila benar-benar dibutuhkan

## MCP Footprint Minimization

Untuk setiap fase task:
1. audit MCP aktif yang benar-benar diperlukan
2. nonaktifkan/hindari server yang tidak relevan pada fase tersebut
3. validasi tool yang tersisa cukup untuk eksekusi

Gunakan `/mcp` untuk inspeksi cepat tools yang aktif.

## Shell Output Discipline

Utamakan command yang hemat context:
- pakai `git status --short` dibanding default verbose
- pakai `ls` (bukan `ls -la`) kecuali perlu permission detail
- pipe output panjang ke `head`, `tail`, atau filter `rg`
- hindari dump log besar tanpa kebutuhan audit

## Benchmark Gate (Wajib)

Untuk source atau tool dengan klaim efisiensi tinggi:
1. ukur baseline sebelum install
2. ukur setelah enable
3. bandingkan kualitas output (bukan hanya token)
4. adopsi permanen hanya jika:
- token turun, dan
- quality tidak degrade

## Guardrails

- Jangan terima klaim marketing tanpa evidence lokal.
- Jangan kompromi akurasi hanya demi hemat token.
- Jangan menghapus konteks kritis untuk task aktif.

## Output Wajib

- `selected_mode`
- `baseline_summary`
- `intervention_plan`
- `compaction_quality` (`ok|warning|degraded`)
- `recommended_path`
- `benchmark_status` (`pass|fail|skipped`)
- `next_step`
