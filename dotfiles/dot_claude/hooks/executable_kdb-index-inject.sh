#!/bin/bash
# SessionStart: inject the kdb index so every session starts AWARE of what's in
# the user's knowledge base. The companion to kdb-inbox-check.sh (which nags
# about WRITES); this one enables READS. Registered in a Claude settings.json
# SessionStart hook. Fail-safe: if kdb/index.md is missing, emit nothing and
# never block session start.
# Vault location: $KDB_ROOT if set, else ~/Notes/kdb.
KDB="${KDB_ROOT:-$HOME/Notes/kdb}"
INDEX="$KDB/index.md"
[ -f "$INDEX" ] || exit 0

# Optional: point $KDB_HUMAN_ONLY at a sibling folder of raw human-only
# material the agent must not read on its own. Mentioned in the preamble only
# when it is set and actually exists.
ARCHIVE="${KDB_HUMAN_ONLY:-}"
[ -n "$ARCHIVE" ] && [ -d "$ARCHIVE" ] || ARCHIVE=""

python3 - "$INDEX" "$KDB" "$ARCHIVE" <<'PY'
import json, os, sys
try:
    idx = open(sys.argv[1], encoding="utf-8").read()
except Exception:
    sys.exit(0)

home = os.path.expanduser("~")


def tilde(p):
    return "~" + p[len(home):] if p.startswith(home + os.sep) else p


root = tilde(sys.argv[2])
archive = sys.argv[3]
archive_note = (f"{tilde(archive)}/ is human-only — do not read it "
                "autonomously. ") if archive else ""

preamble = (
    f"The user's knowledge base (kdb at {root}) — the agent-facing knowledge "
    "surface. Its index is below (one line per page). When a task overlaps an "
    f"entry, READ that page ({root}/<path>.md) and follow its [[wikilinks]] "
    "before answering — this is the user's curated, fact-checked memory, prefer "
    "it over guessing. Contribute knowledge ONLY by dropping a file in "
    f"{root}/inbox/ and using the kdb-librarian skill; never hand-edit pages. "
    f"{archive_note}".rstrip() + "\n\n---\n\n"
)
print(json.dumps({"hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": preamble + idx,
}}))
PY
