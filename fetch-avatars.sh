#!/usr/bin/env bash
# Fetch Instagram profile pictures for all alumni.
# Tries HD JSON API first, falls back to og:image scrape.
# Re-run periodically: IG CDN signatures expire and profile pics change.

set -u
cd "$(dirname "$0")"
mkdir -p avatars

HANDLES=(
  ani_aesthetic1 monmart.visuals zara.aiads hagency.ai melaniacreates
  ai.anyawanessian ai.byanush heema_studio_ elendoes.ai aeloria_ai
  pure.visuals.ai ani_ai_digital aiclubyerevan ai_fabric sylvie.aiexperience
  aiwithann maneharutyunian lia.ai.creator houseofaivision annaai_creativestudio
  softlight_lab neuralstructure by_marsim aintes_arm ai_lab_armenia
  silver.ai.agency aibooben ai_visuals_by_ani ai.withmane tatev.visuals
  your__ai__creator aidailydiary aiwithsat directed_fantasy ann_mdbrd
  nuneaicreator aiwithani_creator
  armimarti_yan lilart_ai scripted._ai gohar_creates_with_ai victoria.yvn
  badalian.ai ai.creator.ani yourfridayai sssaiart.226 dg.goga
  sarah.ai.studio aiwithhelin narek.ai.lab ai_with_g ai_by_human
  karineeee_ai ja_vie_co
)

get_hd_url() {
  # Returns profile_pic_url_hd via web_profile_info JSON
  curl -s -L \
    -A "Instagram 219.0.0.12.117 Android" \
    -H "X-IG-App-ID: 936619743392459" \
    --max-time 12 \
    "https://i.instagram.com/api/v1/users/web_profile_info/?username=$1" \
    | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    u = d.get('data', {}).get('user') or {}
    print(u.get('profile_pic_url_hd') or u.get('profile_pic_url') or '')
except Exception:
    print('')
" 2>/dev/null
}

get_og_url() {
  # Returns og:image content from rendered profile page (Slackbot/FB UA)
  curl -s -L -A "facebookexternalhit/1.1" --max-time 10 "https://www.instagram.com/$1/" \
    | grep -oE 'property="og:image" content="[^"]+"' \
    | head -1 \
    | sed -E 's/.*content="([^"]+)".*/\1/' \
    | sed 's/&amp;/\&/g'
}

download() {
  local out="$1" url="$2"
  curl -s -L --max-time 15 -o "$out" "$url" || { rm -f "$out"; return 1; }
  [[ -s "$out" ]] || { rm -f "$out"; return 1; }
  # Reject IG's logo placeholder (778568 bytes — served when profile pic unavailable)
  local sz=$(wc -c < "$out" | tr -d ' ')
  if [[ "$sz" == "778568" ]]; then
    rm -f "$out"
    return 1
  fi
  return 0
}

ok=0
fail=0
failed_handles=()

for h in "${HANDLES[@]}"; do
  out="avatars/${h}.jpg"

  # Try 1: HD JSON
  url=$(get_hd_url "$h")
  if [[ -n "$url" ]] && download "$out" "$url"; then
    sz=$(wc -c < "$out" | tr -d ' ')
    echo "✓ $h (hd, $sz bytes)"
    ok=$((ok+1))
    sleep 0.5
    continue
  fi

  # Try 2: og:image scrape (different endpoint, different rate limit)
  url=$(get_og_url "$h")
  if [[ -n "$url" ]] && download "$out" "$url"; then
    sz=$(wc -c < "$out" | tr -d ' ')
    echo "✓ $h (og,  $sz bytes)"
    ok=$((ok+1))
    sleep 0.8
    continue
  fi

  rm -f "$out"
  echo "✗ $h"
  failed_handles+=("$h")
  fail=$((fail+1))
  sleep 1
done

echo ""
echo "Done. $ok ok, $fail failed."
[[ $fail -gt 0 ]] && echo "Failed: ${failed_handles[*]}"
