#!/usr/bin/env bash
# fetch_and_analyze.sh — Fetch all PR data and Atlantis analysis in one shot.
#
# Usage: fetch_and_analyze.sh OWNER REPO PR_NUMBER [SKILL_DIR]
#
# Outputs a single JSON object to stdout:
#   {
#     "meta":     { title, author, headRefName, baseRefName, state, url },
#     "files":    ["path/to/file", ...],
#     "diff":     "<full unified diff>",
#     "atlantis": { plan_summaries, destructions, replacements, policy_warns, ... }
#   }
#
# All gh calls run in parallel. Requires: gh, python3 (stdlib only).

set -euo pipefail

OWNER="${1:?Usage: fetch_and_analyze.sh OWNER REPO PR_NUMBER [SKILL_DIR]}"
REPO="${2:?}"
PR="${3:?}"
SKILL_DIR="${4:-$(cd "$(dirname "$0")/.." && pwd)}"
PARSER="$SKILL_DIR/scripts/parse_atlantis.py"

TMPDIR_WORK=$(mktemp -d)
trap 'rm -rf "$TMPDIR_WORK"' EXIT

META_FILE="$TMPDIR_WORK/meta.json"
FILES_FILE="$TMPDIR_WORK/files.json"
DIFF_FILE="$TMPDIR_WORK/diff.txt"
ATLANTIS_FILE="$TMPDIR_WORK/atlantis.json"

# --- Parallel fetches ---

gh pr view "$PR" --repo "$OWNER/$REPO" \
  --json title,body,author,baseRefName,headRefName,state,url \
  > "$META_FILE" &
PID_META=$!

gh pr view "$PR" --repo "$OWNER/$REPO" \
  --json files --jq '[.files[].path]' \
  > "$FILES_FILE" &
PID_FILES=$!

gh pr diff "$PR" --repo "$OWNER/$REPO" \
  > "$DIFF_FILE" &
PID_DIFF=$!

(
  gh api "repos/$OWNER/$REPO/issues/$PR/comments" --paginate \
    --jq '.[] | select(.user.login | test("atlantis|github-actions"; "i")) | {id:.id,body:.body,created_at:.created_at}' \
  | python3 "$PARSER" --mode all
) > "$ATLANTIS_FILE" &
PID_ATLANTIS=$!

# Wait for all and propagate first failure
FAIL=0
wait "$PID_META"    || { echo "ERROR: gh pr view (meta) failed" >&2;     FAIL=1; }
wait "$PID_FILES"   || { echo "ERROR: gh pr view (files) failed" >&2;    FAIL=1; }
wait "$PID_DIFF"    || { echo "ERROR: gh pr diff failed" >&2;            FAIL=1; }
wait "$PID_ATLANTIS"|| { echo "ERROR: Atlantis fetch/parse failed" >&2;  FAIL=1; }
[ "$FAIL" -eq 0 ] || exit 1

# --- Combine into single JSON ---
python3 - "$META_FILE" "$FILES_FILE" "$DIFF_FILE" "$ATLANTIS_FILE" <<'PYEOF'
import sys, json

meta_file, files_file, diff_file, atlantis_file = sys.argv[1:]

with open(meta_file)     as f: meta     = json.load(f)
with open(files_file)    as f: files    = json.load(f)
with open(diff_file)     as f: diff     = f.read()
with open(atlantis_file) as f: atlantis = json.load(f)

print(json.dumps({
    "meta":     meta,
    "files":    files,
    "diff":     diff,
    "atlantis": atlantis,
}, indent=2))
PYEOF
