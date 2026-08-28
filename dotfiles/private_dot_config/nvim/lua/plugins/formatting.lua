vim.pack.add({
  "https://github.com/stevearc/conform.nvim",
})

require("conform").setup({
  formatters_by_ft = {
    python     = { "ruff_format" },  -- install via Mason: :MasonInstall ruff
    lua        = { "stylua" },       -- install via Mason: :MasonInstall stylua
    rust       = { "rustfmt" },      -- comes with rustup, no extra install
    javascript = { "prettier" },     -- install via Mason: :MasonInstall prettier
    typescript = { "prettier" },
    html       = { "prettier" },
    css        = { "prettier" },
  },
})

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  require("conform").format({ async = true })
end, { desc = "Format buffer" })
