local M = {}

local config = require("babel.config")
local ui = require("babel.ui")

local state = {
  last_text = nil,
  history = {},
  cache = {},
  cache_keys = {},
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

local function get_cache_opts()
  return config.options.cache or {}
end

local function get_cache_limit()
  local cache_opts = get_cache_opts()
  local limit = tonumber(cache_opts.limit) or 200

  if limit < 1 then
    return 1
  end

  return math.floor(limit)
end

local function is_cache_enabled()
  local cache_opts = get_cache_opts()
  return cache_opts.enabled == true
end

local function normalize_chain(primary_provider)
  local chain_by_provider = config.options.fallback_chain or {}
  local provider_chain = chain_by_provider[primary_provider]
  if type(provider_chain) ~= "table" then
    return {}
  end

  local seen = {}
  local chain = {}

  for _, provider_name in ipairs(provider_chain) do
    if
      type(provider_name) == "string"
      and provider_name ~= ""
      and provider_name ~= primary_provider
      and not seen[provider_name]
    then
      table.insert(chain, provider_name)
      seen[provider_name] = true
    end
  end

  return chain
end

local function cache_key(opts, text)
  if not is_cache_enabled() then
    return nil
  end

  local payload = {
    provider = opts.provider,
    source = opts.source,
    target = opts.target,
    text = text,
    deepl_formality = (opts.deepl or {}).formality,
  }

  return vim.json.encode(payload)
end

local function cache_get(key)
  if not key then
    return nil
  end

  return state.cache[key]
end

local function cache_set(key, entry)
  if not key then
    return
  end

  if state.cache[key] == nil then
    table.insert(state.cache_keys, key)
  end

  state.cache[key] = entry

  local limit = get_cache_limit()
  while #state.cache_keys > limit do
    local old_key = table.remove(state.cache_keys, 1)
    state.cache[old_key] = nil
  end
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

local function handle_success(result, original, provider_name, opts, meta)
  meta = meta or {}

  if type(result) ~= "string" or result == "" then
    vim.notify("Babel: " .. provider_title(provider_name) .. ": empty translation result", vim.log.levels.ERROR)
    return
  end

  if not meta.from_cache and meta.cache_key then
    cache_set(meta.cache_key, {
      result = result,
      provider = provider_name,
    })
  end

  push_history_entry(original, result, provider_name, opts.source, opts.target)
  ui.show(result, original)
end

---Translates text
---@param text string Text to translate
function M.translate(text)
  local opts = config.options
  local primary_provider = opts.provider
  local provider = get_provider(primary_provider)

  if not provider then
    vim.notify("Babel: Unknown provider: " .. primary_provider, vim.log.levels.ERROR)
    return
  end
  if text == "" then
    vim.notify("Babel: No text to translate", vim.log.levels.WARN)
    return
  end

  state.last_text = text

  local key = cache_key(opts, text)
  local cached_entry = cache_get(key)
  if cached_entry then
    handle_success(cached_entry.result, text, cached_entry.provider or primary_provider, opts, {
      from_cache = true,
    })
    return
  end

  local fallback_chain = normalize_chain(primary_provider)

  local providers_to_try = { primary_provider }
  for _, provider_name in ipairs(fallback_chain) do
    table.insert(providers_to_try, provider_name)
  end

  local function attempt(index)
    local provider_name = providers_to_try[index]
    if provider_name == nil then
      return
    end

    local current_provider = get_provider(provider_name)
    if not current_provider then
      local next_provider_name = providers_to_try[index + 1]
      if next_provider_name then
        vim.notify("Babel: Unknown provider in fallback chain: " .. provider_name, vim.log.levels.WARN)
        attempt(index + 1)
      else
        vim.notify("Babel: Unknown provider in fallback chain: " .. provider_name, vim.log.levels.ERROR)
      end
      return
    end

    current_provider.translate(text, opts.source, opts.target, function(result, err)
      if err then
        local next_provider_name = providers_to_try[index + 1]
        if next_provider_name then
          if provider_name == "deepl" and next_provider_name == "google" and is_deepl_missing_key(err) then
            vim.notify("Babel: DeepL API key not found, falling back to Google", vim.log.levels.WARN)
          else
            local message = type(err) == "table" and (err.message or err.code or "provider error") or tostring(err)
            local notify_message = string.format(
              "Babel: %s failed (%s), falling back to %s",
              provider_title(provider_name),
              message,
              provider_title(next_provider_name)
            )
            vim.notify(notify_message, vim.log.levels.WARN)
          end

          attempt(index + 1)
          return
        end

        vim.notify("Babel: " .. normalize_provider_error(provider_name, err), vim.log.levels.ERROR)
        return
      end

      handle_success(result, text, provider_name, opts, {
        cache_key = key,
      })
    end)
  end

  attempt(1)
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

---Clear translation cache
function M.clear_cache()
  state.cache = {}
  state.cache_keys = {}
end

return M
