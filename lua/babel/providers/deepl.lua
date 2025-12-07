local M = {}

local config = require("babel.config")

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
---@param callback fun(result: string) Callback with translated text
function M.translate(text, source, target, callback)
  local api_key = get_api_key()
  local endpoint = get_endpoint(api_key)

  if not api_key then
    callback(nil, "DeepL API key not found")
    return
  end

  local body = {
    text = { text },
    target_lang = target:upper(),
    source_lang = map_source_lang(source),
    formality = (config.options.deepl or {}).formality,
  }

  local cmd = {
    "curl",
    "-s",
    "-X",
    "POST",
    "-H",
    "Authorization: DeepL-Auth-Key " .. api_key,
    "-H",
    "Content-Type: application/json",
    "-d",
    vim.json.encode(body),
    endpoint,
  }

  vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      local response = table.concat(data, "")

      if response == "" then
        callback(nil, "Empty response")
        return
      end
      local ok, json = pcall(vim.json.decode, response)
      if not ok then
        callback(nil, "JSON parse error")
        return
      end

      local translated = ""

      if json.translations and json.translations[1] then
        translated = json.translations[1].text
      end
      callback(translated, nil)
    end,
  })
end

return M
