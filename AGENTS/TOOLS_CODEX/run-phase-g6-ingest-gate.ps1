param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [int]$TimeoutSec = 10
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

function Write-Section([string]$msg) {
  Write-Host ""
  Write-Host "=== $msg ===" -ForegroundColor Cyan
}

function Assert-Health([string]$Url, [int]$Timeout) {
  $r = Invoke-WebRequest -UseBasicParsing -Uri "$Url/" -TimeoutSec ([Math]::Min($Timeout, 5))
  if ($r.StatusCode -ne 200) {
    throw "Health check gagal, status=$($r.StatusCode)"
  }
}

Write-Section "G6 Preflight"
Assert-Health -Url $BaseUrl -Timeout $TimeoutSec
Write-Host "[OK] backend healthy"

$ok = 0
$fail = 0
$createdAnggotaId = $null

try {
  Write-Section "G6-1 POST /api/documents"
  $docBody = @{
    device_id = "g6-script"
    doc_type = "g6-test"
    count = 1
    nama_dokumen = "G6 Dokumen Test"
    klien = "G6 Client"
    status = "selesai"
  } | ConvertTo-Json
  $docResp = Invoke-WebRequest -UseBasicParsing -Method POST -Uri "$BaseUrl/api/documents" -ContentType "application/json" -Body $docBody -TimeoutSec $TimeoutSec
  if ($docResp.StatusCode -lt 200 -or $docResp.StatusCode -ge 300) { throw "POST /api/documents gagal status=$($docResp.StatusCode)" }
  Assert-Health -Url $BaseUrl -Timeout $TimeoutSec
  Write-Host "[OK] documents ingest + health 200" -ForegroundColor Green
  $ok++

  Write-Section "G6-2 POST /api/files/count"
  $countBody = @{
    hardware_id = "g6-hw"
    jenis_file = "pdf"
    jumlah_file = 3
    tanggal = "2026-04-04"
  } | ConvertTo-Json
  $countResp = Invoke-WebRequest -UseBasicParsing -Method POST -Uri "$BaseUrl/api/files/count" -ContentType "application/json" -Body $countBody -TimeoutSec $TimeoutSec
  if ($countResp.StatusCode -lt 200 -or $countResp.StatusCode -ge 300) { throw "POST /api/files/count gagal status=$($countResp.StatusCode)" }
  Assert-Health -Url $BaseUrl -Timeout $TimeoutSec
  Write-Host "[OK] files_count ingest + health 200" -ForegroundColor Green
  $ok++

  Write-Section "G6-3 POST /api/anggota/self-register (create + update)"
  $hw = "G6-HW-" + ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds())
  $createBody = @{
    hardware_id = $hw
    nama = "G6 User Create"
    nomor_anggota = "G6-" + ([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())
    brevet = "a"
    quotes = "g6-create"
  } | ConvertTo-Json
  $reg1 = Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/anggota/self-register" -ContentType "application/json" -Body $createBody -TimeoutSec $TimeoutSec
  if (-not $reg1.ok) { throw "self-register create gagal: $($reg1.error)" }
  $createdAnggotaId = [string]$reg1.id
  Assert-Health -Url $BaseUrl -Timeout $TimeoutSec

  $updateBody = @{
    hardware_id = $hw
    nama = "G6 User Updated"
    quotes = "g6-update"
    brevet = "a"
  } | ConvertTo-Json
  $reg2 = Invoke-RestMethod -Method POST -Uri "$BaseUrl/api/anggota/self-register" -ContentType "application/json" -Body $updateBody -TimeoutSec $TimeoutSec
  if (-not $reg2.ok) { throw "self-register update gagal: $($reg2.error)" }
  if ([string]$reg2.id -ne $createdAnggotaId) {
    throw "self-register update tidak memakai id yang sama (expected=$createdAnggotaId actual=$($reg2.id))"
  }
  Assert-Health -Url $BaseUrl -Timeout $TimeoutSec
  Write-Host "[OK] self-register create+update + health 200" -ForegroundColor Green
  $ok++

  Write-Section "G6-4 Verify anggota updated"
  $members = Invoke-RestMethod -Method GET -Uri "$BaseUrl/api/anggota" -TimeoutSec $TimeoutSec
  $target = $members | Where-Object { [string]$_.id -eq $createdAnggotaId } | Select-Object -First 1
  if ($null -eq $target) { throw "Anggota hasil self-register tidak ditemukan di list." }
  if ([string]$target.nama -ne "G6 User Updated") {
    throw "Nama anggota belum terupdate. actual='$($target.nama)'"
  }
  Write-Host "[OK] anggota list konsisten (updated name)" -ForegroundColor Green
  $ok++

  Write-Section "G6-5 Cleanup anggota test"
  $del = Invoke-WebRequest -UseBasicParsing -Method DELETE -Uri "$BaseUrl/api/anggota/$createdAnggotaId" -TimeoutSec $TimeoutSec
  if ($del.StatusCode -lt 200 -or $del.StatusCode -ge 300) { throw "DELETE anggota g6 gagal status=$($del.StatusCode)" }
  Assert-Health -Url $BaseUrl -Timeout $TimeoutSec
  Write-Host "[OK] cleanup anggota test + health 200" -ForegroundColor Green
  $ok++
}
catch {
  $fail++
  Write-Host ("[FAIL] {0}" -f $_.Exception.Message) -ForegroundColor Red
}

Write-Section "G6 Summary"
Write-Host ("Checks OK   : {0}" -f $ok)
Write-Host ("Checks FAIL : {0}" -f $fail)

if ($fail -gt 0) { exit 1 }
exit 0
