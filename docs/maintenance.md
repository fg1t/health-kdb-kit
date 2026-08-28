# health-kdb-kit — operator runbook

Audience: the **operator** — the person who set up this Mac and provides remote support.
This doc stays in English. The owner-facing page is
[`docs/cheatsheet.md`](cheatsheet.md); keep a printed copy of the *installed* cheatsheet
(`~/health-kit-docs/cheatsheet.md`) near her Mac.

**Placeholders:** `__HER_NAME__`, `__ASSISTANT_NAME__`, `__HER_GMAIL__`, `__HOME__`, and
`__KIT_HOME__` are substituted with real values by `bootstrap.sh` at install time. In this
repo copy they appear literally; on the installed Mac the instantiated files carry real
values. Below, `__KIT_HOME__` means the absolute path of the kit clone on her Mac (default
`~/health-kit`).

Layout on her Mac after install:

| Path | What |
|---|---|
| `__KIT_HOME__` | this kit (git clone) |
| `~/Notes/kdb` | her knowledge vault — **her data**, local git, no remote |
| `~/.claude` | Claude Code global config: kdb hooks, kdb-librarian skill, settings, statusline |
| `~/health-kit-docs` | the *installed* (substituted) copies of `cheatsheet.md` and this runbook |
| `~/.gmail-mcp` | OAuth client secret + token store for the Gmail MCP server |
| `~/.local/share/health-kit-dotfiles` | staged, substituted dotfiles source (chezmoi applies from here, not from the kit clone) |

---

## Update

```bash
cd __KIT_HOME__
git pull
./bootstrap.sh        # idempotent: each phase re-checks and skips what's done
                      # (Phase 2 re-stages + re-applies the dotfiles too)
```

`bootstrap.sh` is phased and resumable — re-running it is the normal update path, not a
special recovery mode. A re-run needs internet: it re-clones `kdb-kit` from GitHub **every
run**, fresh, into a temp dir. What it refreshes vs. preserves:

- **Refreshed every run:** the vault's `.scripts/` machinery, `templates/`, `~/Notes/kdb/CLAUDE.md`
  (the schema contract — machinery, not owner content), the `kdb-librarian` skill, the
  installed cheatsheet and this runbook under `~/health-kit-docs/`, dotfiles, and
  `~/.claude/settings.json` — **merged**, not overwritten: Phase 5 deep-merges the kit's
  statusline + kdb hook entries into whatever is already there (union on the hook arrays,
  keyed by command), so any other config she or another tool has added to that file survives
  a re-run.
- **Merged, not overwritten:** `.kdb/types.json` — the kit's five health-folder entries are
  authoritative (a kit-side rename/fix always lands), but any folder **she** (or a future
  co-designed personal-health area) registered in that file survives the merge too. A plain
  re-run can neither drop her registrations nor fail to pick up a kit-side registry fix.
- **Preserved (deliberately, never overwritten):** her vault's `pages/` folders (`studies/`,
  `claims/`, `interventions/`, `conditions/`, `topics/`), `inbox/`, `attachments/`,
  `.kdb/kit.json` (her tier setting), `~/.claude/CLAUDE.md` if it already exists.

So **schema/skill changes shipped in a kit update DO propagate on a plain re-run** — that's
by design, since the machinery is meant to stay current — but her own content, her own
`.kdb/types.json` registrations, and her tier choice never do.

## Google token health

Email goes through one **community** local MCP server:

- `@artymclabin/gmail-mcp` (known-good at kit build time: 1.2.3)

**Load-bearing:** the Google Cloud OAuth consent screen must be in **Production** mode. In
*Testing* mode, refresh tokens expire every 7 days. If auth starts dying weekly, check the
consent screen status first (console.cloud.google.com → APIs & Services → OAuth consent
screen).

**Symptoms of token expiry:** the assistant reports it cannot read mail, or the Gmail MCP
server errors at session start with `invalid_grant` / "token has been expired or revoked".

**Re-auth (run in any terminal on her Mac):**

```bash
npx -y @artymclabin/gmail-mcp@1.2.3 auth --scopes=gmail.readonly,gmail.compose
```

Always include `--scopes=gmail.readonly,gmail.compose` — omitting it falls back to the
package's own default (`gmail.modify` + `gmail.settings.basic`), which grants far more than
this kit needs (mail-modify, label-management, filter-management) and only the deny list
would then stand between that grant and a mutating tool call. Opens a browser — sign in as
**__HER_GMAIL__** (not your own account) and approve. Tokens
are persisted by the server on disk at `~/.gmail-mcp/`; start a fresh `claude` session
afterwards.

**Honest risk note:** this is a community package maintained by a third party. A release can
break auth, rename tools, or change flags without notice. If the server misbehaves after an
update, pin the last good version (next section) and check the package's repo for breakage
reports before upgrading again.

## npx cache & version pinning

The kit **ships pinned**: the Gmail MCP config in `~/Notes/kdb/.mcp.json` runs
`@artymclabin/gmail-mcp@1.2.3` — the version the deny-list tool names in
`~/Notes/kdb/.claude/settings.json` were verified against. Both files are written verbatim
by `bootstrap.sh` Phase 4b from the values baked into the script itself (there is no
separate `.tmpl` to edit for this one).

- **Bumping the version** is a deliberate act: edit the pin inside `bootstrap.sh` (Phase
  4b's `.mcp.json` heredoc), re-run `./bootstrap.sh`, then **re-verify the full mutating
  tool list** against the new release, not just the five send/delete names — pull the new
  version's `dist/tools.js` (`npm pack @artymclabin/gmail-mcp@<new-version>` and inspect it,
  or browse the package on npm) and enumerate every tool name it registers, confirming each
  of the following is still present under exactly those names before trusting the deny list
  again:
  `mcp__gmail__send_email`, `send_draft`, `reply_all`, `delete_email`,
  `batch_delete_emails`, `modify_email`, `batch_modify_emails`, `modify_thread`,
  `delete_draft`, `create_filter`, `create_filter_from_template`, `delete_filter`,
  `delete_label`, `update_label`, `report_phishing`, `batch_report_phishing` — a renamed or
  new tool would silently fall out of the deny list. Also re-verify the OAuth scopes
  (`gmail.readonly,gmail.compose`) still filter the tool list the way this doc assumes — a
  release could add a tool gated on one of those two scopes that isn't already covered
  above. Keep the auth command (README §4 / bootstrap Phase 6) pinned to the same version
  **and** the same `--scopes=gmail.readonly,gmail.compose` flag.
- **Flush** a corrupted npx cache: `rm -rf ~/.npm/_npx`, then re-run the re-auth command
  above to re-populate.
- Verify what a pin resolves to: `npm view @artymclabin/gmail-mcp@1.2.3 version`.

## Claude Code login expiry

Symptom: `claude` demands login, or API calls fail with 401.

```bash
claude                # then type /login  (there is no `claude login` subcommand)
```

Log in with **her** account, not yours. Her account is the billing and identity boundary
for everything the assistant does.

## kdb health

```bash
cd ~/Notes/kdb
python3 .scripts/lint.py          # exit 0 = clean; reports orphans, broken
                                  # wikilinks, frontmatter violations, index drift
python3 .scripts/regen-index.py   # rebuild index.md when lint reports drift
```

The hooks nag at session start when `inbox/` has unprocessed drops — a growing backlog
usually just means she hasn't said "ingest" in a while, not a fault. Only the
`kdb-librarian` skill writes `studies/`, `claims/`, `interventions/`, `conditions/`,
`topics/`; everything else goes through `inbox/`. Her hand-authored personal-health pages
(once she has them) are read-only ground truth to `lint.py`/`regen-index.py` and to the
skill — lint may *report* something odd on one, but neither the skill nor the scripts ever
fix it unedited.

## Reset librarian skill

If the skill misbehaves (stale copy, local edits gone wrong), it self-heals on the next
bootstrap run — Phase 4 overwrites `~/.claude/skills/kdb-librarian/SKILL.md` unconditionally
every time:

```bash
cd __KIT_HOME__ && ./bootstrap.sh
```

No flags, no manual deletion needed; this phase never touches the vault itself.

## Re-auth Gmail

See "Google token health" above for the full recipe. Quick version:

```bash
npx -y @artymclabin/gmail-mcp@1.2.3 auth
```

## Vault restore from Time Machine

The vault has **no git remote** — Time Machine is the only backup. To restore:

1. Enter Time Machine (from the Time Machine menu-bar icon, or Launchpad → Time Machine) and
   navigate to a snapshot from before the problem started.
2. Restore `~/Notes/kdb` specifically (don't restore the whole home directory unless you
   mean to) — either drag the folder out of the Time Machine browser onto the Desktop for a
   side-by-side compare, or restore it in place if you're confident.
3. Since it's a local git repo, you can also recover a **specific past state** without a
   full folder restore, if the `.git` directory itself is intact:
   ```bash
   cd ~/Notes/kdb
   git log --oneline              # find the commit you want
   git checkout <commit> -- <path-to-file>   # restore one file, or
   git reset --hard <commit>                  # restore the whole vault to that commit
                                               # (destroys anything after it — confirm first)
   ```
4. After any restore, re-run the self-checks by hand:
   ```bash
   cd ~/Notes/kdb && python3 .scripts/lint.py && python3 .scripts/regen-index.py
   ```

## Reset recipes

**Vault machinery is suspect** (broken `.scripts/`, drifted `templates/`, stale
`.kdb/types.json`) — a plain re-run refreshes all three without touching pages:

```bash
cd __KIT_HOME__ && ./bootstrap.sh
```

**Whole install is suspect** — full idempotent re-run, same command as above (`git pull`
first if you haven't already):

```bash
cd __KIT_HOME__ && git pull && ./bootstrap.sh
```

Then walk the first-session script: ask it a question, ingest one small item, confirm email
stays read/draft-only.

**Her tier setting is wrong / she wants a change** — this is *her* file, never
auto-overwritten:

```bash
$EDITOR ~/Notes/kdb/.kdb/kit.json      # { "default_tier": "narrative" | "structured" }
```

## Uninstall

> **WARNING — the vault is her data.** `~/Notes/kdb` holds her health research and, once she
> starts one, her personal-health area — it is a *local-only* git repo with **no remote**.
> Back it up first (Time Machine snapshot, or `cp -R ~/Notes/kdb ~/Desktop/kdb-backup`)
> before deleting anything. Deleted means gone.

What the kit touched on her Mac:

1. Back up the vault (above). Confirm the backup opens.
2. Delete the vault (only after step 1): `rm -rf ~/Notes/kdb`
3. Delete the kit clone: `rm -rf __KIT_HOME__`
4. Clean `~/.claude`:
   - `rm ~/.claude/CLAUDE.md` (if it is only the kit-written one)
   - `rm ~/.claude/settings.json` (or hand-edit it: remove the `UserPromptSubmit` /
     `SessionStart` hook entries pointing at the kdb hooks, and the statusline entry, if she
     wants to keep other Claude Code config)
   - `rm -rf ~/.claude/skills/kdb-librarian`
5. Delete the staged dotfiles source: `rm -rf ~/.local/share/health-kit-dotfiles`. Applied
   files are plain files in `$HOME` (`~/.zshenv`, `~/.config/{zsh,ghostty,tmux,git,herdr,
   nvim}`) — delete them individually if she wants a stock shell. `chezmoi purge` removes
   chezmoi's own source/state but leaves applied files in place.
6. Delete the installed docs: `rm -rf ~/health-kit-docs`
7. Delete Google credentials: `rm -rf ~/.gmail-mcp` (the OAuth client secret and token store
   live there); optionally `rm -rf ~/.npm/_npx` (cached MCP server code).
8. Homebrew packages: `brew bundle list --file=__KIT_HOME__/Brewfile` shows what the kit
   installed (do this **before** step 3); `brew uninstall` the ones she doesn't otherwise
   use. `npm uninstall -g @anthropic-ai/claude-code`.
9. Google side: revoke the app at myaccount.google.com → Security → Third-party access;
   optionally delete the Google Cloud project.

## Remote support tips

- **First diagnostic:** ask her to run `python3 ~/Notes/kdb/.scripts/lint.py` and read you
  the last few lines — it's read-only and works even when Gmail auth is broken.
- **Phone walk-through:** have her read the last ~10 lines of the terminal aloud; every
  action the assistant takes ends in a plain-language summary, so the tail of the transcript
  is usually enough to diagnose. Keep instructions to "quit Ghostty (Cmd+Q), reopen, `cd
  ~/Notes/kdb`, type `claude`" before anything fancier.
- **Screen Sharing:** easiest over the internet is FaceTime/Messages screen sharing (built
  into macOS, she just accepts the prompt). For hands-on control, enable System Settings →
  General → Sharing → Screen Sharing on her Mac and connect with Finder → Go → Connect to
  Server → `vnc://<her-mac>.local` (same network / VPN).
- **When driving remotely, open a fresh `claude` session** rather than typing into hers —
  her session's context stays hers.
- Everything owner-facing lives in [`docs/cheatsheet.md`](cheatsheet.md); if a support call
  keeps repeating, the fix is usually a line added there, not more phone time.
