# Loads tool/local_env.json (gitignored) and converts it to --dart-define flags.
# Usage: $defines = Get-DartDefines  (then: flutter run $defines ...)
function Get-DartDefines {
  $envFile = Join-Path $PSScriptRoot 'local_env.json'
  if (-not (Test-Path -LiteralPath $envFile)) {
    Write-Error "Missing tool/local_env.json. Copy tool/local_env.example.json to tool/local_env.json and fill in your keys (see TEMPLATE_SETUP.md)."
    exit 1
  }
  $cfg = Get-Content -LiteralPath $envFile -Raw | ConvertFrom-Json
  if ([string]::IsNullOrWhiteSpace($cfg.SUPABASE_URL) -or [string]::IsNullOrWhiteSpace($cfg.SUPABASE_ANON_KEY)) {
    Write-Error 'tool/local_env.json must contain SUPABASE_URL and SUPABASE_ANON_KEY.'
    exit 1
  }
  $defines = @(
    "--dart-define=SUPABASE_URL=$($cfg.SUPABASE_URL)",
    "--dart-define=SUPABASE_ANON_KEY=$($cfg.SUPABASE_ANON_KEY)"
  )
  if ($cfg.SITE_URL) { $defines += "--dart-define=SITE_URL=$($cfg.SITE_URL)" }
  if ($cfg.ENVIRONMENT) { $defines += "--dart-define=ENVIRONMENT=$($cfg.ENVIRONMENT)" }
  if ($cfg.PAYSTACK_PUBLIC_KEY) { $defines += "--dart-define=PAYSTACK_PUBLIC_KEY=$($cfg.PAYSTACK_PUBLIC_KEY)" }
  if ($cfg.GA_MEASUREMENT_ID) { $defines += "--dart-define=GA_MEASUREMENT_ID=$($cfg.GA_MEASUREMENT_ID)" }
  return $defines
}
