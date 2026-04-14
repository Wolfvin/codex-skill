param(
  [Parameter(ValueFromRemainingArguments = $true)]
  [string[]]$Args
)

$runner = Join-Path $PSScriptRoot "tools/_run-sh.ps1"
$script = Join-Path $PSScriptRoot "bootstrap.sh"

& $runner -ScriptPath $script -ForwardArgs $Args
exit $LASTEXITCODE
