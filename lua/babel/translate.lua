local M = {}

local config = require("babel.config")
local ui = require("babel.ui")

local state = {
  last_text = nil,
  history = {},
}

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

local function get_history_opts()
  return config.options.history or {}
end

local function get_history_limit()
  local history_opts = get_history_opts()
  local limit = tonumber(history_opts.limit) or 20

  if limit < 1 then
    return 1
  end

  return math.floor(limit)
end

local function is_history_enabled()
  local history_opts = get_history_opts()
  return history_opts.enabled == true
end

local function push_history_entry(original, translated, provider_name, source, target)
  if not is_history_enabled() then
    return
  end

  local entry = {
    original = original,
    translated = translated,
    provider = provider_name,
    source = source,
    target = target,
    timestamp = os.time(),
  }

  table.insert(state.history, entry)

  local limit = get_history_limit()
  while #state.history > limit do
    table.remove(state.history, 1)
  end
end

local function handle_success(result, original, provider_name, opts)
  if type(result) ~= "string" or result == "" then
    vim.notify("Babel: " .. provider_title(provider_name) .. ": empty translation result", vim.log.levels.ERROR)
    return
  end

  push_history_entry(original, result, provider_name, opts.source, opts.target)
  ui.show(result, original)
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

  state.last_text = text

  provider.translate(text, opts.source, opts.target, function(result, err)
    if err then
      if opts.provider == "deepl" and is_deepl_missing_key(err) then
        vim.notify("Babel: DeepL API key not found, falling back to Google", vim.log.levels.WARN)
        providers.google.translate(text, opts.source, opts.target, function(r, e)
          if e then
            vim.notify("Babel: " .. normalize_provider_error("google", e), vim.log.levels.ERROR)
            return
          end

          handle_success(r, text, "google", opts)
        end)
        return
      end

      vim.notify("Babel: " .. normalize_provider_error(opts.provider, err), vim.log.levels.ERROR)
      return
    end

    handle_success(result, text, opts.provider, opts)
  end)
end

---Repeat translation for the last translated input
function M.repeat_last()
  if type(state.last_text) ~= "string" or state.last_text == "" then
    vim.notify("Babel: No previous translation to repeat", vim.log.levels.WARN)
    return
  end

  M.translate(state.last_text)
end

---Get collected translation history
---@return table[]
function M.get_history()
  return vim.deepcopy(state.history)
end

---Clear collected translation history
function M.clear_history()
  state.history = {}
end

return M
