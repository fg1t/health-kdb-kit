#!/bin/sh
# scan-secrets.sh — the executable half of the health-kdb-kit credential +
# personal-content leak gate.
# Scope: every commit authored to this kit — a clean scan is a precondition
# of `git commit`, not of `chezmoi apply`.
#
# Usage:  ./scan-secrets.sh [path-or-repo ...]     exit 1 on any hit
#         no args => scans "." (repo-root convention: every later task's
#         commit step runs this bare, from the repo root, before `git add`)
# Pattern list v1 (versioned here; extend deliberately, in this file only).
# Note: scans PATHS on disk (files/dirs), by design — point it at the files
# you are about to commit. It is deliberately NOT a `git diff --cached` hook;
# keep it path-based.
set -eu

[ "$#" -gt 0 ] || set -- .

# Token shapes actually observed or plausible:
#   - API-management subscription-key headers
#   - Anthropic / OpenAI-style keys, GitHub PATs classic+fine-grained
#   - PEM private keys, JWTs, generic 32+ hex adjacent to key/token/secret
#
# Personal-content markers for this deployment: this is a *public* repo, so
# zero personal content of the operator or contacts may ever land in a
# commit here (see task-2 brief for the literal values this guards). Each
# marker below is written with a single-char bracket class spliced into it
# so the literal banned string never appears contiguously in this file's own
# bytes — belt-and-suspenders with the --exclude=scan-secrets.sh self-
# exemption on every grep call below (either one alone would be enough).
PATTERNS='(ocp-apim-subscription-key|subscription[-_]key)[ "'"'"':=]+[A-Za-z0-9]{16,}
ANTHROPIC_API_KEY[ ]*=
sk-ant-[A-Za-z0-9_-]{10,}
sk-[A-Za-z0-9]{32,}
ghp_[A-Za-z0-9]{20,}
github_pat_[A-Za-z0-9_]{20,}
xox[bp]-[0-9]
AKIA[A-Z0-9]{16}
BEGIN (RSA |OPENSSH |EC |DSA )?PRIVATE KEY
eyJhbGciOi
[a-f0-9]{32,}[ ]*#?[ ]*(key|token|secret)'

# Deploy-local identity patterns (owner/assistant names, addresses) live in
# the gitignored sibling scan-secrets.local — one extended-regex per line.
# Identity tokens must never be tracked here: even a bracket-defused pattern
# in a published repo IS the leak it exists to prevent.
LOCAL="$(dirname "$0")/scan-secrets.local"
if [ -f "$LOCAL" ]; then
  PATTERNS="$PATTERNS
$(cat "$LOCAL")"
fi

status=0
for target in "$@"; do
  echo "$PATTERNS" | while IFS= read -r p; do
    [ -n "$p" ] || continue
    if grep -rniE --exclude-dir=.git --exclude=scan-secrets.sh --exclude=scan-secrets.local -- "$p" "$target" 2>/dev/null | head -3 | grep -q .; then
      echo "HIT [$p] in $target:"
      grep -rniE --exclude-dir=.git --exclude=scan-secrets.sh -l -- "$p" "$target" 2>/dev/null | head -5
      exit 1
    fi
  done || status=1
done
[ "$status" -eq 0 ] && echo "scan-secrets: clean ($# target(s))"
exit "$status"
