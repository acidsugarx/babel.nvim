local M = {}
local NEWLINE_MARKER = " @@000@@ "
local config = require("babel.config")
local curl = require("babel.providers.curl")

---Helper function for handle uri_encode in new versions or custom url_encode on older
local function url_encode(str)
  if vim.uri_encode then
    return vim.uri_encode(str)
  end
  -- fallback for old versions
  return string.gsub(str, "([^%w%-_.~])", function(c)
    return string.format("%%%02X", string.byte(c))
  end)
end

---Translate text using Google Translate
---@param text string Text to translate
---@param source string Source language code
---@param target string Target language code
---@param callback fun(result: string|nil, err: table|string|nil) Callback with translated text
function M.translate(text, source, target, callback)
  local clean_text = text:gsub("\n", NEWLINE_MARKER)
  local encoded_text = url_encode(clean_text)
  local network_opts = config.options.network or {}
  local timeout_args, _, request_timeout = curl.timeout_args(network_opts)

  -- Use POST request to avoid URL length limits
  local cmd = {
    "curl",
    "-sS",
  }
  vim.list_extend(cmd, timeout_args)
  vim.list_extend(cmd, {
    "-X",
    "POST",
    "-H",
    "Content-Type: application/x-www-form-urlencoded",
    "-d",
    string.format("client=gtx&sl=%s&tl=%s&dt=t&q=%s", source, target, encoded_text),
    "https://translate.googleapis.com/translate_a/single",
  })

  curl.run(cmd, { provider = "google", request_timeout = request_timeout }, function(response, err)
    if err then
      callback(nil, err)
      return
    end

    if response == "" then
      callback(nil, {
        code = "empty_response",
        provider = "google",
        message = "empty response from API",
      })
      return
    end

    local ok, json = pcall(vim.json.decode, response)
    if not ok or type(json) ~= "table" then
      callback(nil, {
        code = "invalid_json",
        provider = "google",
        message = "invalid JSON response from API",
      })
      return
    end

    if type(json[1]) ~= "table" then
      callback(nil, {
        code = "invalid_response",
        provider = "google",
        message = "unexpected response shape from API",
      })
      return
    end

    local translated = ""
    for _, segment in ipairs(json[1]) do
      if type(segment) == "table" and type(segment[1]) == "string" then
        translated = translated .. segment[1]
      end
    end

    translated = translated:gsub(NEWLINE_MARKER, "\n")
    translated = translated:gsub("@@000@@", "\n")

    if translated == "" then
      callback(nil, {
        code = "invalid_response",
        provider = "google",
        message = "translation text missing in API response",
      })
      return
    end

    callback(translated, nil)
  end)
end

return M
