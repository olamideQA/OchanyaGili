# Release build for static hosting (cPanel public_html, Netlify, Vercel, S3).
# Usage: .\tool\build_web.ps1
# Output: build\web\  -> upload its CONTENTS to public_html (or equivalent).

. (Join-Path $PSScriptRoot 'env_loader.ps1')
$defines = Get-DartDefines

& flutter build web --release @defines
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ''
Write-Host 'Build ready in build\web\. Upload its CONTENTS (not the folder) to public_html.' -ForegroundColor Green
Write-Host 'Hash routes (#/shop/...) work on plain static hosting — no rewrites needed.' -ForegroundColor Green
