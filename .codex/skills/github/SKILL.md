---
name: github
description: Safe GitHub commit and push workflow with strict no-merge policy. Use when user asks to commit and push current project to GitHub, wants remote to match local project exactly, needs conventional commit messages, and requires explicit checks for nested git repositories that may be left out.
---

# GitHub

Gunakan workflow ini untuk commit + push ke GitHub tanpa merge.

## Core Rules

- Jangan gunakan `git pull` atau strategi merge apa pun.
- Sebelum push, tampilkan warning ini ke user:
`!! repo kamu akan sama persis dengan struktur proyek dan perubahan saat ini !!`
- Jika terdeteksi nested git repo, wajib tanya user per folder:
`folder <path> tidak masuk, apakah mau masukkan?`
- Jangan push sebelum user mengonfirmasi folder nested repo yang terdeteksi.
- Jangan lakukan auto-fix destruktif pada nested repo tanpa persetujuan eksplisit user.

## Workflow

1. Audit git boundary dan nested repo:
```bash
bash .codex/skills/github/scripts/audit-git-boundaries.sh
```

2. Jika ada nested repo, hentikan flow dan minta keputusan user per folder:
- `masukkan` (umumnya kasus salah `git init` di subfolder)
- `biarkan` (tetap terpisah/tidak ikut commit root)

3. Auth preflight:
```bash
git remote -v
```
- Jika remote `git@github.com:...`:
```bash
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh -T git@github.com
```
- Jika remote `https://github.com/...`:
  - pastikan credential helper/PAT valid sebelum push.

4. Cek status perubahan root repo:
```bash
git status --short
```

5. Stage perubahan yang disetujui user:
```bash
git add -A
```

6. Buat commit message conventional dari diff aktual:
- pilih type yang tepat (`feat|fix|refactor|docs|test|chore|perf|ci`)
- ringkas, fokus ke perubahan nyata
- hindari commit file sensitif

7. Commit:
```bash
git commit -m "<type>: <ringkasan perubahan>"
```

8. Sinkronisasi remote tanpa merge (fetch-only):
```bash
git fetch origin
```

9. Sebelum push, tampilkan warning wajib:
`!! repo kamu akan sama persis dengan struktur proyek dan perubahan saat ini !!`

10. Push strict no-merge:
- Fast-forward mode (default aman):
```bash
bash .codex/skills/github/scripts/strict-no-merge-push.sh --mode ff --yes-warning
```
- Force mode jika user ingin remote dipaksa sama dengan lokal:
```bash
bash .codex/skills/github/scripts/strict-no-merge-push.sh --mode force --yes-warning
```

11. Post-execution safety net:
- jika perubahan sudah valid tapi belum ada PR artefak/ringkasan siap review, wajib keluarkan checklist finalisasi sebelum flow ditutup.

Pre-push risk acknowledgement:
- jika ada indikasi force/history rewrite/infra-impact, tampilkan acknowledgement checklist eksplisit sebelum push.

## Divergence Handling (No-Merge)

Jika remote branch punya commit yang tidak ada di lokal:
- Jangan merge.
- Tawarkan user pilihan:
1. Reset lokal ke `origin/<branch>` lalu ulangi commit.
2. Force push lokal ke remote (`--force-with-lease`).
3. Batal.

## Error Recovery Cepat

- `Host key verification failed`:
  - tambahkan host key GitHub ke `~/.ssh/known_hosts`, lalu retry.
- `Permission denied (publickey)`:
  - add SSH key ke agent (`ssh-add`) dan pastikan public key terdaftar di GitHub.
- `could not read Username for 'https://github.com'`:
  - remote HTTPS belum punya kredensial; login PAT dulu atau ganti ke SSH remote.

## Output Wajib (untuk audit user)

- daftar file yang di-commit
- commit hash + commit message final
- mode push yang dipakai (`ff` atau `force`)
- hasil audit nested repo + jawaban user
