#!/usr/bin/env bash
set -euo pipefail

echo "Reading current power profile..."
ORIGINAL_PROFILE="$(powerprofilesctl get)"
echo "Current profile is: $ORIGINAL_PROFILE"

if [[ "$ORIGINAL_PROFILE" == "performance" ]]; then
  NEW_PROFILE="balanced"
else
  NEW_PROFILE="performance"
fi

echo "Switching to different temporary profile: $NEW_PROFILE"
powerprofilesctl set "$NEW_PROFILE"

echo "Waiting 5 seconds..."
sleep 5

echo "Switching back to original profile: $ORIGINAL_PROFILE"
powerprofilesctl set "$ORIGINAL_PROFILE"

echo "Done."