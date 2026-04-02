local T = MiniTest.new_set()

local function eq(actual, expected)
  assert(actual == expected, string.format("Expected %s, got %s", vim.inspect(expected), vim.inspect(actual)))
end

local function has_keymap(buf, lhs)
  for _, map in ipairs(vim.api.nvim_buf_get_keymap(buf, "n")) do
    if map.lhs == lhs then
      return true
    end
  end

  return false
end

local function capture_open_win(float_opts)
  local ui = require("babel.ui")
  local config = require("babel.config")

  config.setup({ float = float_opts })

  local captured_opts
  local captured_buf
  local captured_enter
  local notifications = {}
  local created_autocmds = {}

  local api = vim.api
  local original_list_uis = api.nvim_list_uis
  local original_open_win = api.nvim_open_win
  local original_notify = vim.notify
  local original_create_autocmd = api.nvim_create_autocmd
  local original_create_augroup = api.nvim_create_augroup

  api.nvim_list_uis = function()
    return { { width = 120, height = 40 } }
  end

  api.nvim_open_win = function(buf, enter, opts)
    captured_buf = buf
    captured_enter = enter
    captured_opts = vim.deepcopy(opts)
    return vim.api.nvim_get_current_win()
  end

  vim.notify = function(msg, level)
    table.insert(notifications, { msg = msg, level = level })
  end

  api.nvim_create_augroup = function(name, opts)
    return 1
  end

  api.nvim_create_autocmd = function(event, opts)
    table.insert(created_autocmds, { event = event, opts = opts })
    return 1
  end

  local ok, err = pcall(ui.show_float, "translated text", "original")

  api.nvim_list_uis = original_list_uis
  api.nvim_open_win = original_open_win
  vim.notify = original_notify
  api.nvim_create_autocmd = original_create_autocmd
  api.nvim_create_augroup = original_create_augroup

  assert(ok, err)

  return captured_opts, notifications, captured_buf, captured_enter, created_autocmds
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

T["invalid auto_close_ms warns and is ignored"] = function()
  local _, notifications = capture_open_win({ auto_close_ms = -10 })

  eq(notifications[1].msg, "Babel: float.auto_close_ms must be >= 0")
  eq(notifications[1].level, vim.log.levels.WARN)
end

T["copy_original enables Y mapping"] = function()
  local _, _, buf = capture_open_win({ copy_original = true })
  eq(has_keymap(buf, "Y"), true)
end

T["pin mapping enabled when auto-close is active"] = function()
  local _, _, buf = capture_open_win({ auto_close_ms = 60000, pin = true })
  eq(has_keymap(buf, "p"), true)
end

T["pin mapping disabled when pin toggle is off"] = function()
  local _, _, buf = capture_open_win({ auto_close_ms = 60000, pin = false })
  eq(has_keymap(buf, "p"), false)
end

T["enter defaults to true"] = function()
  local _, _, _, captured_enter = capture_open_win({})
  eq(captured_enter, true)
end

T["enter false opens window without focus"] = function()
  local _, _, _, captured_enter = capture_open_win({ enter = false })
  eq(captured_enter, false)
end

T["auto_close creates CursorMoved autocmd"] = function()
  local _, _, _, _, autocmds = capture_open_win({ auto_close = true })
  local found = false
  for _, ac in ipairs(autocmds) do
    if ac.event == "CursorMoved" and ac.opts.once == true then
      found = true
    end
  end
  eq(found, true)
end

T["auto_close disabled by default"] = function()
  local _, _, _, _, autocmds = capture_open_win({})
  local found = false
  for _, ac in ipairs(autocmds) do
    if ac.event == "CursorMoved" then
      found = true
    end
  end
  eq(found, false)
end

T["peek mode combines enter false with auto_close"] = function()
  local _, _, _, captured_enter, autocmds = capture_open_win({ enter = false, auto_close = true })
  eq(captured_enter, false)
  local found = false
  for _, ac in ipairs(autocmds) do
    if ac.event == "CursorMoved" and ac.opts.once == true then
      found = true
    end
  end
  eq(found, true)
end

return T
