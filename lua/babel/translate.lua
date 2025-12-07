local M = {}

local config = require("babel.config")
local ui = require("babel.ui")

-- Provider registry
local providers = {
  google = require("babel.providers.google"),
  deepl = require("babel.providers.deepl"),
}

---Get providers by name
---@param name string
---@return table?
local function get_provider(name)
  return providers[name]
end

---Translates text
---@param text string Text to translate
function M.translate(text)
  local opts = config.options
  local provider = get_provider(opts.provider)

  if not provider then
    vim.notify("Babel: Unknown provider: " .. opts.provider, vim.log.levels.ERROR)
    return
  end
  if text == "" then
    vim.notify("Babel: No text to translate", vim.log.levels.WARN)
    return
  end

  provider.translate(text, opts.source, opts.target, function(result, err)
    if err then
      if opts.provider == "deepl" and err:match("API key") then
        vim.notify("Babel: DeepL API key not found, falling back to Google", vim.log.levels.WARN)
        providers.google.translate(text, opts.source, opts.target, function(r, e)
          if e then
            vim.notify("Babel: " .. e, vim.log.levels.ERROR)
            return
          end
          ui.show(r, text)
        end)
        return
      end
      vim.notify("Babel: " .. err, vim.log.levels.ERROR)
      return
    end
    ui.show(result, text)
  end)
end

return M
