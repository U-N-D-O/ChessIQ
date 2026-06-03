#!/bin/sh

set -eu

default_app_id="ca-app-pub-3940256099942544~1458002511"
resolved_app_id="${ADMOB_IOS_APP_ID:-}"
force_test_ads="${ADMOB_FORCE_TEST_ADS:-}"

if [ -n "${DART_DEFINES:-}" ]; then
  decoded_values="$(python3 - <<'PY'
import base64
import os

decoded = {}
for encoded in filter(None, os.environ.get('DART_DEFINES', '').split(',')):
    padding = '=' * (-len(encoded) % 4)
    entry = base64.urlsafe_b64decode(encoded + padding).decode('utf-8')
    key, sep, value = entry.partition('=')
    if sep:
        decoded[key] = value

print(decoded.get('ADMOB_IOS_APP_ID', ''))
print(decoded.get('ADMOB_FORCE_TEST_ADS', ''))
PY
)"
  decoded_app_id="$(printf '%s\n' "$decoded_values" | sed -n '1p')"
  decoded_force_test_ads="$(printf '%s\n' "$decoded_values" | sed -n '2p')"
  if [ -n "$decoded_app_id" ]; then
    resolved_app_id="$decoded_app_id"
  fi
  if [ -n "$decoded_force_test_ads" ]; then
    force_test_ads="$decoded_force_test_ads"
  fi
fi

if [ "$force_test_ads" = "true" ] || [ "$force_test_ads" = "TRUE" ]; then
  resolved_app_id="$default_app_id"
fi

if [ -z "$resolved_app_id" ]; then
  resolved_app_id="$default_app_id"
fi

plist_path="${TARGET_BUILD_DIR}/${INFOPLIST_PATH}"

/usr/libexec/PlistBuddy -c "Set :GADApplicationIdentifier $resolved_app_id" "$plist_path" \
  || /usr/libexec/PlistBuddy -c "Add :GADApplicationIdentifier string $resolved_app_id" "$plist_path"