local T = MiniTest.new_set()

local function eq(actual, expected)
  assert(actual == expected, string.format("Expected %s, got %s", vim.inspect(expected), vim.inspect(actual)))
end

local function with_jobstart(stub, fn)
  local original = vim.fn.jobstart
  vim.fn.jobstart = stub

  local ok, err = pcall(fn)

  vim.fn.jobstart = original
  assert(ok, err)
end

T["returns timeout error for curl exit 28"] = function()
  with_jobstart(function(_, opts)
    opts.on_stdout(nil, { "" })
    opts.on_stderr(nil, { "" })
    opts.on_exit(nil, 28)
    return 1
  end, function()
    package.loaded["babel.providers.curl"] = nil
    local curl = require("babel.providers.curl")
    local response, err

    curl.run({ "curl" }, { provider = "google", timeout = 15 }, function(r, e)
      response, err = r, e
    end)

    eq(response, nil)
    eq(err.code, "timeout")
    eq(err.provider, "google")
    eq(err.message, "request timed out after 15s")
  end)
end

T["returns curl exit error with stderr"] = function()
  with_jobstart(function(_, opts)
    opts.on_stdout(nil, { "" })
    opts.on_stderr(nil, { "resolve failed" })
    opts.on_exit(nil, 6)
    return 1
  end, function()
    package.loaded["babel.providers.curl"] = nil
    local curl = require("babel.providers.curl")
    local response, err

    curl.run({ "curl" }, { provider = "deepl" }, function(r, e)
      response, err = r, e
    end)

    eq(response, nil)
    eq(err.code, "curl_exit")
    eq(err.provider, "deepl")
    eq(err.exit_code, 6)
    eq(err.stderr, "resolve failed")
  end)
end

T["returns stdout on success"] = function()
  with_jobstart(function(_, opts)
    opts.on_stdout(nil, { '{"ok":true}' })
    opts.on_stderr(nil, { "" })
    opts.on_exit(nil, 0)
    return 1
  end, function()
    package.loaded["babel.providers.curl"] = nil
    local curl = require("babel.providers.curl")
    local response, err

    curl.run({ "curl" }, { provider = "google" }, function(r, e)
      response, err = r, e
    end)

    eq(response, '{"ok":true}')
    eq(err, nil)
  end)
end

return T
