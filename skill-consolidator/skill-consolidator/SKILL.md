---
name: skill-consolidator
description: >
  Audit, cluster, dan merge skill yang overlap/duplikat menjadi satu skill yang lebih kaya dan kohesif.
  Gunakan skill ini kapanpun agent hendak membuat skill baru, saat jumlah skill bertambah tanpa konsolidasi,
  saat ada skill dengan nama mirip, atau saat diminta review/cleanup skill workspace. Juga trigger saat
  user menyebut "skill terlalu banyak", "duplikat skill", "merge skill", "konsolidasi skill", atau
  "rapiin skill". Skill ini WAJIB dijalankan sebelum membuat skill baru apapun.
---

# Skill Consolidator

Mencegah skill proliferation dengan audit wajib, similarity check, dan merge skill yang overlap.

---

## KAPAN DIJALANKAN

Wajib dijalankan dalam 3 kondisi:

1. **Sebelum membuat skill baru** — cek dulu apakah sudah ada skill yang bisa diperkaya
2. **Setiap 5 skill baru dibuat** — jalankan audit berkala otomatis
3. **Saat diminta user** — cleanup / konsolidasi / audit skill

---

## STEP 1 — INVENTORY AUDIT

Baca semua skill yang ada:

```bash
# Cari semua SKILL.md di workspace
find .codex/skills -name "SKILL.md" | sort

# Baca nama + description dari frontmatter setiap skill
for f in $(find .codex/skills -name "SKILL.md"); do
  echo "=== $f ==="
  head -20 "$f"
  echo ""
done
```

Buat tabel inventori:

| No | Nama Skill | Tujuan Akhir (1 kalimat) | Lokasi |
|----|-----------|--------------------------|--------|
| 1  | ...       | ...                      | ...    |

---

## STEP 2 — SIMILARITY CLUSTERING

Cluster skill berdasarkan **tujuan akhir**, bukan nama.

### Threshold Similarity
- **>= 60% overlap** → MERGE wajib
- **40-60% overlap** → ENRICH skill yang lebih lemah ke yang lebih kuat
- **< 40% overlap** → Biarkan, dokumentasikan perbedaannya

### Cara menentukan overlap
Tanya per pasang skill:
1. Apakah output akhirnya sama atau sangat mirip?
2. Apakah trigger condition-nya overlap?
3. Apakah step-stepnya redundan?

### Contoh cluster dari skill yang umum ditemukan

```
CLUSTER: Verifikasi & Anti-Hallucination
→ anti-hallucination, truth-finder, uncertainty-detector,
   confidence-scorer, cross-checker, source-verifier,
   citation-enforcer, context-grounding
→ ACTION: Merge ke 1 skill "verification-suite"

CLUSTER: Audit Output
→ answer-analyzer, output-auditor
→ ACTION: Merge ke 1 skill "output-auditor"

CLUSTER: Orkestrasi Agent
→ agentic-cli, agentic-hub
→ ACTION: Merge ke 1 skill "agentic-hub"

CLUSTER: MCP
→ mcp-manager, mcp-server-builder
→ ACTION: Enrich mcp-manager dengan section "Building MCP Servers"
```

Lihat `references/merge-patterns.md` untuk pola merge yang umum.

---

## STEP 3 — KEPUTUSAN PER CLUSTER

Untuk setiap cluster yang ditemukan, putuskan:

### Opsi A: MERGE (cluster >= 2 skill, overlap >= 60%)
```
MERGE: [skill-a] + [skill-b] + [skill-c]
MENJADI: [nama-skill-merged]
ALASAN: [1 kalimat kenapa]
SKILL YANG DIPERTAHANKAN: [skill terlengkap sebagai base]
```

### Opsi B: ENRICH (1 skill sudah bagus, yang lain bisa jadi section)
```
ENRICH: [skill-lemah] → masuk ke [skill-kuat]
SEBAGAI: Section "## [Judul Baru]"
HAPUS: [skill-lemah] setelah merge
```

### Opsi C: BIARKAN (overlap < 40%, tujuan berbeda)
```
KEEP: [skill-a] dan [skill-b]
ALASAN: [perbedaan konkret tujuan akhirnya]
```

---

## STEP 4 — EKSEKUSI MERGE

Untuk setiap keputusan MERGE atau ENRICH:

### 4a. Buat merged SKILL.md

```bash
# Salin skill terkuat sebagai base
cp .codex/skills/[skill-base]/SKILL.md /tmp/merged-skill.md
```

Struktur merged skill:

```markdown
---
name: [nama-merged]
description: >
  [Gabungan description yang mencakup semua trigger dari skill lama]
  Gunakan skill ini saat: [trigger A], [trigger B], [trigger C].
merged_from:
  - [skill-a]
  - [skill-b]
  - [skill-c]
last_merged: [YYYY-MM-DD]
---

# [Nama Skill Merged]

[Deskripsi singkat gabungan]

## [Section dari skill-a yang unik]
[konten]

## [Section dari skill-b yang unik]
[konten]

## [Section baru hasil sintesis]
[konten yang tidak ada di manapun, hasil enrichment]
```

### 4b. Hindari duplikasi konten saat merge

- Baca semua skill yang akan di-merge
- Identifikasi konten yang identik → simpan 1x saja
- Identifikasi konten yang saling melengkapi → gabungkan
- Identifikasi konten yang bertentangan → pilih yang lebih spesifik/akurat

### 4c. Update lokasi skill

```bash
# Buat direktori skill merged
mkdir -p .codex/skills/[nama-merged]

# Tulis SKILL.md hasil merge
# (tulis manual berdasarkan hasil Step 4a)

# Hapus skill lama yang sudah di-merge
rm -rf .codex/skills/[skill-a]
rm -rf .codex/skills/[skill-b]
```

---

## STEP 5 — GUARD SEBELUM SKILL BARU

Sebelum membuat skill baru apapun, agent WAJIB mengisi form ini:

```
SKILL BARU: [nama yang diusulkan]
TUJUAN: [1 kalimat]

SIMILARITY CHECK:
- Skill paling mirip yang ada: [nama]
- Overlap estimate: [%]
- Kenapa tidak bisa di-enrich ke skill itu: [alasan konkret]

KEPUTUSAN: [ ] Buat baru  [ ] Enrich ke [nama skill lama]
```

Jika tidak bisa mengisi "Kenapa tidak bisa di-enrich" dengan alasan konkret → **JANGAN buat skill baru, enrich yang lama**.

---

## STEP 6 — DOKUMENTASI HASIL

Setelah konsolidasi, buat atau update file `SKILL_REGISTRY.md` di root skills:

```markdown
# Skill Registry
Last consolidated: [YYYY-MM-DD]
Total skills: [N] (reduced from [N_before])

## Skills
| Nama | Tujuan | Merged From |
|------|--------|-------------|
| verification-suite | Verifikasi klaim & anti-hallucination | anti-hallucination, truth-finder, ... |
| ...  | ...    | ...         |

## Merge History
- [YYYY-MM-DD]: Merge [A]+[B]+[C] → [D], alasan: ...
```

---

## ATURAN KERAS (JANGAN DILANGGAR)

1. **Jangan merge skill yang tujuan akhirnya berbeda** meski namanya mirip
2. **Jangan hapus konten unik** saat merge — semua insight dari skill lama harus masuk
3. **Pertahankan nama skill yang paling deskriptif**, bukan yang paling lama
4. **Update semua referensi** ke skill lama yang dihapus (di AGENTS.md, README, dll)
5. **Jangan buat skill baru tanpa mengisi SIMILARITY CHECK** di Step 5

---

Lihat `references/merge-patterns.md` untuk contoh pola merge konkret.
