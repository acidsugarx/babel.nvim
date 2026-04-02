local T = MiniTest.new_set()

local function eq(actual, expected)
  assert(actual == expected, string.format("Expected %s, got %s", vim.inspect(expected), vim.inspect(actual)))
end

local languages = require("babel.languages")

T["get_list returns table with code and label"] = function()
  local list = languages.get_list()
  eq(type(list), "table")
  eq(#list > 0, true)
  eq(type(list[1].code), "string")
  eq(type(list[1].label), "string")
end

T["auto is always first"] = function()
  local list = languages.get_list()
  eq(list[1].code, "auto")
end

T["get_list respects override"] = function()
  local list = languages.get_list({ en = "English", ru = "Russian" })
  eq(#list, 2)
  local codes = {}
  for _, entry in ipairs(list) do
    table.insert(codes, entry.code)
  end
  table.sort(codes)
  eq(codes[1], "en")
  eq(codes[2], "ru")
end

T["built-in list has auto"] = function()
  eq(languages.auto ~= nil, true)
end

T["built-in list has common languages"] = function()
  eq(languages.en ~= nil, true)
  eq(languages.ru ~= nil, true)
  eq(languages.de ~= nil, true)
end

return T
