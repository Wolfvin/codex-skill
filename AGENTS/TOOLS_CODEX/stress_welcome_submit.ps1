param(
  [string]$BaseUrl = "http://127.0.0.1:3000",
  [int]$Count = 20,
  [int]$TimeoutSec = 45,
  [string]$OutputCsv = ".\\welcome_stress_results.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Invoke-JsonPost {
  param(
    [Parameter(Mandatory = $true)][string]$Url,
    [Parameter(Mandatory = $true)][hashtable]$Body,
    [Parameter(Mandatory = $true)][int]$TimeoutSec
  )

  $json = $Body | ConvertTo-Json -Depth 10
  return Invoke-RestMethod -Method Post -Uri $Url -ContentType "application/json" -Body $json -TimeoutSec $TimeoutSec
}

$base = $BaseUrl.TrimEnd("/")
$results = New-Object System.Collections.Generic.List[Object]

Write-Host "[INFO] BaseUrl    : $base"
Write-Host "[INFO] Count      : $Count"
Write-Host "[INFO] TimeoutSec : $TimeoutSec"

for ($i = 1; $i -le $Count; $i++) {
  $hardwareId = "codex-stress-$i-" + [Guid]::NewGuid().ToString("N").Substring(0, 8)
  $name = "Stress User $i"
  Write-Host "[RUN] #$i hw=$hardwareId"

  $bootstrapMs = $null
  $registerMs = $null
  $bootstrapOk = $false
  $registerOk = $false
  $errorText = ""

  try {
    $sw1 = [System.Diagnostics.Stopwatch]::StartNew()
    $null = Invoke-JsonPost -Url "$base/api/session/bootstrap" -Body @{
      hardware_id = $hardwareId
      app_version = "1.0.0"
    } -TimeoutSec $TimeoutSec
    $sw1.Stop()
    $bootstrapMs = $sw1.ElapsedMilliseconds
    $bootstrapOk = $true
  }
  catch {
    $errorText = "bootstrap: $($_.Exception.Message)"
  }

  if ($bootstrapOk) {
    try {
      $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
      $null = Invoke-JsonPost -Url "$base/api/anggota/self-register" -Body @{
        hardware_id = $hardwareId
        nama = $name
        brevet = "anonymous"
        role = "anggota"
        status = "aktif"
        quotes = "stress-test-$i"
      } -TimeoutSec $TimeoutSec
      $sw2.Stop()
      $registerMs = $sw2.ElapsedMilliseconds
      $registerOk = $true
    }
    catch {
      $errorText = "self-register: $($_.Exception.Message)"
    }
  }

  $results.Add([PSCustomObject]@{
    index = $i
    hardware_id = $hardwareId
    bootstrap_ok = $bootstrapOk
    bootstrap_ms = $bootstrapMs
    register_ok = $registerOk
    register_ms = $registerMs
    error = $errorText
    timestamp = (Get-Date).ToString("s")
  })
}

$results | Export-Csv -Path $OutputCsv -NoTypeInformation -Encoding UTF8

$okCount = ($results | Where-Object { $_.register_ok }).Count
$failCount = $Count - $okCount
$avgRegister = ($results | Where-Object { $_.register_ok -and $_.register_ms -ne $null } | Measure-Object -Property register_ms -Average).Average
$maxRegister = ($results | Where-Object { $_.register_ok -and $_.register_ms -ne $null } | Measure-Object -Property register_ms -Maximum).Maximum

Write-Host "[DONE] OK=$okCount FAIL=$failCount"
if ($avgRegister -ne $null) {
  Write-Host ("[STAT] register avg={0:N2} ms max={1} ms" -f $avgRegister, $maxRegister)
}
Write-Host "[OUT]  $OutputCsv"

