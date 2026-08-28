vim.pack.add({
  "https://github.com/williamboman/mason.nvim",
  "https://github.com/williamboman/mason-lspconfig.nvim",
  "https://github.com/neovim/nvim-lspconfig",
})

require("mason").setup()

require("mason-lspconfig").setup({
  ensure_installed = {
    "pyright",   -- Python (scripts)
    "lua_ls",    -- Lua (nvim config)
    "typos_lsp", -- Typo suggestions across all files
  },
  automatic_installation = true,
  -- auto-enable would activate EVERY server present in mason's tree,
  -- overruling the explicit vim.lsp.enable() choice below. Only that
  -- call decides what attaches.
  automatic_enable = false,
})

local capabilities = require("cmp_nvim_lsp").default_capabilities()

vim.lsp.config("pyright", {
  capabilities = capabilities,
})

vim.lsp.config("lua_ls", {
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = { globals = { "vim" } },
    },
  },
})

vim.lsp.config("typos_lsp", {
  capabilities = capabilities,
})

-- Presence is not runnability: a prebuilt typos-lsp binary can be present,
-- executable, and still die at spawn on an incompatible runtime — probe by
-- RUNNING it; a box that can't execute it just runs without typos_lsp.
local enable_list = { "pyright", "lua_ls" }
-- vim.fn.system's list form RAISES on a missing executable instead of setting
-- shell_error, so an absent binary would kill this whole file. Test
-- executability first — absent and unrunnable collapse to the same handled
-- answer: no typos_lsp.
if vim.fn.executable("typos-lsp") == 1 then
  vim.fn.system({ "typos-lsp", "--version" })
  if vim.v.shell_error == 0 then
    table.insert(enable_list, "typos_lsp")
  end
end
vim.lsp.enable(enable_list)

-- Add rule codes here to suppress them globally (use <leader>dc to find codes)
local ignored_codes = {}

-- Filter at the LSP handler level — avoids Neovim 0.12 filter API incompatibility
do
  local orig = vim.lsp.handlers["textDocument/publishDiagnostics"]
  vim.lsp.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
    if result and result.diagnostics and #ignored_codes > 0 then
      result.diagnostics = vim.tbl_filter(function(d)
        return not vim.tbl_contains(ignored_codes, tostring(d.code or ""))
      end, result.diagnostics)
    end
    orig(err, result, ctx, config)
  end
end

vim.diagnostic.config({
  virtual_text     = true,
  signs            = true,
  underline        = true,
  update_in_insert = false,
})

-- Ignore diagnostic under cursor; add to ignored_codes to persist across sessions
vim.keymap.set("n", "<leader>di", function()
  local diags = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
  if #diags == 0 then
    vim.notify("No diagnostics on this line", vim.log.levels.INFO)
    return
  end
  local code = tostring(diags[1].code or "")
  if code == "" then
    vim.notify("Diagnostic has no code", vim.log.levels.WARN)
    return
  end
  if vim.tbl_contains(ignored_codes, code) then
    vim.notify("Already ignored: " .. code, vim.log.levels.INFO)
    return
  end
  table.insert(ignored_codes, code)
  -- Re-set each LSP client's diagnostics with the new code filtered out
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    local ns = vim.lsp.diagnostic.get_namespace(client.id)
    local current = vim.diagnostic.get(0, { namespace = ns })
    local filtered = vim.tbl_filter(function(d)
      return not vim.tbl_contains(ignored_codes, tostring(d.code or ""))
    end, current)
    vim.diagnostic.set(ns, 0, filtered)
  end
  vim.notify('Ignored: "' .. code .. '" (add to ignored_codes in lsp.lua to persist)', vim.log.levels.INFO)
end, { desc = "Ignore diagnostic under cursor" })

-- Show diagnostic code under cursor — copy it into ignored_codes above to suppress
vim.keymap.set("n", "<leader>dc", function()
  local diags = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
  if #diags == 0 then
    vim.notify("No diagnostics on this line", vim.log.levels.INFO)
    return
  end
  local codes = {}
  for _, d in ipairs(diags) do
    if d.code then table.insert(codes, tostring(d.code)) end
  end
  local msg = #codes > 0 and table.concat(codes, ", ") or "(no code)"
  vim.notify("Diagnostic code: " .. msg, vim.log.levels.INFO)
end, { desc = "Show diagnostic code under cursor" })

-- Toggle all diagnostics on/off globally
vim.keymap.set("n", "<leader>dg", function()
  local enabled = vim.diagnostic.is_enabled()
  vim.diagnostic.enable(not enabled)
  vim.notify("Diagnostics " .. (not enabled and "enabled" or "disabled"), vim.log.levels.INFO)
end, { desc = "Toggle diagnostics globally" })
