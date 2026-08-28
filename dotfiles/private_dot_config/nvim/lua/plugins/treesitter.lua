vim.pack.add({
  -- Pinned to master: the main-branch rewrite deadens ensure_installed and
  -- shells out to a tree-sitter CLI that may not be installed. Master
  -- compiles parsers with cc and needs no extra tooling.
  { src = "https://github.com/nvim-treesitter/nvim-treesitter", version = "master" },
})

require("nvim-treesitter.configs").setup({
  ensure_installed = {
    "lua",
    "bash",
    "python",
    "markdown",
  },
  auto_install = false,
  highlight = { enable = true },
})
