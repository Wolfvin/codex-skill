param(
  [Parameter(Mandatory = $true)] [string]$Url,
  [Parameter(Mandatory = $false)] [int]$Iterations = 20,
  [Parameter(Mandatory = $false)] [int]$Parallel = 4,
  [Parameter(Mandatory = $false)] [int]$TimeoutSeconds = 10
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
  param([ValidateSet('INFO','WARN','ERROR')] [string]$Level, [string]$Message)
  $ts = (Get-Date).ToString('s')
  Write-Host "$ts [$Level] $Message"
}

try {
  $success = 0
  $failed = 0
  $latencies = New-Object System.Collections.Generic.List[double]

  for ($i = 1; $i -le $Iterations; $i++) {
    $start = Get-Date
    try {
      $null = Invoke-WebRequest -Uri $Url -Method GET -TimeoutSec $TimeoutSeconds -UseBasicParsing
      $success++
    } catch {
      $failed++
    }
    $latencies.Add(((Get-Date) - $start).TotalMilliseconds)
  }

  $avg = if ($latencies.Count -gt 0) { [math]::Round(($latencies | Measure-Object -Average).Average, 2) } else { 0 }
  Write-Log -Level 'INFO' -Message "Node sim finished. Success=$success Failed=$failed AvgMs=$avg"

  if ($failed -gt 0) { exit 1 }
  exit 0
} catch {
  Write-Log -Level 'ERROR' -Message $_.Exception.Message
  exit 1
}
