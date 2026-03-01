local T = MiniTest.new_set()

local function eq(actual, expected)
  assert(actual == expected, string.format("Expected %s, got %s", vim.inspect(expected), vim.inspect(actual)))
end

T["returns all provider capabilities"] = function()
  local capabilities = require("babel.providers.capabilities")
  local all = capabilities.get()

  eq(type(all.google), "table")
  eq(type(all.deepl), "table")
  eq(all.google.supports_formality, false)
  eq(all.deepl.supports_formality, true)
end

T["returns single provider capabilities"] = function()
  local capabilities = require("babel.providers.capabilities")
  local deepl = capabilities.get("deepl")

  eq(type(deepl), "table")
  eq(deepl.requires_api_key, true)
  eq(deepl.supports_auto_source, true)
end

T["returns nil for unknown provider"] = function()
  local capabilities = require("babel.providers.capabilities")
  eq(capabilities.get("unknown"), nil)
end

T["init exposes capability helper"] = function()
  package.loaded["babel"] = nil
  local babel = require("babel")
  local google = babel.get_provider_capabilities("google")

  eq(type(google), "table")
  eq(google.requires_api_key, false)
end

return T
