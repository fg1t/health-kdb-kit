#!/usr/bin/env bash
# health-kdb-kit bootstrap — one-shot, idempotent setup of a friend's health-research
# assistant Mac. Run it from the kit clone, as the target Mac's primary user, with
# internet up:
#
#   cd ~/health-kdb-kit && ./bootstrap.sh
#
# Re-running is safe: every phase checks before it acts. Answers to the identity
# prompts are cached in setup.local (gitignored) so re-runs don't re-ask. Interactive
# steps the script cannot do (Claude login, Google OAuth) are printed as a checklist
# (Phase 6) — README walks through them.
#
# Testability contract (Task 9 depends on these): every target derives from
# overridable env — TARGET_HOME, VAULT, CLAUDE_DIR — plus KDB_KIT_REPO for offline/
# sandbox tests, and SKIP_TOOLCHAIN=1 / SKIP_DOTFILES=1 seams for CI/sandbox runs.
set -euo pipefail

KIT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

TARGET_HOME="${TARGET_HOME:-$HOME}"
VAULT="${VAULT:-$TARGET_HOME/Notes/kdb}"
CLAUDE_DIR="${CLAUDE_DIR:-$TARGET_HOME/.claude}"
STAGED_DOTFILES="$TARGET_HOME/.local/share/health-kit-dotfiles"

# The public machinery kit this overlay composes (machinery-only, leak-gated).
# Env-overridable so a local/staged export can be tested before publishing.
KDB_KIT_REPO="${KDB_KIT_REPO:-https://github.com/fg1t/kdb-kit}"

TMPROOT="$(mktemp -d)"; trap 'rm -rf "$TMPROOT"' EXIT

banner() { printf '\n\033[1m== %s ==\033[0m\n' "$*"; }
ok()     { printf '   \033[32m✓\033[0m %s\n' "$*"; }
skip()   { printf '   \033[33m∙\033[0m %s (already done)\n' "$*"; }

# ── Phase 0: identity ─────────────────────────────────────────────────────────
banner "Phase 0: identity"
if [ -f "$KIT/setup.local" ]; then
  # shellcheck disable=SC1091
  source "$KIT/setup.local"
  : "${HER_GMAIL:?setup.local is missing HER_GMAIL}"
  skip "identity loaded from setup.local (${HER_NAME:?} / ${ASSISTANT_NAME:?})"
else
  read -rp "Owner's name (how the assistant addresses her): " HER_NAME
  read -rp "Assistant's name (what she calls it): " ASSISTANT_NAME
  read -rp "Her Gmail address: " HER_GMAIL
  printf 'HER_NAME=%q\nASSISTANT_NAME=%q\nHER_GMAIL=%q\n' \
    "$HER_NAME" "$ASSISTANT_NAME" "$HER_GMAIL" > "$KIT/setup.local"
  ok "saved to setup.local (gitignored)"
fi

# Literal string replacement (python3, not sed: names with &, |, \ must not
# corrupt the substitution; /usr/bin/python3 ships with the Xcode CLT).
subst() {
  S_HER_NAME="$HER_NAME" S_ASSISTANT_NAME="$ASSISTANT_NAME" \
  S_HER_GMAIL="$HER_GMAIL" S_KIT="$KIT" S_TARGET_HOME="$TARGET_HOME" python3 -c '
import os, sys
s = sys.stdin.read()
for token, val in (("__HER_NAME__", os.environ["S_HER_NAME"]),
                   ("__ASSISTANT_NAME__", os.environ["S_ASSISTANT_NAME"]),
                   ("__HER_GMAIL__", os.environ["S_HER_GMAIL"]),
                   ("__HOME__", os.environ["S_TARGET_HOME"]),
                   ("__KIT_HOME__", os.environ["S_KIT"])):
    s = s.replace(token, val)
sys.stdout.write(s)'
}

# ── Phase 1: toolchain ────────────────────────────────────────────────────────
banner "Phase 1: toolchain (Xcode CLT, Homebrew, packages, Claude Code)"
if [ "${SKIP_TOOLCHAIN:-0}" = "1" ]; then
  skip "toolchain (SKIP_TOOLCHAIN=1)"
else
  if ! xcode-select -p >/dev/null 2>&1; then
    echo "   Xcode Command Line Tools missing — a dialog will open; finish it, then re-run."
    xcode-select --install || true
    exit 1
  fi
  ok "Xcode CLT"
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
  ok "Homebrew $(brew --version | head -1)"
  brew bundle --file "$KIT/Brewfile" --no-upgrade
  ok "brew bundle"
  if ! command -v claude >/dev/null 2>&1; then
    npm install -g @anthropic-ai/claude-code
  fi
  ok "Claude Code $(claude --version 2>/dev/null || echo '(installed)')"
fi

# ── Phase 2: dotfiles ─────────────────────────────────────────────────────────
banner "Phase 2: dotfiles (staged copy → chezmoi apply)"
if [ "${SKIP_DOTFILES:-0}" = "1" ]; then
  skip "dotfiles (SKIP_DOTFILES=1)"
else
  mkdir -p "$STAGED_DOTFILES"
  rsync -a --delete "$KIT/dotfiles/" "$STAGED_DOTFILES/"
  # identity lands in the staged copy only — never in the kit clone
  subst < "$KIT/dotfiles/dot_gitconfig" > "$STAGED_DOTFILES/dot_gitconfig"
  if [ "$TARGET_HOME" = "$HOME" ]; then
    chezmoi apply --source "$STAGED_DOTFILES" --force
    ok "dotfiles applied (source: $STAGED_DOTFILES; re-apply with the same command)"
  else
    echo "   ⚠ TARGET_HOME ($TARGET_HOME) != \$HOME — refusing to chezmoi-apply into the real"
    echo "     home. Staged + substituted the dotfiles for inspection only; apply is skipped."
    ok "dotfiles staged + substituted (chezmoi apply skipped — sandbox mode)"
  fi
fi

# ── Phase 3: vault ─────────────────────────────────────────────────────────────
banner "Phase 3: kdb vault at $VAULT"
KSRC="$TMPROOT/kdb-kit"
git clone -q --depth 1 "$KDB_KIT_REPO" "$KSRC"
mkdir -p "$(dirname "$VAULT")"
# .kdb/types.json is both the kit's own registry AND the extension point the
# owner is told to use for her personal-health folder (README "Her own data").
# On EITHER path it must be a merge, kit keys authoritative, unknown (owner-
# added) keys preserved — never a blind overwrite, or a kit update silently
# de-registers whatever she added (verified failure: C1).
merge_types_json() {
  # $1 = destination types.json (may not exist yet)
  local dest="$1" kit_types="$KIT/vault/.kdb/types.json"
  if [ -f "$dest" ]; then
    local merged
    merged="$(jq -s '.[0] * .[1]' "$dest" "$kit_types")"
    printf '%s\n' "$merged" > "$dest"
  else
    cp "$kit_types" "$dest"
  fi
}

if [ -d "$VAULT" ]; then
  # Existing vault: re-overlay ONLY machinery — .scripts, templates, CLAUDE.md
  # (the schema contract — machinery, not owner content), .kdb/types.json,
  # the librarian skill (Phase 4) — never pages, inbox/, attachments/, or kit.json.
  rsync -a --delete "$KSRC/.scripts/" "$VAULT/.scripts/"
  rsync -a "$KIT/vault/templates/" "$VAULT/templates/"
  cp "$KIT/vault/CLAUDE.md" "$VAULT/CLAUDE.md"
  mkdir -p "$VAULT/.kdb"
  merge_types_json "$VAULT/.kdb/types.json"
  ok "vault machinery re-overlaid (pages, inbox/, attachments/, kit.json untouched; CLAUDE.md refreshed; .kdb/types.json merged, not overwritten)"
else
  mkdir -p "$VAULT"
  # kit machinery: everything except .git, claude-setup (that's Phase 4), LICENSE
  # (repo-only; a clone must still lint clean without it)
  rsync -a --exclude .git --exclude claude-setup --exclude LICENSE "$KSRC/" "$VAULT/"
  # health overlay: her vault contract, type registry, templates, seed pages
  cp "$KIT/vault/CLAUDE.md" "$VAULT/CLAUDE.md"
  mkdir -p "$VAULT/.kdb"
  merge_types_json "$VAULT/.kdb/types.json"
  rsync -a "$KIT/vault/templates/" "$VAULT/templates/"
  for d in claims conditions interventions studies topics; do
    mkdir -p "$VAULT/$d"
    rsync -a "$KIT/vault/$d/" "$VAULT/$d/"
  done
  mkdir -p "$VAULT/inbox" "$VAULT/attachments"
  # per-vault tier config: copies only if absent, never overwritten on re-run
  cp -n "$KIT/config/kit.json" "$VAULT/.kdb/kit.json"
  # fresh-vault ordering (Task 4 discovery): regen the index BEFORE the first
  # lint/self-check — a fresh vault's first lint otherwise reports a spurious
  # index-drift finding
  ( cd "$VAULT" && python3 .scripts/regen-index.py >/dev/null )
  ( cd "$VAULT" && git init -q -b main && git add -A \
      && git -c user.name="$HER_NAME" -c user.email="$HER_GMAIL" \
           commit -qm "kdb: fresh health-research vault from kit" )
  ok "vault created (local git, NO remote — by design)"
fi

# ── Phase 4: librarian ─────────────────────────────────────────────────────────
banner "Phase 4: kdb-librarian skill"
mkdir -p "$CLAUDE_DIR/skills/kdb-librarian"
cp "$KIT/skills/kdb-librarian/SKILL.md" "$CLAUDE_DIR/skills/kdb-librarian/SKILL.md"
ok "kdb-librarian skill installed/refreshed"

# ── Phase 4b: Gmail wiring (read + draft only, never send) ────────────────────
banner "Phase 4b: Gmail wiring (vault-scoped, read+draft/no-send)"
cat > "$VAULT/.mcp.json" <<'EOF'
{ "mcpServers": { "gmail": { "type": "stdio", "command": "npx",
    "args": ["-y", "@artymclabin/gmail-mcp@1.2.3"], "env": {} } } }
EOF
mkdir -p "$VAULT/.claude"
cat > "$VAULT/.claude/settings.json" <<'EOF'
{ "enabledMcpjsonServers": ["gmail"],
  "permissions": {
    "allow": [
      "mcp__gmail__read_email", "mcp__gmail__search_emails", "mcp__gmail__get_thread",
      "mcp__gmail__list_inbox_threads", "mcp__gmail__get_inbox_with_threads",
      "mcp__gmail__list_email_labels", "mcp__gmail__draft_email", "mcp__gmail__update_draft"
    ],
    "deny": [
      "mcp__gmail__send_email", "mcp__gmail__send_draft", "mcp__gmail__reply_all",
      "mcp__gmail__delete_email", "mcp__gmail__batch_delete_emails",
      "mcp__gmail__modify_email", "mcp__gmail__batch_modify_emails",
      "mcp__gmail__modify_thread", "mcp__gmail__delete_draft",
      "mcp__gmail__create_filter", "mcp__gmail__create_filter_from_template",
      "mcp__gmail__delete_filter", "mcp__gmail__delete_label",
      "mcp__gmail__update_label", "mcp__gmail__report_phishing",
      "mcp__gmail__batch_report_phishing"
    ] } }
EOF
GITIGNORE="$VAULT/.gitignore"
[ -f "$GITIGNORE" ] || : > "$GITIGNORE"
for pat in ".mcp.json" ".claude/"; do
  grep -qxF "$pat" "$GITIGNORE" || printf '%s\n' "$pat" >> "$GITIGNORE"
done
mkdir -p "$TARGET_HOME/.gmail-mcp"
# keep the vault repo clean: commit a .gitignore change immediately, same
# authorship as every other librarian-style commit in this vault (idempotent —
# a second run with nothing new to ignore leaves the tree untouched)
if [ -d "$VAULT/.git" ] && ! git -C "$VAULT" diff --quiet -- .gitignore 2>/dev/null; then
  git -C "$VAULT" add .gitignore
  git -C "$VAULT" -c user.name="$HER_NAME" -c user.email="$HER_GMAIL" \
    commit -qm "kdb: gitignore Gmail MCP + Claude local config"
fi
ok "Gmail MCP wired (read/search/draft allowed; send + permanent-delete + full mutating surface denied); .mcp.json + .claude/ gitignored"

# ── Phase 5: Claude global config ─────────────────────────────────────────────
banner "Phase 5: $CLAUDE_DIR global config"
mkdir -p "$CLAUDE_DIR"
if [ ! -f "$CLAUDE_DIR/CLAUDE.md" ]; then
  subst < "$KIT/claude-global/CLAUDE.md.tmpl" > "$CLAUDE_DIR/CLAUDE.md"
  ok "global CLAUDE.md"
else
  skip "global CLAUDE.md exists"
fi
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  # deep-merge, but UNION the hook arrays (keyed by hook command) and the
  # permissions.allow list (plain string union) so re-runs never clobber
  # hooks/permissions the user or another tool added; write only on change
  merged="$(jq -s '
    def union($a; $b): (($a // []) + ($b // [])) | unique_by([.hooks[]?.command]);
    .[0] as $cur | .[1] as $kit |
    ($cur * $kit)
    | .hooks.UserPromptSubmit = union($cur.hooks.UserPromptSubmit; $kit.hooks.UserPromptSubmit)
    | .hooks.SessionStart     = union($cur.hooks.SessionStart;     $kit.hooks.SessionStart)
    | .permissions.allow      = (((($cur.permissions.allow // []) + ($kit.permissions.allow // [])) | unique))
  ' "$CLAUDE_DIR/settings.json" \
    <(subst < "$KIT/claude-global/settings.json.tmpl"))"
  if [ "$(jq -S . "$CLAUDE_DIR/settings.json")" = "$(printf '%s\n' "$merged" | jq -S .)" ]; then
    skip "global settings already merged"
  else
    printf '%s\n' "$merged" > "$CLAUDE_DIR/settings.json"
    ok "global settings merged (kdb hooks registered)"
  fi
else
  subst < "$KIT/claude-global/settings.json.tmpl" > "$CLAUDE_DIR/settings.json"
  ok "global settings written (kdb hooks registered)"
fi

# docs: substituted owner-facing copies, refreshed every run (never touch the
# kit's own docs/ — those keep raw placeholders for the next Mac)
mkdir -p "$TARGET_HOME/health-kit-docs"
subst < "$KIT/docs/cheatsheet.md" > "$TARGET_HOME/health-kit-docs/cheatsheet.md"
subst < "$KIT/docs/maintenance.md" > "$TARGET_HOME/health-kit-docs/maintenance.md"
ok "docs substituted → $TARGET_HOME/health-kit-docs/"

# ── Phase 6: what the script cannot do ────────────────────────────────────────
banner "Phase 6: manual steps (in order — the README walks through each)"
cat <<'EOF'
   1. Claude login (HER account):        claude   → /login
   2. Google Cloud OAuth app             README → "Google setup" (one project,
      (Gmail API, consent screen           Desktop OAuth client, consent screen
       → Production)                       switched to Production)
   3. Put the OAuth client JSON at:      ~/.gmail-mcp/gcp-oauth.keys.json
   4. Authorize Gmail:                   npx -y @artymclabin/gmail-mcp@1.2.3 auth \
                                            --scopes=gmail.readonly,gmail.compose
   5. First session smoke test:          README → "First session"
EOF

# ── Phase 7: self-checks ──────────────────────────────────────────────────────
banner "Phase 7: self-checks"
CHECKS_FAILED=0

( cd "$VAULT" && python3 .scripts/lint.py >/dev/null ) \
  && ok "kdb lint" || { echo "   ✗ kdb lint FAILED"; CHECKS_FAILED=1; }

for section in Studies Claims Interventions Conditions Topics; do
  grep -qxF "## $section" "$VAULT/index.md" \
    || { echo "   ✗ index.md missing section '## $section'"; CHECKS_FAILED=1; }
done
[ "$CHECKS_FAILED" -eq 0 ] && ok "index.md has all five health sections"

if [ -f "$VAULT/studies/moro-2016-trf-males.md" ] \
   && [ -f "$VAULT/studies/cienfuegos-2020-4h-6h-trf.md" ]; then
  ok "seed studies present"
else
  echo "   ✗ seed studies missing"; CHECKS_FAILED=1
fi

[ -f "$CLAUDE_DIR/skills/kdb-librarian/SKILL.md" ] \
  && ok "librarian SKILL.md installed" \
  || { echo "   ✗ librarian SKILL.md missing"; CHECKS_FAILED=1; }

jq . "$VAULT/.mcp.json" >/dev/null 2>&1 \
  && ok ".mcp.json valid JSON" \
  || { echo "   ✗ .mcp.json invalid"; CHECKS_FAILED=1; }

jq -e '.permissions.deny | index("mcp__gmail__send_email")' "$VAULT/.claude/settings.json" >/dev/null 2>&1 \
  && ok "settings deny list blocks mcp__gmail__send_email" \
  || { echo "   ✗ send_email not denied"; CHECKS_FAILED=1; }

( cd "$VAULT" && git log --oneline | head -1 >/dev/null ) \
  && ok "vault git log has commits" \
  || { echo "   ✗ vault git log empty"; CHECKS_FAILED=1; }

if [ "$CHECKS_FAILED" -ne 0 ]; then
  banner "done — WITH FAILURES"
  echo "   One or more self-checks failed (✗ above). Fix and re-run before handover."
  exit 1
fi
banner "done"
echo "   Finish the Phase-6 checklist, then open a terminal and run: claude"
