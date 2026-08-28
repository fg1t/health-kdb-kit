-- plenary.nvim is a no-op here if ui.lua already loaded it
vim.pack.add({
  "https://github.com/nvim-lua/plenary.nvim",
  { src = "https://github.com/nvim-telescope/telescope.nvim", version = "0.1.x" },
  "https://github.com/nvim-telescope/telescope-fzf-native.nvim",
})

local telescope = require("telescope")
telescope.setup({
  defaults = {
    -- Exclude generated files from search
    file_ignore_patterns = {
      "node_modules/", "%.git/",
    },
    layout_strategy = "horizontal",
    layout_config    = { preview_width = 0.55 },
  },
})
-- Safety net for telescope-fzf-native's compiled extension (build/libfzf.so).
-- The PackChanged hook in init.lua builds it on install/update, but if the binary
-- is ever missing (installed before that hook existed, a failed build, or a
-- deleted build/ dir) rebuild it here before loading, then load the extension
-- under pcall so a build failure degrades to "no fzf" instead of aborting init.
local fzf_dir = vim.fn.stdpath("data") .. "/site/pack/core/opt/telescope-fzf-native.nvim"
if vim.fn.filereadable(fzf_dir .. "/build/libfzf.so") == 0 then
  vim.notify("telescope-fzf-native: build/libfzf.so missing, running make...", vim.log.levels.INFO)
  vim.system({ "make" }, { cwd = fzf_dir }):wait()
end

local ok, err = pcall(telescope.load_extension, "fzf")
if not ok then
  vim.notify("telescope: failed to load fzf extension: " .. tostring(err), vim.log.levels.WARN)
end
