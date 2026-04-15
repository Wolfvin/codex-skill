---
name: web-search
description: Web context acquisition skill for ambiguous or low-context tasks. Use when agents need fresh external context, source links, or quick market/library discovery before planning or implementation.
---

# Web Search

Skill ini dipakai untuk mengambil konteks eksternal terbaru sebelum eksekusi.
Skill ini adalah fallback utama saat agent kekurangan konteks domain.

## Efficient Tool Stack (Default)

Gunakan urutan backend ini agar efisien lintas session:
1. `native_search` (default): tool web-search bawaan dengan filter recency/domain + sumber minimum.
2. `metasearch_backend` (opsional): SearXNG/Vane-style aggregator saat butuh recall lebih tinggi tanpa membuka banyak halaman.
3. `deep_research_orchestrator` (opsional): GPT-Researcher/STORM-style hanya untuk mode `deep` berisiko tinggi.

Aturan pemakaian:
- mulai dari backend paling ringan dulu
- escalate backend hanya jika evidence tidak cukup
- jangan pakai deep orchestrator untuk task low-risk

## Curated List Intake Policy

Jika sumber berupa "awesome list"/directory besar:
1. pilih top-N kandidat dulu (default `N=5`) berdasarkan relevansi intent
2. prioritaskan source official/maintainer aktif dibanding listing sekunder
3. jangan langsung adopsi item dari list tanpa cek sumber primer tiap kandidat
4. tandai kandidat yang claim-heavy sebagai `confidence: low` sampai ada bukti primer

## Fast-Moving SDK Recency Guard

Untuk SDK/platform yang berubah cepat:
1. cek branch default/release channel terbaru sebelum ambil rekomendasi final
2. cocokkan versi docs dengan surface install yang disarankan
3. jika ada mismatch branch/docs/package, tandai `conflicts[]` dan turunkan confidence

## Trigger
- Konteks lokal tidak cukup untuk membuat plan yang aman.
- User minta cari referensi/library/tool dari internet.
- `intelect-inject` tidak menemukan sub-skill domain yang cocok.
- `think` menghasilkan `blocked_by_context` atau `unknown_yet`.
- Untuk task UI, dipakai hanya jika design contract lokal dari `frontend-inject` belum cukup.

## Workflow

1. Tentukan query fokus (maksimal spesifik, hindari query terlalu luas).
2. Pilih mode pencarian:
- `quick`: konteks awal cepat, latency rendah, sumber minimal
- `default`: mode seimbang untuk kebanyakan task
- `deep`: recall tinggi untuk topik kompleks/risiko tinggi
Mode selection matrix:
- `quick` -> `native_search`, `max_sources: 3`, `token_budget_class: tight`
- `default` -> `native_search` atau `metasearch_backend`, `max_sources: 5`, `token_budget_class: balanced`
- `deep` -> boleh tambah `deep_research_orchestrator`, `max_sources: 8`, `token_budget_class: expanded`

Tool purpose map:
- `native_search`: discovery cepat + sumber primer minimum
- `metasearch_backend`: perluasan recall jika discovery awal kurang
- `deep_research_orchestrator`: sintesis kompleks high-risk setelah evidence dasar cukup
3. Jika query tentang person/brand/product, lakukan entity handle-resolution dulu:
- cari handle resmi/kanonik (misal akun X, repo resmi, situs resmi)
- gunakan handle/identifier ini untuk query lanjutan
4. Jalankan search/browse tool berbasis web (Google/search tool) untuk menemukan sumber relevan.
5. Terapkan recency gate untuk kebutuhan fresh signal:
- default window: 30 hari terakhir
- hasil tanpa tanggal jelas ditandai dan tidak dipakai untuk klaim kritis
6. Lakukan fusion hasil:
- normalize dan dedupe
- rank sumber paling relevan
- cluster poin yang saling menguatkan
 - terapkan retrieval budget: hanya simpan fakta operasional + source primer
7. Kumpulkan ringkasan high-signal:
- fakta inti
- link sumber
- risiko/ketidakpastian
8. Jika ada konflik sumber, tampilkan dua sisi + atribusi.
9. Kirim konteks hasil pencarian ke `smart-plan` atau agent yang meminta.

Khusus lane UI:
- jika dipanggil dari `frontend-inject`, fokus query pada tren/rujukan yang mempengaruhi keputusan style saat ini
- jangan melakukan broad search jika design decision sudah cukup dari konteks lokal

Aturan token-budget:
- simpan hanya fakta operasional dan source utama
- buang ringkasan dekoratif/opini yang tidak memengaruhi keputusan
- batasi hasil ke konteks minimum yang dibutuhkan langkah berikutnya
- limit ringkasan hasil per source menjadi butir singkat yang bisa dieksekusi

Aturan freshness:
- untuk pertanyaan trend/update, prioritaskan sumber bertanggal dalam 30 hari terakhir
- jika freshness tidak bisa dipastikan, set `uncertainty` minimal `low`

## Agentic Orchestration

Alur default saat konteks kurang:
1. agent -> `think`
2. jika `think` mendeteksi gap konteks -> `intelect-inject`
3. jika tidak ada sub-skill domain yang cocok -> `web-search`
4. hasil pencarian -> short-term memory
5. `smart-plan` memakai konteks ini untuk eksekusi
6. saat memory evolving, `evolve` bisa mengubah pola berulang jadi sub-skill/tool baru

Jika konteks membutuhkan reproduksi UI nyata:
- eskalasi ke browser-action lane (open/click/assert/screenshot) sebelum rekomendasi final.

## Post-Compaction Rehydration Rule

Jika search dilakukan setelah `/compact`:
1. rehydrate objective + constraints dari checkpoint/memory dulu
2. jalankan query sempit berbasis objective aktif (bukan query ulang yang melebar)
3. teruskan hanya fakta operasional yang mempengaruhi next step

## Memory Hand-off (Short-Term)

Simpan hasil pencarian sebagai **short-term memory** di:
- `.codex/memory/MEMORY.md`

Format yang disarankan:
- `web_search_context:` ringkasan temuan
- `source_links:` daftar URL
- `confidence:` high/medium/low
- `candidate_skill_domain:` domain yang mungkin dijadikan sub-skill

Catatan:
- Jangan buat file memory baru untuk short-term.
- Simpan ringkas, fokus pada insight reusable.
- Jika temuan berulang lintas task, tandai sebagai kandidat sub-skill baru.

## Guardrails
- Jangan klaim fakta tanpa sumber.
- Utamakan sumber resmi/dokumentasi primer.
- Hindari menyimpan noise ke memory.

Evidence-tier enforcement:
- klaim kritis wajib didukung `L1_official` atau `L2_primary`
- jika hanya `L3_secondary`, otomatis set `uncertainty: high`
- jangan lanjut ke rekomendasi final high-risk tanpa tier evidence yang memadai

## Failure Mode Policy

Jika source lemah/konflik:
1. label `uncertainty` secara eksplisit
2. hentikan rekomendasi final yang berisiko
3. minta 1 klarifikasi atau source tambahan

Jika source kosong/kurang relevan:
1. tulis eksplisit apa yang tidak ditemukan (source mana yang kosong)
2. jangan isi gap dari pengetahuan latih tanpa evidence baru
3. keluarkan status `unknown_yet` jika klaim kritis tetap tidak didukung

Jika retrieval belum cukup untuk keputusan final:
1. keluarkan `recommendation_status: blocked_by_evidence`
2. berikan hanya next-step query yang paling sempit
3. jangan meneruskan rekomendasi implementasi berisiko

## Output Wajib
- query yang dipakai
- sumber utama yang dipilih
- ringkasan konteks untuk eksekusi
- entri short-term yang ditambahkan ke `MEMORY.md`
- backend/tool yang dipakai untuk search

Schema output minimum:
- `mode` (`quick`|`default`|`deep`)
- `backend_used` (`native_search`|`metasearch_backend`|`deep_research_orchestrator`)
- `token_budget_class` (`tight`|`balanced`|`expanded`)
- `query`
- `time_window` (contoh: `last_30_days`)
- `max_sources`
- `sources[]`
- `clusters[]`
- `conflicts[]`
- `missing_sources[]`
- `confidence` (high/medium/low)
- `uncertainty` (none/low/high)
- `evidence_level` (`L1_official`|`L2_primary`|`L3_secondary`)
- `knowledge_state` (`known`|`unknown_yet`)
- `recommended_next_step`
