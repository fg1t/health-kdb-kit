# health-kdb-kit

Turn a fresh Mac into a **personal health-research assistant** for a non-technical owner —
her own reading of studies, extracted claims, and a private library she can ask questions
of in either language. One bootstrap script, a short manual checklist, and a printable
bilingual cheat-sheet for the owner.

This kit composes one public, machinery-only, leak-gated kit at install time:

- [kdb-kit](https://github.com/fg1t/kdb-kit) — the knowledge base: a typed markdown wiki
  maintained by the `kdb-librarian` skill.

plus a health-research overlay (vault schema for studies/claims/interventions/conditions/
topics, evidence-grade rubric, a health-flavored `kdb-librarian` skill), a curated dotfiles
subset (zsh + starship, Ghostty, tmux, herdr, neovim, git), and read+draft/no-send Gmail
wiring.
**No personal content ships in this repo** — the owner's name, assistant name, and Gmail are
prompted by the bootstrap and never leave her Mac.

**Deployment shape.** One Claude Code session, no daemons. She opens Ghostty, runs `claude`,
and works directly against her vault at `~/Notes/kdb` — there is no orchestrator, no
dispatch layer, no bus. The only moving parts are Claude Code itself, the `kdb-librarian`
skill, and the two session hooks that nag about a growing inbox and keep the index fresh in
context.

## What you need before setup day

| Item | Notes |
|---|---|
| Her Apple ID | She signs into the Mac herself (FileVault on; you never need her password) |
| Her Claude account | Pro works; **Max recommended** for daily agent use. Claude Code is included in both |
| Her Google account | Gmail only. You will create a Google Cloud OAuth app **under her account** (~40 min, once) |
| Internet + admin account | Bootstrap needs both — on first run AND on every update re-run (it re-clones `kdb-kit` from GitHub every time) |
| This kit | `git clone https://github.com/fg1t/health-kdb-kit ~/health-kit` (public — no auth needed on her Mac) |
| A Time Machine disk | The vault has **no cloud remote by design** — Time Machine is the entire backup story |
| A printer (or PDF) | for her bilingual cheat-sheet — print `~/health-kit-docs/cheatsheet.md` **after** bootstrap (the kit copy under `docs/` has placeholder tokens; the installed copy has her real names) |

## Setup day

### 1. macOS first boot

Her Apple ID, her password. Turn on **FileVault** (Settings → Privacy & Security) and plug
in a **Time Machine** disk (Settings → General → Time Machine) *before* running bootstrap —
the vault it creates has no remote, so this disk is the only copy outside the Mac itself.

### 2. Clone and bootstrap

Open Terminal (the stock one — Ghostty arrives in a minute):

```bash
xcode-select --install        # finish the dialog before continuing
```

Wait for the install to complete (it provides `git`), then:

```bash
git clone https://github.com/fg1t/health-kdb-kit ~/health-kit
cd ~/health-kit && ./bootstrap.sh
```

The script prompts for **her name, the assistant's name, and her Gmail address** (cached in
`setup.local`, gitignored — a re-run won't ask again), then installs everything: Homebrew +
Brewfile (git, starship, zsh add-ons, Ghostty, tmux, herdr, neovim, node, python…), Claude
Code, dotfiles (staged copy via `chezmoi apply --source`, identity substituted at apply
time), the `~/Notes/kdb` vault (fresh local git, seeded with two worked-example studies),
the health-flavored `kdb-librarian` skill, read+draft/no-send Gmail wiring, and `~/.claude`
global config (kdb hooks + assistant identity).

**Re-running is safe** — every phase self-checks before it acts. If Xcode CLT was missing,
the script exits once; finish the dialog and re-run.

**⚠ If bootstrap is interrupted (Ctrl-C, crash, lost power) partway through Phase 3 on a
FIRST run** — before `~/Notes/kdb` exists yet — `rm -rf ~/Notes/kdb` before re-running.
Bootstrap tells "fresh vault" from "existing vault" by whether `~/Notes/kdb` exists at all;
a half-built directory left behind by an interrupted first run is treated as an *existing*
vault on the next run, which only re-overlays machinery and never finishes laying down
`CLAUDE.md`, the seed pages, or `git init` — deleting and starting over is the fix, not
another plain re-run.

### 3. Claude login — her account

```bash
cd ~/Notes/kdb && claude    # then: /login  → sign in with HER Claude account in the browser
```

### 4. Google setup (the 40 minutes)

Everything under **her** Google account, so the tokens never depend on you. At
[console.cloud.google.com](https://console.cloud.google.com):

1. **New project** — name it e.g. `health-research-assistant`.
2. **APIs & Services → Library** — enable the **Gmail API**.
3. **OAuth consent screen** (Google Auth Platform) — External; app name + her email; then
   publish to **Production** (Testing-mode refresh tokens expire every 7 days). The
   "unverified app" state is fine for personal use.
4. **Credentials → Create credentials → OAuth client ID → Desktop app** — download the JSON.
5. Place it:
   ```bash
   mv ~/Downloads/client_secret*.json ~/.gmail-mcp/gcp-oauth.keys.json
   ```
6. Authorize (a browser opens; at the "unverified app" warning: Advanced → continue; sign in
   as her). Version pinned to match the shipped MCP config, and scoped to least privilege —
   **read + compose only**, not the package's broader default (`gmail.modify` +
   `gmail.settings.basic`, which would also grant label/filter management):
   ```bash
   npx -y @artymclabin/gmail-mcp@1.2.3 auth --scopes=gmail.readonly,gmail.compose
   ```

**Email is read + draft only.** The vault's `.claude/settings.json` allows reading,
searching, and drafting; the OAuth grant itself is scoped to `gmail.readonly` +
`gmail.compose`, so mail-modifying, label-management, and filter-management tools are
absent from the tool list at the source — not just blocked by policy. On top of that,
`send_email`, `send_draft`, `reply_all`, `delete_email`, `batch_delete_emails`, and every
other mutating tool the server exposes (`modify_email`, `delete_draft`, `create_filter`,
and the rest — see `docs/maintenance.md`) are denied by name in `.claude/settings.json`.
**Sending is denied; deleting an email permanently is denied.** Trashing a message (moving
it to Trash via a label change) is not itself possible under these scopes, and the specific
`modify_email`/`batch_modify_emails` tools that could do it are also explicitly denied. She
reviews and presses **send** herself, in Gmail, every time. Nothing in this kit sends mail
on her behalf.

### 5. First session — verify the whole chain

```bash
cd ~/Notes/kdb && claude
```

In order (approve the one-time tool prompts as they appear — they persist):

1. Ask it a question in either language — confirm it answers in the language you used.
2. Drop a real paper (a PDF, or a `.md` note with the DOI/URL) into `~/Notes/kdb/inbox/`
   and say "ingest" — confirm a `studies/` page lands, the index regenerates, and a `log.md`
   entry appears.
3. Ask it to read your recent email — confirm it reads/drafts only; try "draft a reply to
   the top thread" and confirm it stops at a draft, never a send.

The bootstrap's Phase-7 self-checks (vault lint, index sections, seed studies present,
librarian skill installed, Gmail deny-list correct, vault git log has commits) have already
passed if the script ended with `== done ==`.

### 6. Handover

Print `~/health-kit-docs/cheatsheet.md`, put it next to the Mac. Show her: open **Ghostty**
→ `cd ~/Notes/kdb` → type `claude` → talk. The two promises to state out loud: it never
sends an email without her pressing send in Gmail; her own health pages, once she starts
writing them, are hers alone — the assistant never rewrites them.

## The rigor-tier trial

The vault ships with `default_tier: narrative` in `~/Notes/kdb/.kdb/kit.json` — a new study
gets a page (`## Summary` / `## Key findings` / `## Limitations`) but no claims are
extracted until she asks. This is the deliberately conservative default; the point of the
first real week is to *earn* a decision about whether to change it.

Two seed pages in `~/Notes/kdb/studies/` show both ends of the spectrum already:

- [`studies/moro-2016-trf-males`](vault/studies/moro-2016-trf-males.md) — filed
  `tier: narrative`: a page only, no claims extracted yet.
- [`studies/cienfuegos-2020-4h-6h-trf`](vault/studies/cienfuegos-2020-4h-6h-trf.md) — filed
  `tier: structured`: the study page *plus* extracted `claims/` pages that cite it.

Walk her through the trial in the first real week:

1. **Ingest ~5 real papers** she cares about, narrative-first (the shipped default). Each
   lands as a study page, hub-linked, no claims yet.
2. **Promote 2 of them to structured** — ask the assistant to extract claims from a
   narrative-tier study she wants graded (it adds `claims/` pages and flips the study's
   `tier` to `structured`; this doesn't require re-ingesting the source).
3. Once she has a feel for how much friction the "ask every time" narrative default adds,
   **set the default** for new studies:
   ```bash
   $EDITOR ~/Notes/kdb/.kdb/kit.json      # { "default_tier": "narrative" | "structured" }
   ```
   `structured` means every new study gets claims extracted automatically (still filed
   `narrative` if a study genuinely doesn't support a discrete falsifiable claim); `narrative`
   means the librarian asks first, every time. Either choice is fully reversible — nothing
   about the vault's shape depends on it.

## Updating later

```bash
cd ~/health-kit && git pull && ./bootstrap.sh     # idempotent; re-applies dotfiles too
```

Operator details — reset/uninstall recipes, Gmail re-auth, remote support: **`docs/maintenance.md`**.

## Her own data — the personal-health area

The vault's schema (`~/Notes/kdb/CLAUDE.md`) deliberately pre-creates **nothing** personal.
Her own health tracking — symptoms, labs, a condition she's managing, whatever she wants to
keep — gets its own folder structure and frontmatter, **co-designed with the assistant on
her Mac** once she has real content to organize, not decided in advance by this kit.

When that folder is created, register it in `~/Notes/kdb/.kdb/types.json` (the same registry
the five research folders use) so `lint.py` and `regen-index.py` pick it up.

**Hands-off guarantees, permanent:** once a personal page exists, it is read-only ground
truth to the `kdb-librarian` skill and to `lint.py`/`regen-index.py` — no rewrite, no
re-schema, no normalization, ever, unless she asks for it directly. The vault's global
`CLAUDE.md` and the librarian skill both encode this; it isn't a convention that can silently
erode across a bootstrap re-run.

**Privacy is absolute:** her personal health data never leaves this Mac. It never goes into
an email draft, a reply meant for anyone but her, or any other outward payload — the vault
has no git remote, by design, for exactly this reason.

## Deliberately out of scope (v1)

Notifications, a router/dispatch layer, multi-context orchestration, a vault git remote,
calendar integration. This kit is one session working directly in one vault — there is no
`fai`-style orchestrator underneath it.

## Security & privacy model

- **Email can't send, and can't delete or trash a message.** The OAuth grant itself is
  scoped to `gmail.readonly` + `gmail.compose` — the tools that need `gmail.modify` (message
  edits, including moving a message to Trash) or `gmail.full` (permanent delete) or
  `gmail.settings.basic` (filters) are absent from the tool list at the source, not merely
  blocked by policy. On top of that, `.claude/settings.json` denies every mutating tool the
  server registers by name — `send_email`, `send_draft`, `reply_all`, `delete_email`,
  `batch_delete_emails`, `modify_email`, `batch_modify_emails`, `modify_thread`,
  `delete_draft`, `create_filter`, `create_filter_from_template`, `delete_filter`,
  `delete_label`, `update_label`, `report_phishing`, `batch_report_phishing` — as
  defence-in-depth against a scope mistake. Only read/search/draft tools are allowed. She
  presses send herself, in Gmail, every time.
- **Everything stays local:** the vault has no remote — Time Machine is the backup;
  Gmail tokens live in `~/.gmail-mcp/`. Nothing in this repo or on her Mac references you.
- **Her data stays hers.** Her hand-authored personal-health pages are read-only ground
  truth to every vault operation (see above) — the assistant contributes research through
  `inbox/` + the librarian, never by editing her own pages.
- Kit hygiene: run `./scan-secrets.sh` over the tree before every commit to this repo (a
  convention, enforced by hand, not a hook); placeholders substitute at install time only.

## Repo layout

| Path | What |
|---|---|
| `bootstrap.sh` | the one-shot idempotent installer (7 phases + self-checks) |
| `Brewfile` | everything Homebrew installs |
| `dotfiles/` | chezmoi source subset — zsh+starship, Ghostty, tmux (ctrl+s, kit plumbing only), herdr (ctrl+g, her interactive mux), neovim, git (identity via placeholders), kdb hooks |
| `vault/` | the health overlay: `CLAUDE.md` (schema — study/claim/intervention/condition/topic types, evidence-grade rubric, women's-data-gap rule), `.kdb/types.json` (folder registry), `templates/`, two seed study pages |
| `skills/kdb-librarian/` | the health-flavored librarian skill (ingest/distill/lint, tier rule, hub-reachability, personal-pages hands-off) |
| `claude-global/` | `CLAUDE.md.tmpl` + `settings.json.tmpl` written to `~/.claude` (assistant identity, kdb hooks, statusline) |
| `config/kit.json` | shipped default (`default_tier: narrative`) — copied once to `~/Notes/kdb/.kdb/kit.json`, then hers to edit |
| `docs/` | `cheatsheet.md` (hers, bilingual) · `maintenance.md` (yours) |
| `scan-secrets.sh` | the leak gate every commit to this repo must pass clean |
