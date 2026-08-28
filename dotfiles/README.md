# dotfiles/ — chezmoi source subset

Operator notes (English, for the person running the install). This directory is a
**chezmoi source directory** vendored into the kit — there is no dotfiles git repo on the
target Mac, and no `.chezmoi.toml.tmpl` (no autoCommit/autoPush; the kit clone is the only
source of truth).

## How it is applied

The bootstrap **stages a copy** — it never applies from (or writes identity into) the kit
clone:

```sh
rsync -a --delete <kit>/dotfiles/ ~/.local/share/health-kit-dotfiles/
# identity substituted into the STAGED copy only, then:
chezmoi apply --source ~/.local/share/health-kit-dotfiles --force
```

To pick up later kit updates: pull the kit clone and re-run `./bootstrap.sh` (Phase 2
re-stages and re-applies).

## Placeholder substitution contract

`dot_gitconfig` ships with `__HER_NAME__` and `__HER_GMAIL__` in its `[user]` section. The
bootstrap substitutes these **in the staged copy** before `chezmoi apply` — chezmoi itself
does no templating here, and the kit clone always keeps the raw placeholders. Nothing else
in this tree carries a placeholder.

## What's inside

| Target | Notes |
|---|---|
| `~/.zshenv` | Bootstrap stub: sets `ZDOTDIR=~/.config/zsh` and sources its `.zshenv` |
| `~/.config/zsh/` | zshrc (starship-first prompt with p10k fallback, zoxide, fzf, autosuggestions, syntax highlighting), zprofile (Homebrew), zshenv (empty per-machine env seam), p10k config |
| `~/.config/starship.toml` | starship prompt — catppuccin-powerline preset, Mocha palette |
| `~/.claude/statusline-command.sh` | Claude Code status line (Catppuccin, matches the prompt); wired via the kit's global settings template |
| `~/.config/ghostty/` | Terminal config: fonts, Catppuccin Mocha theme, keybinds, optional per-machine `local` override (see `local.example`) |
| `~/.config/tmux/tmux.conf` | fai worker plumbing only (prefix **ctrl+s**); humans use herdr |
| `~/.config/herdr/config.toml` | The interactive terminal mux (leader **ctrl+g**), Catppuccin theme |
| `~/.config/git/personal.inc` | delta pager niceties, no identity |
| `~/.gitconfig` | Identity from bootstrap prompts (placeholders above); `gh` credential helper resolved from PATH |
| `~/.config/nvim/` | Neovim config: treesitter, LSP (pyright/lua_ls/typos), telescope, oil, cmp, Catppuccin UI, claudecode.nvim |
| `~/.claude/hooks/` | The two kdb hooks (inbox nag + index inject), `$KDB_ROOT`-parameterized |

`.chezmoiignore` keeps this README from deploying into the home directory.

## Deliberately excluded

No identity, no work tooling, no machine-specific extras — this subset carries only what
the assistant Mac needs and is maintained through the kit itself.
