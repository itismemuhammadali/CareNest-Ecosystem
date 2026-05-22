#!/usr/bin/env bash
# One-shot local stack for tech demos (Docker + Supabase CLI).
# Run from repo root:  bash scripts/bootstrap-local-demo.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v supabase >/dev/null 2>&1; then
  echo "Install Supabase CLI: https://supabase.com/docs/guides/cli"
  exit 1
fi

cp -n .env.example .env 2>/dev/null || true
cp -n supabase/.env.example supabase/.env.local 2>/dev/null || true

echo "==> supabase start"
supabase start

echo "==> supabase db reset (migrations + seed.sql)"
supabase db reset

echo "==> Writing .env.from-status (merge into Flutter + Admin .env — never commit)"
supabase status -o env > .env.from-status || true

echo ""
echo "Done. Next:"
echo "  1) Open .env.from-status — copy API URL + anon key into Star_Sitter_Family/.env and Star_Sitter_Baby_Sitter/.env"
echo "  2) Copy service_role line into supabase/.env.local for: supabase functions serve --env-file supabase/.env.local"
echo "  3) Set WEBHOOK_SECRET in supabase/.env.local (openssl rand -hex 32) — match Dashboard webhooks when using hosted"
echo "  4) Admin: StarSitters_Admin/starsitters-admin/.env.local — see RUN_LOCAL.md in PIXORAFT1 workspace"
