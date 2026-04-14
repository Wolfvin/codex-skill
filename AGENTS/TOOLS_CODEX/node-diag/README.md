# Node Diagnostics Bundle

Folder ini disiapkan agar node produksi (tanpa source/devtools) bisa langsung cek status join/auth.

## File
1. `this_device_hwid_hash.ps1`
- Ambil raw HWID kandidat dan hash SHA-256.
- Cocok untuk cari nilai hash device yang harus muncul di `/api/devices`.

2. `diag-user-bootstrap-status.ps1`
- Cek bootstrap + keberadaan device hash untuk 1..N hardware id.

3. `node-oneclick-check.ps1`
- Paket cepat satu perintah:
  - hitung hash HWID node
  - cek `POST /api/session/bootstrap`
  - cek hash cocok di `GET /api/devices`

## Quick Start (di node)
```powershell
powershell -ExecutionPolicy Bypass -File .\node-oneclick-check.ps1 -BaseUrl "http://192.168.100.74:3000"
```

Jika ingin pakai raw HWID manual:
```powershell
powershell -ExecutionPolicy Bypass -File .\node-oneclick-check.ps1 -BaseUrl "http://192.168.100.74:3000" -RawHardwareId "<RAW_HWID>"
```

## Multi User Check
```powershell
powershell -ExecutionPolicy Bypass -File .\diag-user-bootstrap-status.ps1 -BaseUrl "http://192.168.100.74:3000" -HardwareIds @("HWID_A","HWID_B") -Names @("NodeA","NodeB")
```

## Output Yang Dicari
- `bootstrap.ok = True`
- `token.set = True`
- `[PASS] hash ditemukan di /api/devices`

Jika salah satu gagal, kirim output terminal ke tim untuk diagnosis lanjut.
