local M = {}

local config = require("babel.config")
local curl = require("babel.providers.curl")

local REQUEST_TIMEOUT = 15

--- Gets api key from config/env
local function get_api_key()
  local key = config.options.deepl and config.options.deepl.api_key
  if key then
    return key
  end
  return os.getenv("DEEPL_API_KEY")
end

local function get_endpoint(api_key)
  local deepl_opts = config.options.deepl or {}

  if deepl_opts.pro == true then
    return "https://api.deepl.com/v2/translate"
  elseif deepl_opts.pro == false then
    return "https://api-free.deepl.com/v2/translate"
  end

  if not api_key then
    return "https://api-free.deepl.com/v2/translate"
  end

  if api_key:match(":fx$") then
    return "https://api-free.deepl.com/v2/translate"
  else
    return "https://api.deepl.com/v2/translate"
  end
end

local function map_source_lang(source)
  if not source then
    return nil
  end

  if source == "auto" then
    return nil
  else
    return source:upper()
  end
end

---Translate text using Deepl
---@param text string Text to translate
---@param source string Source language code
---@param target string Target language code
---@param callback fun(result: string|nil, err: table|string|nil) Callback with translated text
function M.translate(text, source, target, callback)
  local api_key = get_api_key()
  local endpoint = get_endpoint(api_key)

  if not api_key then
    callback(nil, {
      code = "missing_api_key",
      provider = "deepl",
      message = "API key not found",
    })
    return
  end

  local body = {
    text = { text },
    target_lang = target:upper(),
    source_lang = map_source_lang(source),
    formality = (config.options.deepl or {}).formality,
  }
  local timeout_args, timeout = curl.timeout_args(REQUEST_TIMEOUT)

  local cmd = {
    "curl",
    "-sS",
  }
  vim.list_extend(cmd, timeout_args)
  vim.list_extend(cmd, {
    "-X",
    "POST",
    "-H",
    "Authorization: DeepL-Auth-Key " .. api_key,
    "-H",
    "Content-Type: application/json",
    "-d",
    vim.json.encode(body),
    endpoint,
  })

  curl.run(cmd, { provider = "deepl", timeout = timeout }, function(response, err)
    if err then
      callback(nil, err)
      return
    end

    if response == "" then
      callback(nil, {
        code = "empty_response",
        provider = "deepl",
        message = "empty response from API",
      })
      return
    end

    local ok, json = pcall(vim.json.decode, response)
    if not ok or type(json) ~= "table" then
      callback(nil, {
        code = "invalid_json",
        provider = "deepl",
        message = "invalid JSON response from API",
      })
      return
    end

    if type(json.message) == "string" and json.message ~= "" then
      callback(nil, {
        code = "api_error",
        provider = "deepl",
        message = "API error: " .. json.message,
      })
      return
    end

    if type(json.translations) ~= "table" or type(json.translations[1]) ~= "table" then
      callback(nil, {
        code = "invalid_response",
        provider = "deepl",
        message = "unexpected response shape from API",
      })
      return
    end

    local translated = json.translations[1].text
    if type(translated) ~= "string" or translated == "" then
      callback(nil, {
        code = "invalid_response",
        provider = "deepl",
        message = "translation text missing in API response",
      })
      return
    end

    callback(translated, nil)
  end)
end

return M
