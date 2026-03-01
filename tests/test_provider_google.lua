local T = MiniTest.new_set()

local function eq(actual, expected)
  assert(actual == expected, string.format("Expected %s, got %s", vim.inspect(expected), vim.inspect(actual)))
end

local function with_google(stub_curl, setup_opts, fn)
  local config = require("babel.config")

  package.loaded["babel.providers.curl"] = {
    timeout_args = function(opts)
      return {}, opts and opts.connect_timeout or 5, opts and opts.request_timeout or 15
    end,
    run = stub_curl,
  }

  config.setup(setup_opts or {})
  package.loaded["babel.providers.google"] = nil

  local ok, err = pcall(function()
    local google = require("babel.providers.google")
    fn(google)
  end)

  package.loaded["babel.providers.google"] = nil
  package.loaded["babel.providers.curl"] = nil

  assert(ok, err)
end

T["returns error for empty response"] = function()
  with_google(function(_, _, cb)
    cb("", nil)
  end, {}, function(google)
    local result, err
    google.translate("hello", "auto", "ru", function(r, e)
      result, err = r, e
    end)

    eq(result, nil)
    eq(err.code, "empty_response")
  end)
end

T["returns error for invalid JSON"] = function()
  with_google(function(_, _, cb)
    cb("{oops", nil)
  end, {}, function(google)
    local result, err
    google.translate("hello", "auto", "ru", function(r, e)
      result, err = r, e
    end)

    eq(result, nil)
    eq(err.code, "invalid_json")
  end)
end

T["returns error for unexpected response shape"] = function()
  with_google(function(_, _, cb)
    cb("{}", nil)
  end, {}, function(google)
    local result, err
    google.translate("hello", "auto", "ru", function(r, e)
      result, err = r, e
    end)

    eq(result, nil)
    eq(err.code, "invalid_response")
  end)
end

T["returns translated text on valid response"] = function()
  with_google(function(_, _, cb)
    cb('[[["privet"]]]', nil)
  end, {}, function(google)
    local result, err
    google.translate("hello", "auto", "ru", function(r, e)
      result, err = r, e
    end)

    eq(err, nil)
    eq(result, "privet")
  end)
end

T["uses configured request timeout"] = function()
  local seen_timeout

  with_google(function(_, opts, cb)
    seen_timeout = opts.request_timeout
    cb('[[["privet"]]]', nil)
  end, {
    network = {
      connect_timeout = 3,
      request_timeout = 22,
    },
  }, function(google)
    local result, err
    google.translate("hello", "auto", "ru", function(r, e)
      result, err = r, e
    end)

    eq(err, nil)
    eq(result, "privet")
    eq(seen_timeout, 22)
  end)
end

return T
