-- ============================================================================
-- LuaCATS Type Annotations (for LSP autocomplete)
-- ============================================================================

---@class BabelConfig Main configuration class
---@field options BabelOptions Current settings (after setup)
---@field setup fun(opts?: BabelOptions) Initialization function

---@class BabelOptions Plugin settings
---@field source string Source language ('auto' = auto-detect)
---@field target string Target language ('ru', 'en', etc.)
---@field provider string Translation provider ('google', 'yandex')
---@field display "float"|"picker" Display mode ('float' = floating window, 'picker' = use picker)
---@field picker "auto"|"telescope"|"fzf"|"snacks"|"mini" Picker to use (when display = "picker")
---@field float BabelFloatOptions Floating window options
---@field keymaps BabelKeymaps Keybindings

---@class BabelFloatOptions Floating window settings
---@field border string Border style ('rounded', 'single', 'double', 'none')
---@field max_width number Maximum window width
---@field max_height number Maximum window height

---@class BabelKeymaps Keybindings
---@field translate string Translate selection (visual mode)
---@field translate_word string Translate word under cursor (normal mode)

-- ============================================================================

---@class BabelConfig
local M = {}

---@type BabelOptions
local defaults = {
  source = "auto",
  target = "ru",
  provider = "google",
  display = "float", -- "float" or "picker"
  picker = "auto", -- "auto", "telescope", "fzf", "snacks", "mini"
  float = {
    border = "rounded",
    max_width = 80,
    max_height = 20,
  },
  keymaps = {
    translate = "<leader>tr",
    translate_word = "<leader>tw",
  },
}

---@type BabelOptions
M.options = {}

---Initialize configuration (merge defaults + user opts)
---@param opts? BabelOptions User settings
function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", defaults, opts or {})
end

return M
