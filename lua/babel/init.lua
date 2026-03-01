---@class Babel Main plugin module
---@field setup fun(opts?: BabelOptions) Initialize plugin
---@field translate fun(text: string) Translate text
---@field translate_range fun(line1: number, line2: number) Translate line range
---@field translate_word fun() Translate word under cursor
---@field repeat_last_translation fun() Repeat last translation
---@field get_provider_capabilities fun(provider?: string): table|nil Get provider capability table

---@type BabelConfig
local config = require("babel.config")

local translate = require("babel.translate")
local utils = require("babel.utils")
local provider_capabilities = require("babel.providers.capabilities")

---@class Babel
local M = {}

---Initialize plugin
---@param opts? BabelOptions
function M.setup(opts)
  config.setup(opts)

  -- Setup keymaps from config
  local keymaps = config.options.keymaps

  -- Visual mode: translate selection
  vim.keymap.set("v", keymaps.translate, function()
    -- Exit VM first, then translate
    M.translate_selection()
  end, { desc = "Babel: Translate selection" })

  -- Normal mode: translate word under cursor
  vim.keymap.set("n", keymaps.translate_word, function()
    M.translate_word()
  end, { desc = "Babel: Translate word" })
end

---Translate text
---@param text string Text to translate
function M.translate(text)
  translate.translate(text)
end

---Translate line range
---@param line1 number Start line (1-based)
---@param line2 number End line (1-based)
function M.translate_range(line1, line2)
  local text = utils.get_line_range(line1, line2)
  translate.translate(text)
end

---Translate visual selection
function M.translate_selection()
  local text = utils.get_visual_selection()
  translate.translate(text)
end

---Translate word under cursor
function M.translate_word()
  local text = utils.get_word_under_cursor()
  translate.translate(text)
end

---Repeat last translation
function M.repeat_last_translation()
  translate.repeat_last()
end

---Get provider capabilities
---@param provider? string
---@return table|nil
function M.get_provider_capabilities(provider)
  return provider_capabilities.get(provider)
end

return M
