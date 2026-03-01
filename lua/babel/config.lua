-- ============================================================================
-- LuaCATS Type Annotations (for LSP autocomplete)
-- ============================================================================

---@class BabelConfig Main configuration class
---@field options BabelOptions Current settings (after setup)
---@field setup fun(opts?: BabelOptions) Initialization function

---@class BabelDeeplOptions Deepl provider settings
---@field api_key? string API key (overrides DEEPL_API_KEY env)
---@field pro? boolean Force Pro endpoint (auto-detect by default)
---@field formality? "default"|"more"|"less"|"prefer_more"|"prefer_less"

---@class BabelOptions Plugin settings
---@field deepl? BabelDeeplOptions
---@field network? BabelNetworkOptions Network request settings
---@field history? BabelHistoryOptions Translation history settings
---@field source string Source language ('auto' = auto-detect)
---@field target string Target language ('ru', 'en', etc.)
---@field provider string Translation provider ('google', 'deepl')
---@field display "float"|"picker" Display mode ('float' = floating window, 'picker' = use picker)
---@field picker "auto"|"telescope"|"fzf"|"snacks"|"mini" Picker to use (when display = "picker")
---@field float BabelFloatOptions Floating window options
---@field keymaps BabelKeymaps Keybindings

---@class BabelNetworkOptions Network request settings
---@field connect_timeout? number Curl connect timeout in seconds
---@field request_timeout? number Curl max request time in seconds

---@class BabelHistoryOptions Translation history settings
---@field enabled? boolean Enable in-memory translation history
---@field limit? number Maximum history entries to keep

---@class BabelFloatOptions Floating window settings
---@field border string Border style ('rounded', 'single', 'double', 'none')
---@field mode? "center"|"cursor" Float positioning preset ('center' = screen center, 'cursor' = follow cursor)
---@field max_width number Maximum window width
---@field max_height number Maximum window height
---@field auto_close_ms? number Auto-close timeout in milliseconds (0 disables)
---@field pin? boolean Allow pin toggle with 'p' when auto-close is enabled
---@field copy_original? boolean Enable copying original text with 'Y'
---@field nvim_open_win? table<string, any> Extra nvim_open_win() options (overrides defaults)

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
  network = {
    connect_timeout = 5,
    request_timeout = 15,
  },
  history = {
    enabled = false,
    limit = 20,
  },
  display = "float", -- "float" or "picker"
  picker = "auto", -- "auto", "telescope", "fzf", "snacks", "mini"
  float = {
    border = "rounded",
    mode = "center",
    max_width = 80,
    max_height = 20,
    auto_close_ms = 0,
    pin = true,
    copy_original = false,
    nvim_open_win = {},
  },
  keymaps = {
    translate = "<leader>tr",
    translate_word = "<leader>tw",
  },
  deepl = {
    api_key = nil, -- use DEEPL_API_KEY env
    pro = nil, -- auto-detect by key suffix
    formality = "default",
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
