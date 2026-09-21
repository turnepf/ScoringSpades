#!/bin/sh
# Verify the committed ios/ScoringSpades.xcodeproj still matches ios/project.yml.
#
# Why this exists: project.yml is the declared source of truth, but Xcode
# archives from the committed .xcodeproj. Nothing else checks that the two
# agree. They have already drifted once — at commit ad9d94f, project.yml
# declared MARKETING_VERSION 1.1 / build 2 and the Associated Domains
# entitlement while the committed pbxproj still read 1.0 / build 1 with no
# CODE_SIGN_ENTITLEMENTS at all. They disagreed for two commits.
#
# This check is non-mutating: it regenerates, compares, then restores whatever
# was there before, so it can never leave the working tree changed.
#
# Usage:  ios/scripts/check-project-sync.sh
# Exit:   0 = in sync, 1 = drift (or xcodegen missing)

set -eu

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
ios_dir="$repo_root/ios"
pbxproj="$ios_dir/ScoringSpades.xcodeproj/project.pbxproj"

if ! command -v xcodegen >/dev/null 2>&1; then
  echo "check-project-sync: xcodegen not installed (brew install xcodegen)" >&2
  exit 1
fi

if [ ! -f "$pbxproj" ]; then
  echo "check-project-sync: $pbxproj not found" >&2
  exit 1
fi

backup=$(mktemp -t scoringspades-pbxproj)
cp "$pbxproj" "$backup"
# Always put the original back, whatever happens below.
trap 'cp "$backup" "$pbxproj" 2>/dev/null || true; rm -f "$backup"' EXIT INT TERM

( cd "$ios_dir" && xcodegen generate --quiet )

if cmp -s "$pbxproj" "$backup"; then
  echo "check-project-sync: OK — .xcodeproj matches project.yml"
  exit 0
fi

echo "check-project-sync: DRIFT — the committed .xcodeproj does not match project.yml." >&2
echo "" >&2
echo "  Xcode archives from the .xcodeproj, so what ships is what is committed," >&2
echo "  not what project.yml declares. Regenerate and commit the result:" >&2
echo "" >&2
echo "    cd ios && xcodegen && git add ScoringSpades.xcodeproj && git commit" >&2
echo "" >&2
echo "  Differences (regenerated vs committed):" >&2
diff "$backup" "$pbxproj" | head -40 >&2 || true
exit 1
