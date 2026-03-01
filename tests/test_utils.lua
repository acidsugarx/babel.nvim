local T = MiniTest.new_set()

local function eq(actual, expected)
  assert(actual == expected, string.format("Expected %s, got %s", vim.inspect(expected), vim.inspect(actual)))
end

T["get_line_range returns joined text for line span"] = function()
  local utils = require("babel.utils")

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alpha", "beta", "gamma" })
  local text = utils.get_line_range(1, 2)

  eq(text, "alpha\nbeta")
end

T["get_line_range handles single line"] = function()
  local utils = require("babel.utils")

  vim.api.nvim_buf_set_lines(0, 0, -1, false, { "alpha", "beta", "gamma" })
  local text = utils.get_line_range(3, 3)

  eq(text, "gamma")
end

return T
