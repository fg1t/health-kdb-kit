if vim.g.vscode then return end

-- Shared dependencies listed first so they are packadd'd before plugins that need them
vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/MunifTanjim/nui.nvim",
  "https://github.com/catppuccin/nvim",
  "https://github.com/nvim-lualine/lualine.nvim",
  { src = "https://github.com/nvim-neo-tree/neo-tree.nvim", version = "v3.x" },
  "https://github.com/lukas-reineke/indent-blankline.nvim",
  "https://github.com/folke/which-key.nvim",
  "https://github.com/folke/trouble.nvim",
  "https://github.com/lewis6991/gitsigns.nvim",
  "https://github.com/akinsho/bufferline.nvim",
  "https://github.com/akinsho/toggleterm.nvim",
})

-- Catppuccin Mocha — the one palette across Ghostty/tmux/herdr/delta/fzf.
require("catppuccin").setup({ flavour = "mocha" })
vim.cmd.colorscheme("catppuccin")

require("lualine").setup({
  options = { theme = "auto" },
  sections = {
    lualine_c = { { "filename", path = 1 } },
  },
})

require("neo-tree").setup({
  window = { width = 30 },
  filesystem = {
    filtered_items = { hide_dotfiles = false },
  },
})

require("ibl").setup({ scope = { enabled = true } })
require("which-key").setup()
require("which-key").add({
  { "<leader>a", group = "Claude AI" },
  { "<leader>b", group = "buffer" },
  { "<leader>c", group = "code" },
  { "<leader>d", group = "diagnostic" },
  { "<leader>e", desc = "file explorer" },
  { "<leader>f", group = "find" },
  { "<leader>r", group = "refactor" },
  { "<leader>t", desc = "terminal" },
  { "<leader>u", group = "UI" },
  { "<leader>x", group = "trouble" },
})
require("trouble").setup()
require("gitsigns").setup({ current_line_blame = true })
require("bufferline").setup()
require("toggleterm").setup({
  size = 15,
  shade_terminals = true,
})
