param(
  [Parameter(Mandatory = $true)] [string]$ProcessName,
  [Parameter(Mandatory = $false)] [string]$HealthUrl,
  [Parameter(Mandatory = $false)] [int]$TimeoutSeconds = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
  param([ValidateSet('INFO','WARN','ERROR')] [string]$Level, [string]$Message)
  $ts = (Get-Date).ToString('s')
  Write-Host "$ts [$Level] $Message"
}

try {
  $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
  if ($null -eq $proc) {
    Write-Log -Level 'ERROR' -Message "Process not running: $ProcessName"
    exit 1
  }

  Write-Log -Level 'INFO' -Message "Process running: $ProcessName (PID=$($proc.Id))"

  if ($HealthUrl) {
    $resp = Invoke-WebRequest -Uri $HealthUrl -Method GET -TimeoutSec $TimeoutSeconds -UseBasicParsing
    Write-Log -Level 'INFO' -Message "Health URL status: $($resp.StatusCode)"
    if ($resp.StatusCode -ne 200) { exit 1 }
  }

  Write-Log -Level 'INFO' -Message 'Debug cycle basic passed.'
  exit 0
} catch {
  Write-Log -Level 'ERROR' -Message $_.Exception.Message
  exit 1
}
