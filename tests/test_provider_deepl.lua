local T = MiniTest.new_set()

local function eq(actual, expected)
  assert(actual == expected, string.format("Expected %s, got %s", vim.inspect(expected), vim.inspect(actual)))
end

local function with_deepl(stub_curl, setup_opts, fn)
  local config = require("babel.config")

  package.loaded["babel.providers.curl"] = {
    timeout_args = function()
      return {}, 15
    end,
    run = stub_curl,
  }

  config.setup(setup_opts or {})
  package.loaded["babel.providers.deepl"] = nil

  local ok, err = pcall(function()
    local deepl = require("babel.providers.deepl")
    fn(deepl)
  end)

  package.loaded["babel.providers.deepl"] = nil
  package.loaded["babel.providers.curl"] = nil

  assert(ok, err)
end

T["returns missing_api_key when no key configured"] = function()
  local original_getenv = os.getenv
  os.getenv = function(name)
    if name == "DEEPL_API_KEY" then
      return nil
    end
    return original_getenv(name)
  end

  local ok, err = pcall(function()
    with_deepl(function()
      error("curl.run should not be called without API key")
    end, {
      deepl = { api_key = nil },
    }, function(deepl)
      local result, callback_err
      deepl.translate("hello", "auto", "ru", function(r, e)
        result, callback_err = r, e
      end)

      eq(result, nil)
      eq(callback_err.code, "missing_api_key")
    end)
  end)

  os.getenv = original_getenv
  assert(ok, err)
end

T["returns error for empty response"] = function()
  with_deepl(function(_, _, cb)
    cb("", nil)
  end, {
    deepl = { api_key = "test-key" },
  }, function(deepl)
    local result, err
    deepl.translate("hello", "auto", "ru", function(r, e)
      result, err = r, e
    end)

    eq(result, nil)
    eq(err.code, "empty_response")
  end)
end

T["returns API error message from payload"] = function()
  with_deepl(function(_, _, cb)
    cb('{"message":"Quota exceeded"}', nil)
  end, {
    deepl = { api_key = "test-key" },
  }, function(deepl)
    local result, err
    deepl.translate("hello", "auto", "ru", function(r, e)
      result, err = r, e
    end)

    eq(result, nil)
    eq(err.code, "api_error")
    eq(err.message, "API error: Quota exceeded")
  end)
end

T["returns translated text on valid response"] = function()
  with_deepl(function(_, _, cb)
    cb('{"translations":[{"text":"privet"}]}', nil)
  end, {
    deepl = { api_key = "test-key" },
  }, function(deepl)
    local result, err
    deepl.translate("hello", "auto", "ru", function(r, e)
      result, err = r, e
    end)

    eq(err, nil)
    eq(result, "privet")
  end)
end

return T
