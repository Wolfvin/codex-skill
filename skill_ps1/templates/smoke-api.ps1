param(
  [Parameter(Mandatory = $true)] [string]$Url,
  [Parameter(Mandatory = $false)] [ValidateSet('GET','POST','PUT','PATCH','DELETE')] [string]$Method = 'GET',
  [Parameter(Mandatory = $false)] [int]$ExpectedStatus = 200,
  [Parameter(Mandatory = $false)] [string]$ExpectedBodyContains,
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
  $start = Get-Date
  $response = Invoke-WebRequest -Uri $Url -Method $Method -TimeoutSec $TimeoutSeconds -UseBasicParsing
  $elapsed = ((Get-Date) - $start).TotalMilliseconds

  if ($response.StatusCode -ne $ExpectedStatus) {
    Write-Log -Level 'ERROR' -Message "Status mismatch. Expected $ExpectedStatus got $($response.StatusCode)"
    exit 1
  }

  if ($ExpectedBodyContains -and (-not $response.Content.Contains($ExpectedBodyContains))) {
    Write-Log -Level 'ERROR' -Message "Body does not contain expected text: $ExpectedBodyContains"
    exit 1
  }

  Write-Log -Level 'INFO' -Message "Smoke API passed in $([math]::Round($elapsed,2)) ms"
  exit 0
} catch {
  Write-Log -Level 'ERROR' -Message $_.Exception.Message
  exit 1
}
