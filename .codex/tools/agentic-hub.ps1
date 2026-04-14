param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$runner = Join-Path $PSScriptRoot "_run-sh.ps1"
$script = Join-Path $PSScriptRoot "agentic-hub.sh"

& $runner -ScriptPath $script -ForwardArgs $Args
exit $LASTEXITCODE
