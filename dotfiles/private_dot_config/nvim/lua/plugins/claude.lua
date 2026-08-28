vim.pack.add({
  "https://github.com/coder/claudecode.nvim",
})

require("claudecode").setup({
  terminal = {
    provider = "native",
    split_side = "right",
    split_width_percentage = 0.35,
  },
})

vim.keymap.set("n", "<leader>ac", "<cmd>ClaudeCode<CR>",          { desc = "Toggle Claude Code" })
vim.keymap.set({ "n", "v" }, "<leader>as", "<cmd>ClaudeCodeSend<CR>", { desc = "Send to Claude" })
vim.keymap.set("n", "<leader>ao", "<cmd>ClaudeCodeTreeAdd<CR>",   { desc = "Add file to Claude context" })
