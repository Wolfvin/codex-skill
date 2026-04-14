param(
  [Parameter(Mandatory = $true)] [string]$TaskName,
  [Parameter(Mandatory = $false)] [string]$ProjectRoot = (Get-Location).Path,
  [Parameter(Mandatory = $false)] [switch]$DryRun = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
  param([ValidateSet('INFO','WARN','ERROR')] [string]$Level, [string]$Message)
  $ts = (Get-Date).ToString('s')
  Write-Host "$ts [$Level] $Message"
}

function Invoke-WithRetry {
  param([scriptblock]$Action, [int]$MaxAttempts = 3, [int]$DelaySeconds = 2)
  for ($i = 1; $i -le $MaxAttempts; $i++) {
    try { return (& $Action) } catch {
      if ($i -eq $MaxAttempts) { throw }
      Write-Log -Level 'WARN' -Message "Attempt $i failed: $($_.Exception.Message). Retrying in $DelaySeconds sec."
      Start-Sleep -Seconds $DelaySeconds
    }
  }
}

try {
  if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    Write-Log -Level 'ERROR' -Message "ProjectRoot not found: $ProjectRoot"
    exit 2
  }

  Write-Log -Level 'INFO' -Message "Scaffold start for task '$TaskName'"
  Write-Log -Level 'INFO' -Message "ProjectRoot: $ProjectRoot"
  Write-Log -Level 'INFO' -Message "DryRun: $DryRun"

  if ($DryRun) {
    Write-Log -Level 'INFO' -Message 'Dry-run mode: no changes applied.'
  } else {
    Write-Log -Level 'INFO' -Message 'Execution mode enabled.'
  }

  Write-Log -Level 'INFO' -Message 'Scaffold complete.'
  exit 0
} catch {
  Write-Log -Level 'ERROR' -Message $_.Exception.Message
  exit 1
}
