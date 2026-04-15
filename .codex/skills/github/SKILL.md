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

## Workflow

1. Audit git boundary dan nested repo:
```bash
bash .codex/skills/github/scripts/audit-git-boundaries.sh
```

2. Cek status perubahan root repo:
```bash
git status --short
```

3. Stage perubahan yang disetujui user:
```bash
git add -A
```

4. Buat commit message conventional dari diff aktual:
- pilih type yang tepat (`feat|fix|refactor|docs|test|chore|perf|ci`)
- ringkas, fokus ke perubahan nyata
- hindari commit file sensitif

5. Commit:
```bash
git commit -m "<type>: <ringkasan perubahan>"
```

6. Sinkronisasi remote tanpa merge (fetch-only):
```bash
git fetch origin
```

7. Push strict no-merge:
- Fast-forward mode (default aman):
```bash
bash .codex/skills/github/scripts/strict-no-merge-push.sh --mode ff --yes-warning
```
- Force mode jika user ingin remote dipaksa sama dengan lokal:
```bash
bash .codex/skills/github/scripts/strict-no-merge-push.sh --mode force --yes-warning
```

## Divergence Handling (No-Merge)

Jika remote branch punya commit yang tidak ada di lokal:
- Jangan merge.
- Tawarkan user pilihan:
1. Reset lokal ke `origin/<branch>` lalu ulangi commit.
2. Force push lokal ke remote (`--force-with-lease`).
3. Batal.

## Output Wajib

- daftar file yang di-commit
- commit hash + commit message final
- mode push yang dipakai (`ff` atau `force`)
- hasil audit nested repo + jawaban user
