local T = MiniTest.new_set()

local function eq(actual, expected)
  assert(actual == expected, string.format("Expected %s, got %s", vim.inspect(expected), vim.inspect(actual)))
end

local function capture_open_win(float_opts)
  local ui = require("babel.ui")
  local config = require("babel.config")

  config.setup({ float = float_opts })

  local captured_opts
  local notifications = {}

  local api = vim.api
  local original_list_uis = api.nvim_list_uis
  local original_open_win = api.nvim_open_win
  local original_notify = vim.notify

  api.nvim_list_uis = function()
    return { { width = 120, height = 40 } }
  end

  api.nvim_open_win = function(_, _, opts)
    captured_opts = vim.deepcopy(opts)
    return vim.api.nvim_get_current_win()
  end

  vim.notify = function(msg, level)
    table.insert(notifications, { msg = msg, level = level })
  end

  local ok, err = pcall(ui.show_float, "translated text", "original")

  api.nvim_list_uis = original_list_uis
  api.nvim_open_win = original_open_win
  vim.notify = original_notify

  assert(ok, err)

  return captured_opts, notifications
end

T["float mode defaults to center preset"] = function()
  local win_opts = capture_open_win({})

  eq(win_opts.relative, "editor")
  eq(win_opts.row, 19)
  eq(win_opts.col, 51)
  eq(win_opts.width, 20)
  eq(win_opts.height, 3)
end

T["float mode cursor follows cursor by preset"] = function()
  local win_opts = capture_open_win({ mode = "cursor" })

  eq(win_opts.relative, "cursor")
  eq(win_opts.row, 1)
  eq(win_opts.col, 0)
  eq(win_opts.anchor, "NW")
end

T["nvim_open_win options override preset defaults"] = function()
  local win_opts = capture_open_win({
    mode = "cursor",
    nvim_open_win = {
      relative = "editor",
      row = 5,
      col = 7,
      anchor = "SW",
    },
  })

  eq(win_opts.relative, "editor")
  eq(win_opts.row, 5)
  eq(win_opts.col, 7)
  eq(win_opts.anchor, "SW")
end

T["invalid mode warns and falls back to center"] = function()
  local win_opts, notifications = capture_open_win({ mode = "invalid" })

  eq(win_opts.relative, "editor")
  eq(notifications[1].msg, "Babel: float.mode must be 'center' or 'cursor'")
  eq(notifications[1].level, vim.log.levels.WARN)
end

return T
