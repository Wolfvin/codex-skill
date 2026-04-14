# Merge Patterns — Referensi Konkret

Pola merge yang paling sering ditemukan di skill workspace AI dev.

---

## PATTERN 1: Verification Suite Merge

**Skill yang biasa overlap:**
`anti-hallucination`, `anti-hallucination-suite`, `truth-finder`,
`uncertainty-detector`, `confidence-scorer`, `cross-checker`,
`source-verifier`, `citation-enforcer`, `context-grounding`

**Cara merge:**
```
verification-suite/
├── SKILL.md
│   ├── Section: Grounding (dari context-grounding)
│   ├── Section: Source Verification (dari source-verifier + citation-enforcer)
│   ├── Section: Cross-checking (dari cross-checker)
│   ├── Section: Confidence Scoring (dari confidence-scorer)
│   └── Section: Uncertainty Handling (dari uncertainty-detector)
```

**Description trigger gabungan:**
> Gunakan saat agent perlu memverifikasi klaim, menghindari hallucination,
> menambahkan confidence score, cross-check sumber, atau memastikan
> jawaban berbasis bukti konkret.

---

## PATTERN 2: Output Audit Merge

**Skill yang biasa overlap:**
`answer-analyzer`, `output-auditor`, `delivery-pipeline` (bagian gate-nya)

**Cara merge:**
```
output-auditor/
├── SKILL.md
│   ├── Section: Pre-delivery Review (dari answer-analyzer)
│   ├── Section: Quality Gate (dari output-auditor)
│   └── Section: Release Readiness (dari delivery-pipeline - gate only)
```

**Catatan:** `delivery-pipeline` biasanya punya scope lebih luas (end-to-end),
jadi hanya bagian "gate" yang di-merge ke output-auditor. Skill
delivery-pipeline tetap dipertahankan untuk scope full pipeline.

---

## PATTERN 3: Agentic Hub Merge

**Skill yang biasa overlap:**
`agentic-cli`, `agentic-hub`, `tagged-work-intake` (bagian intake-nya)

**Cara merge:**
```
agentic-hub/
├── SKILL.md
│   ├── Section: Command Center / Orkestrasi (dari agentic-hub)
│   ├── Section: CLI Interface (dari agentic-cli)
│   └── Section: Task Intake & Normalisasi (dari tagged-work-intake)
```

---

## PATTERN 4: MCP Enrich (bukan merge penuh)

**Skill yang biasa overlap:**
`mcp-manager`, `mcp-server-builder`

**Kenapa enrich, bukan merge:**
- `mcp-manager` = pakai/kelola MCP yang sudah ada
- `mcp-server-builder` = bangun MCP server baru dari scratch
- Tujuan akhir berbeda, tapi bisa dalam 1 skill dengan 2 mode

**Cara enrich:**
```
mcp-manager/
├── SKILL.md
│   ├── Section: Managing Connectors (core lama)
│   ├── Section: Installing & Configuring (core lama)
│   └── Section: Building New MCP Servers [BARU dari mcp-server-builder]
│       ├── API contract design
│       ├── Schema validation
│       └── Testing & deployment
```

---

## PATTERN 5: Tauri Workflow Merge

**Skill yang biasa overlap:**
`vibe-tauri`, `debug-tauri`

**Cara merge:**
```
tauri-workflow/
├── SKILL.md
│   ├── Section: Vibe Coding Loop (dari vibe-tauri)
│   ├── Section: Debug & Fix Loop (dari debug-tauri)
│   └── Section: Evidence-based Iteration (sintesis keduanya)
```

**Trigger gabungan:**
> Gunakan untuk semua workflow iteratif di Tauri: baik vibe-coding
> fitur baru maupun debugging UI/e2e.

---

## CHECKLIST SEBELUM MERGE

```
[ ] Sudah baca semua skill yang akan di-merge
[ ] Tidak ada konten unik yang terhapus
[ ] Description trigger mencakup semua trigger lama
[ ] Semua referensi ke skill lama sudah diupdate
[ ] SKILL_REGISTRY.md sudah diupdate
[ ] Merge history dicatat
```
