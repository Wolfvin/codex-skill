# AGENTS.md - AKP2I Projects

Dokumen ini adalah aturan kerja agen lintas repo di `D:\Workspace\projects\akp2i_projects`.

## 1. Scope
- Berlaku untuk seluruh folder project, terutama:
  - `server_lokal`
  - `smart_tax_assistance`
  - `AKP2I-STA`

## 2. Prioritas Instruksi
1. Instruksi runtime (`System` / `Developer`)
2. `AGENTS.md` ini
3. Instruksi user pada task aktif

Jika konflik, ikuti urutan di atas dan jelaskan singkat ke user.

## 3. Prinsip Eksekusi
1. Progress-first: sebelum read/edit/run besar, beri intent singkat ke user.
2. Source-of-truth: edit file sumber, bukan artifact generated, kecuali diminta.
3. Traceability: setiap perubahan wajib jelas apa, kenapa, dan hasil verifikasi.
4. Risk-aware workflow:
   - sebelum implementasi besar, lakukan risk scan singkat (potensi bug, regresi, dampak data/runtime).
   - setelah task selesai, laporkan risiko regresi yang masih tersisa.
5. Kritik teknis wajib:
   - untuk usulan user/solusi, beri evaluasi teknis singkat (risiko, asumsi lemah, opsi lebih aman produksi).
6. Quality over speed: utamakan correctness, maintainability, dan verifikasi nyata.

## 4. Disiplin Teknis Wajib
1. API discipline:
   - sebelum tambah/ubah endpoint, cek `smart_tax_assistance/docs/dev-notes/API.md`.
   - jika endpoint baru/berubah, update `API.md`.
2. Frontend ID/Class discipline (khusus area HTML/JS):
   - sebelum/sesudah edit `index.html` atau page HTML lain, pastikan tidak ada `id` duplikat.
   - class untuk styling boleh reuse, tetapi class hook JS harus scoped per fitur (hindari collision antar modul).
   - hindari selector JS terlalu generik (`.modal-*`, `.btn-*`) jika ada lebih dari satu komponen sejenis.
   - jika komponen beda perilaku, pakai prefix domain/fitur (contoh: `ann-*`, `agm-*`, `sm-*`, `dev-*`).
   - jika ditemukan bentrok selector/event lintas komponen, wajib perbaiki dulu sebelum lanjut fitur lain.
3. Struktur folder discipline (frontend window + backend):
   - struktur dipisah per domain, tidak dicampur acak.
   - frontend tetap terkelola per layer/fitur (`src/js/*`, `src/styles/*`, page folder terkait).
   - window/fitur khusus ditempatkan di folder khususnya, bukan ditumpuk di root `src`.
   - backend harus tetap terpisah dari source UI (`server_lokal`, `src-tauri`, dsb).
   - saat menambah fitur baru, tetapkan lokasi folder yang benar dulu sebelum menulis file.
   - jika ada file lintas domain tercampur, agent wajib usulkan/kerjakan perapihan terstruktur.
4. Security key discipline:
   - jangan pakai placeholder key untuk jalur release.
   - jika key belum final, hentikan proses release dan lapor user.

## 5. Operasional Tooling
1. Search cepat: utamakan `rg`.
2. Edit: utamakan patch minimal dan fokus ke scope task.
3. Git safety:
   - dilarang command destruktif tanpa izin user.
   - jangan revert perubahan user yang tidak diminta.
4. Verifikasi:
   - jalankan verifikasi relevan (`cargo check`, smoke test, dsb).
   - jika tidak sempat/terhalang, laporkan jelas.

## 6. Dokumen Progress dan Handoff
1. Handoff/progress wajib mengikuti `AGENTS/SKILLS/skill_handoff/skill_handoff.md` (single source rule untuk update state dokumen).
2. Agent tidak boleh menutup task tanpa update dokumen handoff sesuai skill tersebut.

## 7. Penggunaan Skill Lokal (Wajib Saat Relevan)
Struktur skill standar:
- `AGENTS/SKILLS/<nama_skill>/README.md`
- `AGENTS/SKILLS/<nama_skill>/<nama_skill>.md`
- optional: folder template/assets (`SOP_TEMPLATE`, dll)

Canonical skill yang dipakai:
1. `AGENTS/SKILLS/skill_ps1/skill_ps1.md`
   - gunakan saat membuat script test end-to-end (health, GET/POST, verifikasi, cleanup).
   - gunakan untuk regression check setelah perubahan backend/frontend.
2. `AGENTS/SKILLS/skill_sop/skill_sop.md`
   - gunakan saat membuat/merapikan struktur SOP PowerShell operasional.
   - target pola struktur mengikuti `server_lokal/SOP`.
3. `AGENTS/SKILLS/skill_handoff/skill_handoff.md`
   - gunakan pada setiap task yang mengubah file.
   - wajib update handoff/state file + README bertingkat di folder terkait sebelum menutup task.

## 8. SOP Server Lokal
Untuk start/stop backend `server_lokal`, default pakai:
- `server_lokal/SOP/40_run_backend.ps1`
- `server_lokal/SOP/41_stop_backend.ps1`

## 9. Maintenance
- Dokumen ini living document.
- Revisi besar dilakukan dengan persetujuan user.
