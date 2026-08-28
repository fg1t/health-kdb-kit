local map = vim.keymap.set

-- Always-on: work in both Neovim and VS Code
map("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- Toggle LSP virtual text (inline diagnostic messages)
map("n", "<leader>uv", function()
  local cfg = vim.diagnostic.config()
  vim.diagnostic.config({ virtual_text = not cfg.virtual_text })
end, { desc = "Toggle virtual text" })
map("v", "<", "<gv")
map("v", ">", ">gv")
map("v", "J", ":m '>+1<CR>gv=gv")
map("v", "K", ":m '<-2<CR>gv=gv")

if vim.g.vscode then
  -- ── VS Code mode: redirect everything to VS Code commands ──────────────
  local vscode = require("vscode")

  -- File explorer
  map("n", "<leader>e", function() vscode.action("workbench.view.explorer") end,              { desc = "Toggle file explorer" })

  -- Telescope → VS Code quick-open equivalents
  map("n", "<leader>ff", function() vscode.action("workbench.action.quickOpen") end,          { desc = "Find files" })
  map("n", "<leader>fg", function() vscode.action("workbench.action.findInFiles") end,        { desc = "Live grep" })
  map("n", "<leader>fb", function() vscode.action("workbench.action.showAllEditors") end,     { desc = "Buffers" })
  map("n", "<leader>fs", function() vscode.action("workbench.action.gotoSymbol") end,         { desc = "Document symbols" })
  map("n", "<leader>fr", function() vscode.action("editor.action.goToReferences") end,        { desc = "References" })

  -- Diagnostics (Trouble → Problems panel)
  map("n", "<leader>xx", function() vscode.action("workbench.actions.view.problems") end,     { desc = "Toggle problems panel" })
  map("n", "<leader>xd", function() vscode.action("workbench.actions.view.problems") end,     { desc = "Document diagnostics" })

  -- LSP
  map("n", "K",          function() vscode.action("editor.action.showHover") end,             { desc = "Hover docs" })
  map("n", "gd",         function() vscode.action("editor.action.revealDefinition") end,      { desc = "Go to definition" })
  map("n", "gr",         function() vscode.action("editor.action.goToReferences") end,        { desc = "References" })
  map("n", "<leader>rn", function() vscode.action("editor.action.rename") end,                { desc = "Rename symbol" })
  map("n", "<leader>ca", function() vscode.action("editor.action.quickFix") end,              { desc = "Code action" })
  map("n", "[d",         function() vscode.action("editor.action.marker.prevInFiles") end,    { desc = "Prev diagnostic" })
  map("n", "]d",         function() vscode.action("editor.action.marker.nextInFiles") end,    { desc = "Next diagnostic" })

  -- Terminal
  map("n", "<leader>t",  function() vscode.action("workbench.action.terminal.toggleTerminal") end, { desc = "Toggle terminal" })

  -- Buffer/editor navigation
  map("n", "<S-h>",      function() vscode.action("workbench.action.previousEditor") end,     { desc = "Prev editor" })
  map("n", "<S-l>",      function() vscode.action("workbench.action.nextEditor") end,         { desc = "Next editor" })
  map("n", "<leader>bd", function() vscode.action("workbench.action.closeActiveEditor") end,  { desc = "Close editor" })

  -- Window/split navigation
  map("n", "<C-h>", function() vscode.action("workbench.action.focusLeftGroup") end,  { desc = "Move to left window" })
  map("n", "<C-j>", function() vscode.action("workbench.action.focusBelowGroup") end, { desc = "Move to lower window" })
  map("n", "<C-k>", function() vscode.action("workbench.action.focusAboveGroup") end, { desc = "Move to upper window" })
  map("n", "<C-l>", function() vscode.action("workbench.action.focusRightGroup") end, { desc = "Move to right window" })

else
  -- ── Normal Neovim mode: plugin-based mappings ───────────────────────────

  -- File explorer
  map("n", "<leader>e", "<cmd>Neotree toggle<CR>", { desc = "Toggle file explorer" })

  -- Window navigation
  map("n", "<C-h>", "<C-w>h", { desc = "Move to left window" })
  map("n", "<C-j>", "<C-w>j", { desc = "Move to lower window" })
  map("n", "<C-k>", "<C-w>k", { desc = "Move to upper window" })
  map("n", "<C-l>", "<C-w>l", { desc = "Move to right window" })

  -- Telescope
  map("n", "<leader>ff", "<cmd>Telescope find_files<CR>",              { desc = "Find files" })
  map("n", "<leader>fg", "<cmd>Telescope live_grep<CR>",               { desc = "Live grep" })
  map("n", "<leader>fb", "<cmd>Telescope buffers<CR>",                 { desc = "Buffers" })
  map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<CR>",    { desc = "Document symbols" })
  map("n", "<leader>fr", "<cmd>Telescope lsp_references<CR>",          { desc = "References" })
  map("n", "<leader>fo", "<cmd>Telescope oldfiles<CR>",                 { desc = "Recent files" })

  -- Diagnostics (Trouble)
  map("n", "<leader>xx", "<cmd>TroubleToggle<CR>",                     { desc = "Toggle diagnostics" })
  map("n", "<leader>xd", "<cmd>TroubleToggle document_diagnostics<CR>",{ desc = "Document diagnostics" })

  -- LSP
  map("n", "K",          vim.lsp.buf.hover,         { desc = "Hover docs" })
  map("n", "gd",         vim.lsp.buf.definition,    { desc = "Go to definition" })
  map("n", "gr",         vim.lsp.buf.references,    { desc = "References" })
  map("n", "<leader>rn", vim.lsp.buf.rename,        { desc = "Rename symbol" })
  map("n", "<leader>ca", vim.lsp.buf.code_action,   { desc = "Code action" })
  map("n", "[d",         vim.diagnostic.goto_prev,  { desc = "Prev diagnostic" })
  map("n", "]d",         vim.diagnostic.goto_next,  { desc = "Next diagnostic" })

  -- Terminal (toggleterm)
  map("n", "<leader>t",  "<cmd>ToggleTerm direction=horizontal<CR>", { desc = "Toggle terminal" })
  map("t", "<Esc>",      "<C-\\><C-n>",                              { desc = "Exit terminal mode" })

  -- Buffer navigation
  map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
  map("n", "<S-l>", "<cmd>bnext<CR>",     { desc = "Next buffer" })
  map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "Delete buffer" })
end
