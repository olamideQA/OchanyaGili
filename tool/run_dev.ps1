# Dev runner: flutter run with buyer keys from tool/local_env.json
# Usage: .\tool\run_dev.ps1 [-Device chrome] [-WebPort 8081]
param([string]$Device = 'chrome', [int]$WebPort = 8081)

. (Join-Path $PSScriptRoot 'env_loader.ps1')
$defines = Get-DartDefines

if ($Device -eq 'chrome') {
  & flutter run -d $Device --web-port=$WebPort @defines
} else {
  & flutter run -d $Device @defines
}
