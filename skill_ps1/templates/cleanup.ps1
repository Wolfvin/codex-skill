param(
  [Parameter(Mandatory = $false)] [string]$ProjectRoot = (Get-Location).Path,
  [Parameter(Mandatory = $false)] [string[]]$TargetPatterns = @('logs\\*.tmp', 'logs\\*.bak', 'temp\\*'),
  [Parameter(Mandatory = $false)] [switch]$DryRun = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
  param([ValidateSet('INFO','WARN','ERROR')] [string]$Level, [string]$Message)
  $ts = (Get-Date).ToString('s')
  Write-Host "$ts [$Level] $Message"
}

function Assert-UnderRoot {
  param([string]$Root, [string]$Candidate)
  $resolvedRoot = (Resolve-Path -LiteralPath $Root).Path
  $resolvedCandidate = (Resolve-Path -LiteralPath (Split-Path -Parent $Candidate) -ErrorAction SilentlyContinue)
  if ($null -eq $resolvedCandidate) { return }
  if (-not $resolvedCandidate.Path.StartsWith($resolvedRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "Refusing cleanup outside project root: $Candidate"
  }
}

try {
  if (-not (Test-Path -LiteralPath $ProjectRoot)) {
    Write-Log -Level 'ERROR' -Message "ProjectRoot not found: $ProjectRoot"
    exit 2
  }

  foreach ($pattern in $TargetPatterns) {
    $fullPattern = Join-Path $ProjectRoot $pattern
    $items = Get-ChildItem -Path $fullPattern -Force -ErrorAction SilentlyContinue
    foreach ($item in $items) {
      Assert-UnderRoot -Root $ProjectRoot -Candidate $item.FullName
      if ($DryRun) {
        Write-Log -Level 'INFO' -Message "[DRY-RUN] Would remove: $($item.FullName)"
      } else {
        Remove-Item -LiteralPath $item.FullName -Recurse -Force
        Write-Log -Level 'INFO' -Message "Removed: $($item.FullName)"
      }
    }
  }

  Write-Log -Level 'INFO' -Message 'Cleanup completed.'
  exit 0
} catch {
  Write-Log -Level 'ERROR' -Message $_.Exception.Message
  exit 1
}
