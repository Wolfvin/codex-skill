param(
  [Parameter(Mandatory = $true)] [string]$ProcessName,
  [Parameter(Mandatory = $false)] [string]$HealthUrl,
  [Parameter(Mandatory = $false)] [int]$Iterations = 5,
  [Parameter(Mandatory = $false)] [int]$SleepSeconds = 2,
  [Parameter(Mandatory = $false)] [int]$CpuThreshold = 85,
  [Parameter(Mandatory = $false)] [int]$WorkingSetMbThreshold = 2048
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
  param([ValidateSet('INFO','WARN','ERROR')] [string]$Level, [string]$Message)
  $ts = (Get-Date).ToString('s')
  Write-Host "$ts [$Level] $Message"
}

try {
  for ($i = 1; $i -le $Iterations; $i++) {
    $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue
    if ($null -eq $proc) {
      Write-Log -Level 'ERROR' -Message "Iteration $i: process missing: $ProcessName"
      exit 1
    }

    $workingSetMb = [math]::Round($proc.WorkingSet64 / 1MB, 2)
    Write-Log -Level 'INFO' -Message "Iteration $i: PID=$($proc.Id) WorkingSetMB=$workingSetMb"

    if ($workingSetMb -gt $WorkingSetMbThreshold) {
      Write-Log -Level 'WARN' -Message "Iteration $i: memory above threshold ($WorkingSetMbThreshold MB)"
    }

    if ($HealthUrl) {
      try {
        $resp = Invoke-WebRequest -Uri $HealthUrl -Method GET -TimeoutSec 20 -UseBasicParsing
        if ($resp.StatusCode -ne 200) {
          Write-Log -Level 'ERROR' -Message "Iteration $i: health status $($resp.StatusCode)"
          exit 1
        }
      } catch {
        Write-Log -Level 'ERROR' -Message "Iteration $i: health check failed: $($_.Exception.Message)"
        exit 1
      }
    }

    Start-Sleep -Seconds $SleepSeconds
  }

  Write-Log -Level 'INFO' -Message 'Debug cycle extended passed.'
  exit 0
} catch {
  Write-Log -Level 'ERROR' -Message $_.Exception.Message
  exit 1
}
