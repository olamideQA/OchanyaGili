# Buyer first-time setup: prerequisites -> backend keys -> migrations ->
# first admin -> local_env.json -> optional release build.
# The service_role key is used in-memory ONLY to create the first admin and
# is NEVER written to disk. See TEMPLATE_SETUP.md.

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
Set-Location -LiteralPath $root

function Require-Cmd($name, $installHint) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Error "Missing '$name'. $installHint"
    exit 1
  }
}

Write-Host '== 1/5 Prerequisites ==' -ForegroundColor Cyan
Require-Cmd 'flutter' 'Install Flutter SDK 3.12+ and re-open the terminal.'
$supabaseCli = $null -ne (Get-Command 'supabase' -ErrorAction SilentlyContinue)
if (-not $supabaseCli) {
  Write-Warning 'Supabase CLI not found — migrations must then be applied manually in the dashboard SQL editor (supabase/migrations/*.sql in order).'
}

Write-Host '== 2/5 Backend keys ==' -ForegroundColor Cyan
$supabaseUrl = (Read-Host 'Supabase project URL (https://xyzcompany.supabase.co)').Trim()
$anonKey = (Read-Host 'Supabase ANON key (eyJ...)').Trim()
if ([string]::IsNullOrWhiteSpace($supabaseUrl) -or [string]::IsNullOrWhiteSpace($anonKey)) {
  Write-Error 'Both values are required.'
  exit 1
}

Write-Host 'Validating keys against your project...' -ForegroundColor Gray
try {
  $headers = @{ 'apikey' = $anonKey; 'Authorization' = "Bearer $anonKey" }
  Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/settings?select=key&limit=1" -Headers $headers -TimeoutSec 20 | Out-Null
  Write-Host 'Keys OK.' -ForegroundColor Green
} catch {
  Write-Error "Keys rejected by $supabaseUrl ($($_.Exception.Message)). Fix them and re-run."
  exit 1
}

Write-Host '== 3/5 Database migrations ==' -ForegroundColor Cyan
if ($supabaseCli) {
  Write-Host 'Link your project when prompted (supabase link), then pushing migrations...' -ForegroundColor Gray
  & supabase link
  & supabase db push
  if ($LASTEXITCODE -ne 0) {
    Write-Warning 'Automatic push failed — apply supabase/migrations/*.sql manually in order via the dashboard SQL editor.'
  }
} else {
  Write-Host 'Apply supabase/migrations/00001..00016 manually in the dashboard SQL editor, in order.' -ForegroundColor Yellow
  Read-Host 'Press Enter when done'
}

Write-Host '== 4/5 First admin account ==' -ForegroundColor Cyan
$adminEmail = (Read-Host 'Admin email').Trim()
$adminPassword = Read-Host 'Admin password (min 8 chars)' -AsSecureString
$serviceRole = Read-Host 'Supabase SERVICE_ROLE key (used once, never saved)'
try {
  $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($adminPassword)
  $plainPw = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
  $svcHeaders = @{ 'apikey' = $serviceRole; 'Authorization' = "Bearer $serviceRole"; 'Content-Type' = 'application/json' }
  $body = @{ email = $adminEmail; password = $plainPw; email_confirm = $true } | ConvertTo-Json
  $user = Invoke-RestMethod -Uri "$supabaseUrl/auth/v1/admin/users" -Method Post -Headers $svcHeaders -Body $body -TimeoutSec 20
  Invoke-RestMethod -Uri "$supabaseUrl/rest/v1/profiles?id=eq.$($user.id)" -Method Patch -Headers ($svcHeaders + @{ 'Prefer' = 'return=minimal' }) -Body (@{ role = 'admin' } | ConvertTo-Json) -TimeoutSec 20 | Out-Null
  Write-Host "Admin $adminEmail created with role=admin." -ForegroundColor Green
} catch {
  Write-Error "Admin creation failed ($($_.Exception.Message)). Create the user at /signup in the app, then set profiles.role='admin' in Table Editor."
  exit 1
} finally {
  $serviceRole = $null
  $plainPw = $null
}

Write-Host '== 5/5 Local config + build ==' -ForegroundColor Cyan
$siteUrl = (Read-Host 'Storefront URL (https://shop.example.com) [optional]').Trim()
@{
  SUPABASE_URL     = $supabaseUrl
  SUPABASE_ANON_KEY = $anonKey
  SITE_URL         = $siteUrl
  ENVIRONMENT      = 'production'
} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $PSScriptRoot 'local_env.json') -Encoding UTF8
Write-Host 'Wrote tool/local_env.json (gitignored).' -ForegroundColor Green

$build = Read-Host 'Run release web build now? (y/n)'
if ($build -eq 'y') {
  & (Join-Path $PSScriptRoot 'build_web.ps1')
}

Write-Host ''
Write-Host 'Done. Log in at /#/login as admin, then customize everything at /#/admin (theme, nav, footer, pages, products).' -ForegroundColor Green
