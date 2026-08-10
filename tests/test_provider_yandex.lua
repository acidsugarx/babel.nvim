local T = MiniTest.new_set()

local function eq(actual, expected)
  assert(actual == expected, string.format("Expected %s, got %s", vim.inspect(expected), vim.inspect(actual)))
end

local function with_yandex(stub_curl, setup_opts, fn)
  local config = require("babel.config")

  package.loaded["babel.providers.curl"] = {
    timeout_args = function(opts)
      return {}, opts and opts.connect_timeout or 5, opts and opts.request_timeout or 15
    end,
    run = stub_curl,
  }

  config.setup(setup_opts or {})
  package.loaded["babel.providers.yandex"] = nil

  local ok, err = pcall(function()
    local yandex = require("babel.providers.yandex")
    fn(yandex)
  end)

  package.loaded["babel.providers.yandex"] = nil
  package.loaded["babel.providers.curl"] = nil

  assert(ok, err)
end

T["returns missing_api_key when no IAM token configured"] = function()
  local original_getenv = os.getenv
  os.getenv = function(name)
    if name == "YANDEX_TRANSLATE_IAM_TOKEN" or name == "YANDEX_FOLDER_ID" then
      return nil
    end
    return original_getenv(name)
  end

  local ok, err = pcall(function()
    with_yandex(function()
      error("curl.run should not be called without IAM token")
    end, {
      yandex = { iam_token = nil, folder_id = nil },
    }, function(yandex)
      local result, callback_err
      yandex.translate("hello", "auto", "ru", function(r, e)
        result, callback_err = r, e
      end)

      eq(result, nil)
      eq(callback_err.code, "missing_api_key")
    end)
  end)

  os.getenv = original_getenv
  assert(ok, err)
end

T["returns missing_folder_id when no folder ID configured"] = function()
  local original_getenv = os.getenv
  os.getenv = function(name)
    if name == "YANDEX_FOLDER_ID" then
      return nil
    end
    if name == "YANDEX_TRANSLATE_IAM_TOKEN" then
      return "fake-token"
    end
    return original_getenv(name)
  end

  local ok, err = pcall(function()
    with_yandex(function()
      error("curl.run should not be called without folder ID")
    end, {
      yandex = { iam_token = "fake-token", folder_id = nil },
    }, function(yandex)
      local result, callback_err
      yandex.translate("hello", "auto", "ru", function(r, e)
        result, callback_err = r, e
      end)

      eq(result, nil)
      eq(callback_err.code, "missing_folder_id")
    end)
  end)

  os.getenv = original_getenv
  assert(ok, err)
end

T["returns error for empty response"] = function()
  with_yandex(function(_, _, cb)
    cb("", nil)
  end, {
    yandex = { iam_token = "test-token", folder_id = "test-folder" },
  }, function(yandex)
    local result, err
    yandex.translate("hello", "auto", "ru", function(r, e)
      result, err = r, e
    end)

    eq(result, nil)
    eq(err.code, "empty_response")
  end)
end

T["returns API error from error object"] = function()
  with_yandex(function(_, _, cb)
    cb('{"error":{"message":"Quota exceeded","code":7}}', nil)
  end, {
    yandex = { iam_token = "test-token", folder_id = "test-folder" },
  }, function(yandex)
    local result, err
    yandex.translate("hello", "auto", "ru", function(r, e)
      result, err = r, e
    end)

    eq(result, nil)
    eq(err.code, "api_error")
    eq(err.message, "API error: Quota exceeded")
  end)
end

T["returns translated text on valid response"] = function()
  with_yandex(function(_, _, cb)
    cb('{"translations":[{"text":"privet","detectedLanguageCode":"en"}]}', nil)
  end, {
    yandex = { iam_token = "test-token", folder_id = "test-folder" },
  }, function(yandex)
    local result, err
    yandex.translate("hello", "auto", "ru", function(r, e)
      result, err = r, e
    end)

    eq(err, nil)
    eq(result, "privet")
  end)
end

T["uses configured request timeout"] = function()
  local seen_timeout

  with_yandex(function(_, opts, cb)
    seen_timeout = opts.request_timeout
    cb('{"translations":[{"text":"privet"}]}', nil)
  end, {
    yandex = { iam_token = "test-token", folder_id = "test-folder" },
    network = {
      connect_timeout = 4,
      request_timeout = 23,
    },
  }, function(yandex)
    local result, err
    yandex.translate("hello", "auto", "ru", function(r, e)
      result, err = r, e
    end)

    eq(err, nil)
    eq(result, "privet")
    eq(seen_timeout, 23)
  end)
end

T["passes lowercase target and folder_id in request"] = function()
  local seen_cmd

  with_yandex(function(cmd, _, cb)
    seen_cmd = cmd
    cb('{"translations":[{"text":"privet"}]}', nil)
  end, {
    yandex = { iam_token = "test-token", folder_id = "test-folder" },
  }, function(yandex)
    yandex.translate("hello", "auto", "RU", function() end)

    -- Verify the request body contains targetLanguageCode lowercase and folderId
    local found_body = false
    for i, arg in ipairs(seen_cmd) do
      if arg == "-d" and seen_cmd[i + 1] then
        local body = vim.json.decode(seen_cmd[i + 1])
        eq(body.targetLanguageCode, "ru")
        eq(body.folderId, "test-folder")
        eq(body.sourceLanguageCode, nil) -- omitted for "auto"
        found_body = true
        break
      end
    end
    eq(found_body, true)
  end)
end

return T
