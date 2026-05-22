#!/usr/bin/env bash
# Create an extra family account (pending BG) for admin demos.
# Uses Auth Admin API: POST /auth/v1/admin/users — same as Dashboard "Add user",
# so existing trigger public.handle_new_auth_user() creates public.users + family_profiles.
#
# Prereqs: starsitters-backend/.env with SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY
# Run from repo root:
#   bash scripts/seed-pending-family.sh
# Optional overrides:
#   EMAIL=demo@example.com PASSWORD='Str0ng!' FULL_NAME='Casey Lee' bash scripts/seed-pending-family.sh

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [[ ! -f .env ]]; then
  echo "Missing .env — copy from .env.example and set SUPABASE_URL + SUPABASE_SERVICE_ROLE_KEY" >&2
  exit 1
fi

set -a
# shellcheck disable=1090
source .env
set +a

if [[ -z "${SUPABASE_URL:-}" || -z "${SUPABASE_SERVICE_ROLE_KEY:-}" ]]; then
  echo "SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY must be set in .env" >&2
  exit 1
fi

BASE="${SUPABASE_URL%/}"
EMAIL="${EMAIL:-demo.pending.family+$(date +%s)@starsitters.invalid}"
PASSWORD="${PASSWORD:-DemoFamilyPending2026!}"
FULL_NAME="${FULL_NAME:-Demo Pending Family}"

BODY_JSON="$(
  EMAIL="$EMAIL" PASSWORD="$PASSWORD" FULL_NAME="$FULL_NAME" python3 -c '
import json, os
print(json.dumps({
  "email": os.environ["EMAIL"],
  "password": os.environ["PASSWORD"],
  "email_confirm": True,
  "user_metadata": {
    "role": "family",
    "full_name": os.environ["FULL_NAME"],
  },
}))
')"

TMP="$(mktemp)"
HTTP=$(curl -sS -o "$TMP" -w "%{http_code}" -X POST "$BASE/auth/v1/admin/users" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_ROLE_KEY" \
  -H "apikey: $SUPABASE_SERVICE_ROLE_KEY" \
  -H "Content-Type: application/json" \
  -d "$BODY_JSON")

cat "$TMP"
rm -f "$TMP"
echo ""

if [[ "$HTTP" != "200" && "$HTTP" != "201" ]]; then
  echo "Auth admin API returned HTTP $HTTP (see body above)." >&2
  exit 1
fi

echo ""
echo "Created family auth user:"
echo "  Email:    $EMAIL"
echo "  Password: (value you passed; default shown only if you used default PASSWORD env)"
echo "  Name:     $FULL_NAME"
echo "Refresh /families in the admin portal to see a second Pending row."
