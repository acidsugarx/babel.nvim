local M = {}

local config = require("babel.config")
local curl = require("babel.providers.curl")

local ENDPOINT = "https://translate.api.cloud.yandex.net/translate/v2/translate"

---Get IAM token from config or YANDEX_TRANSLATE_IAM_TOKEN env.
---@return string|nil
local function get_iam_token()
  local yandex_opts = config.options.yandex or {}
  if yandex_opts.iam_token then
    return yandex_opts.iam_token
  end
  return os.getenv("YANDEX_TRANSLATE_IAM_TOKEN")
end

---Get folder ID from config or YANDEX_FOLDER_ID env.
---@return string|nil
local function get_folder_id()
  local yandex_opts = config.options.yandex or {}
  if yandex_opts.folder_id then
    return yandex_opts.folder_id
  end
  return os.getenv("YANDEX_FOLDER_ID")
end

---Map source language code. Yandex expects lowercase; "auto" = omit (Yandex detects automatically).
---@param source string Source language code
---@return string|nil
local function map_source_lang(source)
  if not source or source == "auto" then
    return nil
  end
  return source:lower()
end

---Translate text using Yandex Translate API v2.
---@param text string Text to translate
---@param source string Source language code
---@param target string Target language code
---@param callback fun(result: string|nil, err: table|string|nil) Callback with translated text
function M.translate(text, source, target, callback)
  local iam_token = get_iam_token()
  local folder_id = get_folder_id()

  if not iam_token then
    callback(nil, {
      code = "missing_api_key",
      provider = "yandex",
      message = "IAM token not found",
    })
    return
  end

  if not folder_id then
    callback(nil, {
      code = "missing_folder_id",
      provider = "yandex",
      message = "folder ID not found",
    })
    return
  end

  local body = {
    sourceLanguageCode = map_source_lang(source),
    targetLanguageCode = target:lower(),
    texts = { text },
    folderId = folder_id,
  }

  -- Remove nil fields so vim.json.encode doesn't produce "null"
  if body.sourceLanguageCode == nil then
    body.sourceLanguageCode = nil
  end

  local network_opts = config.options.network or {}
  local timeout_args, _, request_timeout = curl.timeout_args(network_opts)

  local cmd = {
    "curl",
    "-sS",
  }
  vim.list_extend(cmd, timeout_args)
  vim.list_extend(cmd, {
    "-X",
    "POST",
    "-H",
    "Authorization: Bearer " .. iam_token,
    "-H",
    "Content-Type: application/json",
    "-d",
    vim.json.encode(body),
    ENDPOINT,
  })

  curl.run(cmd, { provider = "yandex", request_timeout = request_timeout }, function(response, err)
    if err then
      callback(nil, err)
      return
    end

    if response == "" then
      callback(nil, {
        code = "empty_response",
        provider = "yandex",
        message = "empty response from API",
      })
      return
    end

    local ok, json = pcall(vim.json.decode, response)
    if not ok or type(json) ~= "table" then
      callback(nil, {
        code = "invalid_json",
        provider = "yandex",
        message = "invalid JSON response from API",
      })
      return
    end

    -- Yandex error shape: { error: { message: "...", code: ... } }
    if type(json.error) == "table" and json.error.message then
      callback(nil, {
        code = "api_error",
        provider = "yandex",
        message = "API error: " .. json.error.message,
      })
      return
    end

    if type(json.translations) ~= "table" or type(json.translations[1]) ~= "table" then
      callback(nil, {
        code = "invalid_response",
        provider = "yandex",
        message = "unexpected response shape from API",
      })
      return
    end

    local translated = json.translations[1].text
    if type(translated) ~= "string" or translated == "" then
      callback(nil, {
        code = "invalid_response",
        provider = "yandex",
        message = "translation text missing in API response",
      })
      return
    end

    callback(translated, nil)
  end)
end

return M
