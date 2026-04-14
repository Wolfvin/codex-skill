# Setup Goal: Self-Evolving Agentic Coder

Dokumen ini adalah sumber kebenaran tujuan kita.
Fungsi utamanya: menjaga `.codex` tetap lean, legal, dan terus membaik dari repo yang dipelajari.

## Outcome yang Diinginkan

1. Saat user memberi URL repo, agent bisa intake cepat dan konsisten.
2. Insight penting masuk ke `.codex` (skills, memory, README), bukan copy-paste mentah.
3. Clone repo selalu temporary dan dibersihkan.
4. Agent makin efektif di sesi berikutnya karena memory tersimpan rapi.

## Prinsip Tetap

- `Signal over noise`: ambil hanya hal yang meningkatkan kualitas coding agentic.
- `Surgical changes`: ubah seperlunya, hindari rewrite besar tanpa alasan.
- `Source hygiene`: jangan impor kode dari sumber leak/proprietary yang meragukan.
- `Idempotent`: proses intake repo sama tidak bikin duplikat liar.
- `Traceable`: setiap knowledge harus punya sumber repo yang jelas.

## Mode Eksekusi Default

- Default lintas sesi: agent harus **inisiatif penuh** memilih skill yang tepat dan mengeksekusi task sampai selesai.
- User tidak perlu mengarahkan langkah mikro (mis. "sekarang baca file ini", "sekarang jalankan command itu").
- Agent wajib:
  - memilih workflow/skill sendiri berdasarkan intent user,
  - menjalankan implementasi + verifikasi end-to-end,
  - memberi laporan hasil final + perubahan file.

## Trigger

Aktifkan workflow ini jika user minta hal seperti:

- "baca repo ini"
- "ambil insight dari github ini"
- "pelajari repo ini untuk update .codex"
- "jadikan repo ini referensi kita"

## Workflow Operasional (Wajib)

### 0) Load konteks dulu

Baca state saat ini sebelum intake:

- `.codex/memory/MEMORY.md`
- `.codex/README.md`
- skill terkait (`repo-intake`, `official-skill-sync`, `agentic-cli`, `skill-router`)

Tujuan: hindari duplikasi dan jaga konsistensi.

### 1) Intake repo (fast path)

Single repo:

```bash
bash .codex/tools/repo-intake-cli.sh <repo-url|local-path>
```

Multi repo:

```bash
bash .codex/tools/agentic-cli.sh intake <repo-url|local-path> [repo-url|local-path ...]
```

Atau pakai command center:

```bash
bash .codex/tools/agentic-hub.sh intake <repo-url> [repo-url ...]
```

### 2) Ekstrak high-signal saja

Prioritas ekstraksi:

1. README + docs inti
2. CI/workflows
3. dependency manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, dll)
4. instruction files (`AGENTS.md`, `CLAUDE.md`, `.codex`, `.cursor`)
5. SKILL inventory (jika repo skill)

Output wajib dari ekstraksi:

- tujuan repo (1-2 kalimat)
- stack utama
- command penting (`build`, `test`, `lint`, `dev`)
- pola arsitektur yang reusable
- apa yang layak diadopsi ke `.codex`

### 3) Kurasi ke `.codex`

Update hanya file yang relevan:

- `.codex/skills/*` (jika ada workflow/pattern baru yang memang reusable)
- `.codex/README.md` (cara pakai dan indeks skill/tool)
- `.codex/memory/MEMORY.md` (index + session log)
- `.codex/memory/repo_intake_<topic>.md` (artifact insight per intake)
- aktifkan skill `agent-runtime-advanced` untuk long-session execution (compaction + dependency graph + recovery)

### 4) Cleanup

- clone temporary harus dihapus
- jika `.codex` tidak writable, simpan report di `.tmp/repo-intake/reports` lalu sync:

```bash
bash .codex/tools/agentic-cli.sh sync .tmp/repo-intake/reports
```

### 5) Report ke user

Selalu laporkan:

- sumber repo
- insight utama (max signal)
- file `.codex` yang berubah
- status cleanup

## Navigasi Skill (Wajib untuk Prompt Ambigu)

Saat intent user tidak spesifik, pilih skill via router:

```bash
bash .codex/tools/skill-navigator.sh suggest "<prompt user>"
```

Pilih minimal set skill dengan skor tertinggi, lalu eksekusi end-to-end.

## Do / Don't

Do:

- gunakan CLI intake yang sudah ada
- gunakan `agentic-hub` untuk operasi connector/plugin agar konsisten
- utamakan source resmi/curated untuk skill
- catat keputusan penting ke memory

Don't:

- bulk import semua skill tanpa kurasi
- menyalin kode/prosedur dari source leak
- menyimpan secret/token ke memory
- membiarkan temp clone menumpuk tanpa alasan

## Template Ringkas Output

```text
## Repo Intake Selesai

Sumber: <repo-url>
Insight utama:
1. ...
2. ...
3. ...

Update .codex:
- <file-1>
- <file-2>

Cleanup:
- temporary clone dihapus: ya/tidak
```

## Definisi Selesai

Sebuah intake dianggap selesai jika:

1. Report intake tersedia.
2. Kurasi sudah masuk `.codex` seperlunya.
3. Memory index terupdate.
4. Temporary clone sudah dibersihkan.
5. User mendapat ringkasan yang bisa langsung dipakai.
