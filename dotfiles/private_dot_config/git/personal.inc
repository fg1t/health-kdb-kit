# delta pager niceties — carries NO identity and NO credentials.

[core]
	pager = delta

[interactive]
	diffFilter = delta --color-only

[delta]
	navigate = true
	dark = true
	line-numbers = true
	side-by-side = true
	syntax-theme = Catppuccin Mocha

[merge]
	conflictStyle = zdiff3

[diff]
	colorMoved = default
