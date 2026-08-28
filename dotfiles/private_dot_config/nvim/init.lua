-- Extend PATH so Mason/LSPs can find cargo, homebrew binaries
local home = vim.fn.expand("~")
vim.env.PATH = home .. "/.cargo/bin:/opt/homebrew/bin:" .. vim.env.PATH

-- Leader key (must be before any plugin loads)
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("options")
require("keymaps")

-- Build hooks for plugins that need post-install/update steps.
-- Must be registered before any require("plugins.*") so it fires on first-launch installs.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name = ev.data.spec.name
    local kind = ev.data.kind
    if kind ~= "install" and kind ~= "update" then return end
    if name == "telescope-fzf-native.nvim" then
      -- :wait() is required — fzf-native must finish compiling before telescope loads
      vim.system({ "make" }, { cwd = ev.data.path }):wait()
    elseif name == "nvim-treesitter" then
      -- packadd needed when treesitter is not yet on rtp during first-launch install
      if not ev.data.active then vim.cmd.packadd("nvim-treesitter") end
      vim.cmd("TSUpdate")
    end
  end,
})

-- A throw in any one module must cost THAT module, loudly, not every module
-- required after it — a bare-require chain silently deletes everything
-- downstream of the first error, and the editor still looks normal.
for _, mod in ipairs({
  "plugins.formatting", "plugins.editing", "plugins.completion",
  "plugins.lsp", "plugins.ui", "plugins.telescope", "plugins.oil",
  "plugins.treesitter", "plugins.claude",
}) do
  local ok, err = pcall(require, mod)
  if not ok then
    vim.schedule(function()
      vim.notify(("config: %s failed to load:\n%s"):format(mod, err), vim.log.levels.ERROR)
    end)
  end
end
