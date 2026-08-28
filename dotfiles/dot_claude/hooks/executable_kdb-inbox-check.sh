#!/bin/bash
# Detect files in the kdb inbox and inject an ingestion reminder.
# Registered in a Claude settings.json UserPromptSubmit hook — the nag is
# scoped to the sessions that opt in, by design.
# Vault location: $KDB_ROOT if set, else ~/Notes/kdb.
KDB="${KDB_ROOT:-$HOME/Notes/kdb}"
INBOX="$KDB/inbox"

n=$(find "$INBOX" -type f ! -name '.gitkeep' 2>/dev/null | wc -l | tr -d ' ')

if [ "$n" -gt 0 ]; then
  noun="files"
  [ "$n" -eq 1 ] && noun="file"
  msg="KDB inbox has $n $noun pending ingestion — use the kdb-librarian skill (ingest) when appropriate."
  printf '{"hookSpecificOutput":{"hookEventName":"UserPromptSubmit","additionalContext":"%s"}}\n' "$msg"
fi
