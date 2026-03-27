#!/usr/bin/env bash
# check-wikipedia.sh
# Fetches the latest Wikipedia "Signs of AI writing" page and outputs
# a diff against the stored snapshot. Used by the weekly cron job.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SNAPSHOT="$REPO_DIR/references/wikipedia-snapshot.txt"
TMP="$(mktemp)"

# Fetch latest revision
curl -s "https://en.wikipedia.org/w/api.php?action=query&titles=Wikipedia:Signs_of_AI_writing&prop=revisions&rvprop=content|ids&rvslots=main&format=json" \
  | python3 -c "
import json, sys
data = json.load(sys.stdin)
pages = data['query']['pages']
for pid, page in pages.items():
    rev = page['revisions'][0]
    revid = rev['revid']
    content = rev['slots']['main']['*']
    print(f'REVID:{revid}')
    print(content)
" > "$TMP"

OLD_REVID=$(head -1 "$SNAPSHOT" | sed 's/REVID://')
NEW_REVID=$(head -1 "$TMP" | sed 's/REVID://')

if [ "$OLD_REVID" = "$NEW_REVID" ]; then
  echo "NO_CHANGE:$OLD_REVID"
  rm "$TMP"
  exit 0
fi

echo "CHANGED:$OLD_REVID->$NEW_REVID"
diff <(tail -n +2 "$SNAPSHOT") <(tail -n +2 "$TMP") || true
cp "$TMP" "$SNAPSHOT"
rm "$TMP"
