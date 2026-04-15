---
name: frontend-inject
description: Frontend context injector that merges visual direction and DESIGN.md contract validation. Use when tasks involve UI creation, redesign, or style-sensitive frontend execution needing consistent design-system context.
---

# Frontend Inject

Skill ini adalah merge dari `frontend-design` + `design-md-inject`.
Tujuan: injeksi konteks frontend yang konsisten, bukan hanya inspirasi visual.

## Trigger
- Task melibatkan build/redesign UI.
- Task butuh konsistensi desain lintas page/component.
- Ada `DESIGN.md` yang perlu dijadikan kontrak implementasi.

## Workflow

1. Cek apakah `DESIGN.md` tersedia di root project.
2. Jika ada, validasi section minimum dengan script:
```bash
bash .codex/skills/intelect-inject/scripts/design-md-check.sh --file DESIGN.md
```
3. Injeksi constraint desain utama:
- visual theme + atmosphere
- color roles (semantic)
- typography hierarchy
- component styling rules
- responsive behavior + do/don't
4. Jika `DESIGN.md` tidak ada atau gagal validasi:
- fallback ke design brief ringkas berbasis konteks user
- tetap tetapkan design constraints ringkas sebelum coding
5. Terapkan guardrail anti-generic UI:
- hindari layout boilerplate
- gunakan style direction yang intentional
- pastikan mobile + desktop render aman

## Domain-to-Design-System Decision Gate

Sebelum implementasi UI, wajib tetapkan keputusan ini:
1. `product_domain` (contoh: fintech, healthcare, saas, beauty, ecommerce)
2. `ui_pattern` (landing/dashboard/form-heavy/storytelling)
3. `style_direction`
4. `color_role_plan`
5. `typography_plan`
6. `interaction_effects`

Jika salah satu belum jelas:
- tahan coding
- keluarkan 1 pertanyaan klarifikasi paling kecil

## Anti-Pattern Blacklist + Pre-Delivery Checklist

Blacklist minimum:
- kontras teks rendah
- motion berlebihan tanpa reduced-motion fallback
- CTA utama tidak jelas
- layout pecah di mobile
- penggunaan ikon emoji untuk UI produksi

Checklist sebelum status siap:
1. contrast target minimal WCAG AA untuk teks utama
2. focus state keyboard terlihat
3. hover/active state konsisten
4. breakpoint minimum: 375, 768, 1024, 1440
5. `prefers-reduced-motion` dihormati
6. komponen utama punya semantic role yang tepat

## Multi-Framework Design Contract

Saat task lintas framework, tulis adaptasi kontrak per target:
1. `framework_target[]`
2. `shared_design_rules`
3. `framework_specific_notes`

Target umum:
- React/Next
- Vue/Nuxt
- Svelte/SvelteKit
- React Native/Flutter
- SwiftUI/Jetpack Compose

## Searchable Design Retrieval (Compressed)

Jika butuh referensi design tambahan:
1. prioritaskan retrieval lokal terstruktur (style/palette/typography/chart/ux-rule)
2. keluarkan hanya:
- `decision`
- `why`
- `checklist_impact`
3. jangan dump katalog panjang ke context aktif

## Output Wajib
- `design_contract_source` (`design_md`|`fallback_brief`)
- `product_domain`
- `design_system_decision`
- `design_constraints`
- `anti_pattern_guard`
- `ui_risks`
- `next_step`
