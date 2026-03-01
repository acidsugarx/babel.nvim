local T = MiniTest.new_set()

local function eq(actual, expected)
  assert(actual == expected, string.format("Expected %s, got %s", vim.inspect(expected), vim.inspect(actual)))
end

local function with_translate(stubs, opts, fn)
  local config = require("babel.config")
  local original_notify = vim.notify
  local notifications = {}
  local shown = {}

  vim.notify = function(msg, level)
    table.insert(notifications, { msg = msg, level = level })
  end

  package.loaded["babel.providers.google"] = stubs.google
  package.loaded["babel.providers.deepl"] = stubs.deepl
  package.loaded["babel.ui"] = {
    show = function(result, original)
      table.insert(shown, { result = result, original = original })
    end,
  }
  package.loaded["babel.translate"] = nil

  config.setup(opts or {})

  local ok, err = pcall(function()
    local translate = require("babel.translate")
    fn(translate, notifications, shown)
  end)

  vim.notify = original_notify
  package.loaded["babel.translate"] = nil
  package.loaded["babel.ui"] = nil
  package.loaded["babel.providers.google"] = nil
  package.loaded["babel.providers.deepl"] = nil

  assert(ok, err)
end

T["normalizes provider error message"] = function()
  with_translate({
    google = {
      translate = function(_, _, _, cb)
        cb(nil, { code = "timeout", message = "request timed out after 15s" })
      end,
    },
    deepl = {
      translate = function()
        error("deepl provider should not be used")
      end,
    },
  }, {
    provider = "google",
  }, function(translate, notifications)
    translate.translate("hello")

    eq(notifications[1].msg, "Babel: Google: request timed out after 15s")
    eq(notifications[1].level, vim.log.levels.ERROR)
  end)
end

T["falls back from deepl missing key to google"] = function()
  with_translate({
    google = {
      translate = function(_, _, _, cb)
        cb("privet", nil)
      end,
    },
    deepl = {
      translate = function(_, _, _, cb)
        cb(nil, { code = "missing_api_key", message = "API key not found" })
      end,
    },
  }, {
    provider = "deepl",
  }, function(translate, notifications, shown)
    translate.translate("hello")

    eq(notifications[1].msg, "Babel: DeepL API key not found, falling back to Google")
    eq(notifications[1].level, vim.log.levels.WARN)
    eq(shown[1].result, "privet")
    eq(shown[1].original, "hello")
  end)
end

T["normalizes google error during deepl fallback"] = function()
  with_translate({
    google = {
      translate = function(_, _, _, cb)
        cb(nil, { code = "curl_exit", message = "request failed (curl exit 6)" })
      end,
    },
    deepl = {
      translate = function(_, _, _, cb)
        cb(nil, { code = "missing_api_key", message = "API key not found" })
      end,
    },
  }, {
    provider = "deepl",
  }, function(translate, notifications)
    translate.translate("hello")

    eq(notifications[1].msg, "Babel: DeepL API key not found, falling back to Google")
    eq(notifications[2].msg, "Babel: Google: request failed (curl exit 6)")
    eq(notifications[2].level, vim.log.levels.ERROR)
  end)
end

T["repeat_last warns when no previous translation"] = function()
  with_translate({
    google = {
      translate = function()
        error("google provider should not be used")
      end,
    },
    deepl = {
      translate = function()
        error("deepl provider should not be used")
      end,
    },
  }, {
    provider = "google",
  }, function(translate, notifications)
    translate.repeat_last()

    eq(notifications[1].msg, "Babel: No previous translation to repeat")
    eq(notifications[1].level, vim.log.levels.WARN)
  end)
end

T["repeat_last reuses last input text"] = function()
  local calls = {}

  with_translate({
    google = {
      translate = function(text, _, _, cb)
        table.insert(calls, text)
        cb("ok", nil)
      end,
    },
    deepl = {
      translate = function()
        error("deepl provider should not be used")
      end,
    },
  }, {
    provider = "google",
  }, function(translate)
    translate.translate("hello")
    translate.repeat_last()

    eq(#calls, 2)
    eq(calls[1], "hello")
    eq(calls[2], "hello")
  end)
end

T["history is empty when disabled"] = function()
  with_translate({
    google = {
      translate = function(_, _, _, cb)
        cb("privet", nil)
      end,
    },
    deepl = {
      translate = function()
        error("deepl provider should not be used")
      end,
    },
  }, {
    provider = "google",
    history = {
      enabled = false,
      limit = 10,
    },
  }, function(translate)
    translate.translate("hello")

    local history = translate.get_history()
    eq(#history, 0)
  end)
end

T["history stores entries with limit when enabled"] = function()
  with_translate({
    google = {
      translate = function(text, _, _, cb)
        cb(text .. "-translated", nil)
      end,
    },
    deepl = {
      translate = function()
        error("deepl provider should not be used")
      end,
    },
  }, {
    provider = "google",
    source = "auto",
    target = "ru",
    history = {
      enabled = true,
      limit = 2,
    },
  }, function(translate)
    translate.translate("one")
    translate.translate("two")
    translate.translate("three")

    local history = translate.get_history()
    eq(#history, 2)
    eq(history[1].original, "two")
    eq(history[1].translated, "two-translated")
    eq(history[2].original, "three")
    eq(history[2].translated, "three-translated")
  end)
end

return T
