if vim.g.vscode then return end

-- nvim-web-devicons is a no-op here if ui.lua already loaded it
vim.pack.add({
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/stevearc/oil.nvim",
})

require("oil").setup({
  default_file_explorer = false,
  view_options = { show_hidden = true },
})
vim.keymap.set("n", "-", "<cmd>Oil<CR>", { desc = "Open parent dir (oil)" })
