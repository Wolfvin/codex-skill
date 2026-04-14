param(
  [string]$DataRoot = "D:\Workspace\projects\akp2i_projects",
  [int]$NodeCount = 3,
  [int]$BasePort = 3000
)

. "$PSScriptRoot\node-sim-lib.ps1"

$nodes = Build-NodeList -NodeCount $NodeCount -BasePort $BasePort -DataRoot $DataRoot

Write-Section "Stop Nodes"
foreach ($n in $nodes) {
  if (Stop-Node -Node $n) {
    Write-Host "[OK] stop $($n.Name)" -ForegroundColor Green
  } else {
    Write-Host "[WARN] gagal stop $($n.Name)" -ForegroundColor Yellow
  }
}
