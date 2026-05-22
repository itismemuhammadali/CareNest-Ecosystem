#!/usr/bin/env bash
# Push Edge Function secrets to the *linked* hosted Supabase project.
# Prerequisites: `supabase login`, `supabase link --project-ref <ref>`
#
# 1) cp .env.example .env
# 2) Put **rotated** values only in .env (never commit .env).
# 3) Run: bash scripts/push-hosted-secrets.sh
#
# FCM JSON must be one line. Example:
#   FCM_SERVICE_ACCOUNT_JSON=$(jq -c . < /path/to/new-service-account.json)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if ! command -v supabase >/dev/null 2>&1; then
  echo "Install Supabase CLI."
  exit 1
fi
if [[ ! -f .env ]]; then
  echo "Missing .env — copy .env.example to .env and fill with rotated secrets."
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

if [[ -z "${WEBHOOK_SECRET:-}" || -z "${APP_BASE_URL:-}" ]]; then
  echo "WEBHOOK_SECRET and APP_BASE_URL are required in .env"
  exit 1
fi

ARGS=(
  "WEBHOOK_SECRET=${WEBHOOK_SECRET}"
  "APP_BASE_URL=${APP_BASE_URL}"
)
[[ -n "${RESEND_API_KEY:-}" ]] && ARGS+=("RESEND_API_KEY=${RESEND_API_KEY}")
[[ -n "${EMAIL_FROM:-}" ]] && ARGS+=("EMAIL_FROM=${EMAIL_FROM}")
[[ -n "${FCM_PROJECT_ID:-}" ]] && ARGS+=("FCM_PROJECT_ID=${FCM_PROJECT_ID}")
[[ -n "${FCM_SERVICE_ACCOUNT_JSON:-}" ]] && ARGS+=("FCM_SERVICE_ACCOUNT_JSON=${FCM_SERVICE_ACCOUNT_JSON}")

echo "Pushing ${#ARGS[@]} secret(s) to linked project (values not printed)."
supabase secrets set "${ARGS[@]}"

echo "Done. In SQL Editor, set providers if you want real sends:"
echo "  update public.system_config set value = '\"live\"'::jsonb where key = 'fcm_provider';"
echo "  update public.system_config set value = '\"resend\"'::jsonb where key = 'email_provider';"
