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

local function provider_title(name)
  local titles = {
    google = "Google",
    deepl = "DeepL",
  }
  return titles[name] or name
end

local function normalize_provider_error(provider_name, err)
  local prefix = provider_title(provider_name)

  if type(err) == "table" then
    local message = err.message or err.code or "unknown provider error"
    return string.format("%s: %s", prefix, message)
  end

  return string.format("%s: %s", prefix, tostring(err or "unknown provider error"))
end

local function is_deepl_missing_key(err)
  if type(err) == "table" then
    return err.code == "missing_api_key"
  end

  return tostring(err or ""):match("API key") ~= nil
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
      if opts.provider == "deepl" and is_deepl_missing_key(err) then
        vim.notify("Babel: DeepL API key not found, falling back to Google", vim.log.levels.WARN)
        providers.google.translate(text, opts.source, opts.target, function(r, e)
          if e then
            vim.notify("Babel: " .. normalize_provider_error("google", e), vim.log.levels.ERROR)
            return
          end

          if type(r) ~= "string" or r == "" then
            vim.notify("Babel: Google: empty translation result", vim.log.levels.ERROR)
            return
          end

          ui.show(r, text)
        end)
        return
      end

      vim.notify("Babel: " .. normalize_provider_error(opts.provider, err), vim.log.levels.ERROR)
      return
    end

    if type(result) ~= "string" or result == "" then
      vim.notify("Babel: " .. provider_title(opts.provider) .. ": empty translation result", vim.log.levels.ERROR)
      return
    end

    ui.show(result, text)
  end)
end

return M
