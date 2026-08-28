-- nvim-surround works in both Neovim and vscode-neovim
vim.pack.add({
  "https://github.com/kylechui/nvim-surround",
})

require("nvim-surround").setup()

-- Autopairs and color highlighting are standalone Neovim only
if not vim.g.vscode then
  vim.pack.add({
    "https://github.com/windwp/nvim-autopairs",
    "https://github.com/brenoprata10/nvim-highlight-colors",
  })
  require("nvim-autopairs").setup()
  require("nvim-highlight-colors").setup()
end
