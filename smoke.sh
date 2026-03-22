#!/usr/bin/env bash

set -euo pipefail

BASE="${BASE:-https://api.clickajans.net}"
TOKEN="${TOKEN:-}"
PROVIDER_ID="${PROVIDER_ID:-}"
BOOKING_ID="${BOOKING_ID:-}"
CHAT_ID="${CHAT_ID:-}"

auth_header=()
if [[ -n "$TOKEN" ]]; then
  auth_header=(-H "Authorization: Bearer $TOKEN")
fi

section() {
  printf '\n== %s ==\n' "$1"
}

run() {
  local label="$1"
  shift
  printf '\n-- %s --\n' "$label"
  "$@"
  printf '\n'
}

skip_if_missing() {
  local value="$1"
  local label="$2"
  if [[ -z "$value" ]]; then
    printf '\n-- %s --\nSKIPPED: missing required env var\n' "$label"
    return 0
  fi
  return 1
}

section "Config"
printf 'BASE=%s\n' "$BASE"
printf 'TOKEN=%s\n' "${TOKEN:+<set>}"
printf 'PROVIDER_ID=%s\n' "${PROVIDER_ID:-<unset>}"
printf 'BOOKING_ID=%s\n' "${BOOKING_ID:-<unset>}"
printf 'CHAT_ID=%s\n' "${CHAT_ID:-<unset>}"

section "Auth"
if [[ -n "$TOKEN" ]]; then
  run "GET /v1/me" curl -sS "${auth_header[@]}" "$BASE/v1/me"
else
  echo "SKIPPED: TOKEN not set"
fi

section "Providers"
run "GET /v1/providers" curl -sS "$BASE/v1/providers"
if ! skip_if_missing "$PROVIDER_ID" "GET /v1/providers/:id"; then
  run "GET /v1/providers/$PROVIDER_ID" curl -sS "$BASE/v1/providers/$PROVIDER_ID"
fi

section "Favorites"
if [[ -n "$TOKEN" ]]; then
  run "GET /v1/favorites" curl -sS "${auth_header[@]}" "$BASE/v1/favorites"
  if ! skip_if_missing "$PROVIDER_ID" "POST /v1/favorites/:providerId"; then
    run "POST /v1/favorites/$PROVIDER_ID" \
      curl -sS -X POST "${auth_header[@]}" "$BASE/v1/favorites/$PROVIDER_ID"
  fi
  if ! skip_if_missing "$PROVIDER_ID" "DELETE /v1/favorites/:providerId"; then
    run "DELETE /v1/favorites/$PROVIDER_ID" \
      curl -sS -X DELETE "${auth_header[@]}" "$BASE/v1/favorites/$PROVIDER_ID"
  fi
else
  echo "SKIPPED: TOKEN not set"
fi

section "Bookings"
if [[ -n "$TOKEN" ]]; then
  if ! skip_if_missing "$PROVIDER_ID" "POST /v1/bookings"; then
    run "POST /v1/bookings" \
      curl -sS -X POST "${auth_header[@]}" \
      -H "Content-Type: application/json" \
      -d "{
        \"nanny_id\": \"$PROVIDER_ID\",
        \"start_time\": \"2026-03-24T08:00:00Z\",
        \"end_time\": \"2026-03-24T12:00:00Z\"
      }" \
      "$BASE/v1/bookings"
  fi
  run "GET /v1/bookings" curl -sS "${auth_header[@]}" "$BASE/v1/bookings"
  if ! skip_if_missing "$BOOKING_ID" "GET /v1/bookings/:id"; then
    run "GET /v1/bookings/$BOOKING_ID" \
      curl -sS "${auth_header[@]}" "$BASE/v1/bookings/$BOOKING_ID"
  fi
  if ! skip_if_missing "$BOOKING_ID" "PATCH /v1/bookings/:id/cancel"; then
    run "PATCH /v1/bookings/$BOOKING_ID/cancel" \
      curl -sS -X PATCH "${auth_header[@]}" "$BASE/v1/bookings/$BOOKING_ID/cancel"
  fi
else
  echo "SKIPPED: TOKEN not set"
fi

section "Notifications"
if [[ -n "$TOKEN" ]]; then
  run "GET /v1/notifications" curl -sS "${auth_header[@]}" "$BASE/v1/notifications"
else
  echo "SKIPPED: TOKEN not set"
fi

section "Chats"
if [[ -n "$TOKEN" ]]; then
  run "GET /v1/chats" curl -sS "${auth_header[@]}" "$BASE/v1/chats"
  if ! skip_if_missing "$CHAT_ID" "GET /v1/chats/:id/messages"; then
    run "GET /v1/chats/$CHAT_ID/messages" \
      curl -sS "${auth_header[@]}" "$BASE/v1/chats/$CHAT_ID/messages"
  fi
  if ! skip_if_missing "$CHAT_ID" "POST /v1/chats/:id/messages"; then
    run "POST /v1/chats/$CHAT_ID/messages" \
      curl -sS -X POST "${auth_header[@]}" \
      -H "Content-Type: application/json" \
      -d '{
        "text": "Hello from smoke.sh"
      }' \
      "$BASE/v1/chats/$CHAT_ID/messages"
  fi
  run "GET /v1/calls" curl -sS "${auth_header[@]}" "$BASE/v1/calls"
else
  echo "SKIPPED: TOKEN not set"
fi

section "Payment Methods"
if [[ -n "$TOKEN" ]]; then
  run "GET /v1/payment-methods" curl -sS "${auth_header[@]}" "$BASE/v1/payment-methods"
  run "POST /v1/payment-methods" \
    curl -sS -X POST "${auth_header[@]}" \
    -H "Content-Type: application/json" \
    -d '{
      "brand": "VISA",
      "card_number": "8364937509307302",
      "holder_name": "Zubaedah Valcova",
      "exp_month": 22,
      "exp_year": 2030,
      "cvc": "847"
    }' \
    "$BASE/v1/payment-methods"
else
  echo "SKIPPED: TOKEN not set"
fi
