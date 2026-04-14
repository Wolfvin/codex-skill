param(
  [Parameter(Mandatory = $true)] [string]$Url,
  [Parameter(Mandatory = $false)] [ValidateSet('edge','chrome','default')] [string]$Browser = 'edge',
  [Parameter(Mandatory = $false)] [switch]$OpenDevTools = $false,
  [Parameter(Mandatory = $false)] [switch]$DryRun = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
  param([ValidateSet('INFO','WARN','ERROR')] [string]$Level, [string]$Message)
  $ts = (Get-Date).ToString('s')
  Write-Host "$ts [$Level] $Message"
}

function Get-BrowserCommand {
  param([string]$Name)
  switch ($Name) {
    'edge' { return 'msedge.exe' }
    'chrome' { return 'chrome.exe' }
    default { return $null }
  }
}

try {
  if ($DryRun) {
    Write-Log -Level 'INFO' -Message "[DRY-RUN] Would open URL: $Url on browser: $Browser"
    exit 0
  }

  $browserCmd = Get-BrowserCommand -Name $Browser
  if ($null -eq $browserCmd) {
    Start-Process $Url
    Write-Log -Level 'INFO' -Message "Opened URL with default browser: $Url"
  } else {
    Start-Process -FilePath $browserCmd -ArgumentList $Url
    Write-Log -Level 'INFO' -Message "Opened URL with $Browser: $Url"
  }

  if ($OpenDevTools) {
    Write-Log -Level 'WARN' -Message 'OpenDevTools flag requested. Manual devtools toggle may be required by browser policy.'
  }

  exit 0
} catch {
  Write-Log -Level 'ERROR' -Message $_.Exception.Message
  exit 1
}
