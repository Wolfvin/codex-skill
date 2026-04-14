param(
  [Parameter(Mandatory = $false)] [string]$ProjectRoot = (Get-Location).Path,
  [Parameter(Mandatory = $false)] [string[]]$RequiredCommands = @('Get-Process', 'Invoke-WebRequest', 'Start-Process')
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
  param([ValidateSet('INFO','WARN','ERROR')] [string]$Level, [string]$Message)
  $ts = (Get-Date).ToString('s')
  Write-Host "$ts [$Level] $Message"
}

try {
  Write-Log -Level 'INFO' -Message "PowerShell version: $($PSVersionTable.PSVersion)"

  if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    Write-Log -Level 'ERROR' -Message "ProjectRoot not found: $ProjectRoot"
    exit 2
  }

  $logsDir = Join-Path $ProjectRoot 'logs'
  if (-not (Test-Path -LiteralPath $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir | Out-Null
  }

  foreach ($cmd in $RequiredCommands) {
    if (-not (Get-Command -Name $cmd -ErrorAction SilentlyContinue)) {
      Write-Log -Level 'ERROR' -Message "Required command missing: $cmd"
      exit 2
    }
    Write-Log -Level 'INFO' -Message "Command available: $cmd"
  }

  Write-Log -Level 'INFO' -Message 'Environment check passed.'
  exit 0
} catch {
  Write-Log -Level 'ERROR' -Message $_.Exception.Message
  exit 1
}
