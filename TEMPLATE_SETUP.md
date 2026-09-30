# Template Buyer Setup Guide — Atelier Commerce (Flutter + Supabase)

You bought a full boutique storefront + admin backend, not a WordPress theme.
One technical setup (~15–30 min), then everything else is point-and-click
in the admin backend at `/#/admin`.

## What you need first

1. **Flutter SDK 3.12+** (`flutter --version` to verify).
2. **A Supabase project** (free tier works): supabase.com → New project.
   Keep two keys handy: Project Settings → API → `anon` key and
   `service_role` key. The service_role key is used **once** by the setup
   script to create your admin account and is never saved anywhere.
3. **Supabase CLI** (optional but recommended): `npm i -g supabase`.

## Setup (guided)

```powershell
.\tool\setup_buyer.ps1
```

It walks you through: prerequisite checks → backend key validation →
database migrations (`supabase/migrations/00001`–`00016`, in order) →
first admin account → `tool/local_env.json` (your keys, gitignored) →
optional release build.

Manual fallback for any step is printed by the script as it runs.

## Daily use

```powershell
.\tool\run_dev.ps1        # dev server with your keys (default http://localhost:8081)
.\tool\build_web.ps1      # release build into build\web\
```

## Going live (cPanel / any static host)

1. Run `.\tool\build_web.ps1`.
2. Upload the **contents** of `build\web\` (not the folder itself) to
   `public_html` (cPanel → File Manager).
3. Done — hash routes (`#/shop/...`) work on plain static hosting, no
   rewrite rules needed. Rebuild + re-upload whenever you ship app updates
   (content edits in `/admin` need no rebuild).

## Customizing without code

Log in as admin → `/#/admin`: brand/logo/announcement (`navigation`),
theme colors + presets (`theme`), footer/socials (`footer`), custom pages
(`custom-pages`), products, collections, lookbook, journal, hero slides
(`settings`). Changes apply to the storefront immediately (hard-refresh).

## Demo data

The template ships with pitch content gated behind `DemoConfig.enabled`
(`lib/core/config/demo_config.dart`). Set it to `false` for a clean
client handoff — `grep DEMO-SEED` lists every removable block.

## What this template is NOT

* Not WordPress/PHP — there is no uploader-friendly zip or wp-admin import.
  WordPress can only act as a headless CMS via REST, which is a separate
  integration project.
* The mobile/desktop apps (`android/`, `ios/`) share the same backend but
  need store signing setup outside this guide.
