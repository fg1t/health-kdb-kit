# health-kdb-kit — everything the friend's Mac needs from Homebrew.
# Applied by bootstrap.sh via `brew bundle --file Brewfile`. Idempotent.

# shell + prompt
brew "starship"        # primary prompt (catppuccin-powerline, ~/.config/starship.toml)
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"
brew "zoxide"
brew "fzf"

# core tooling
brew "git"
brew "git-delta"
brew "chezmoi"
brew "jq"              # macOS has no stock jq; bootstrap.sh settings-merge + self-check need it

# editors / muxes (operator toolchain)
brew "neovim"
brew "tmux"           # fai worker plumbing (prefix ctrl+s)
brew "herdr"           # the human's interactive mux (prefix ctrl+g)

# runtimes fai needs
brew "node"            # Claude Code + npx-launched MCP servers (Gmail MCP runs via npx)
brew "python"          # fai glue (stdlib + claude-agent-sdk in a venv)

# apps
cask "ghostty"
cask "font-jetbrains-mono-nerd-font"
