local M = {}

local config = require("babel.config")

-- Track current open float window to prevent stacking
local current_win = nil

-- Picker priority for auto-detection
local PICKER_PRIORITY = { "telescope", "fzf", "snacks", "mini" }

-- Check if a picker is available
local function picker_available(name)
  local checks = {
    telescope = function()
      return pcall(require, "telescope")
    end,
    fzf = function()
      return pcall(require, "fzf-lua")
    end,
    snacks = function()
      local ok, snacks = pcall(require, "snacks")
      return ok and snacks.picker ~= nil
    end,
    mini = function()
      return pcall(require, "mini.pick")
    end,
  }
  return checks[name] and checks[name]()
end

-- Auto-detect available picker
local function detect_picker()
  for _, name in ipairs(PICKER_PRIORITY) do
    if picker_available(name) then
      return name
    end
  end
  return nil
end

-- Get the picker to use
local function get_picker()
  local picker = config.options.picker
  if picker == "auto" then
    return detect_picker()
  end
  if picker_available(picker) then
    return picker
  end
  vim.notify("Babel: picker '" .. picker .. "' not available, falling back to float", vim.log.levels.WARN)
  return nil
end

---Show translation in focusable floating window
---@param text string Translated text
---@param original string Original text
---@param opts? BabelFloatOptions
function M.show_float(text, original, opts)
  opts = opts or config.options.float
  local user_win_opts = opts.nvim_open_win or {}
  local mode = opts.mode or "center"
  local enter = opts.enter ~= false
  local auto_close = opts.auto_close == true
  local auto_close_ms = tonumber(opts.auto_close_ms) or 0
  local allow_pin = opts.pin ~= false
  local allow_copy_original = opts.copy_original == true

  -- If no close mechanism exists, force auto_close to prevent stuck floats
  if not enter and not auto_close and auto_close_ms <= 0 then
    auto_close = true
  end

  if type(user_win_opts) ~= "table" then
    vim.notify("Babel: float.nvim_open_win must be a table", vim.log.levels.WARN)
    user_win_opts = {}
  end

  if mode ~= "center" and mode ~= "cursor" then
    vim.notify("Babel: float.mode must be 'center' or 'cursor'", vim.log.levels.WARN)
    mode = "center"
  end

  if auto_close_ms < 0 then
    vim.notify("Babel: float.auto_close_ms must be >= 0", vim.log.levels.WARN)
    auto_close_ms = 0
  end

  local lines = vim.split(text, "\n")

  -- Calculate dimensions
  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(line))
  end
  width = math.min(width + 2, opts.max_width or 80)
  local height = math.min(#lines, opts.max_height or 20)

  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "babel"

  -- Calculate centered position
  local ui_info = vim.api.nvim_list_uis()[1]
  local row = math.floor((ui_info.height - height) / 2)
  local col = math.floor((ui_info.width - width) / 2)
  local cursor_row = vim.fn.winline()
  local win_height = math.max(height, 3)

  -- Cursor mode: open above cursor if not enough space below
  local cursor_mode_row = 1
  if cursor_row + win_height + 1 > ui_info.height then
    cursor_mode_row = -win_height
  end

  local mode_opts = {
    center = {
      relative = "editor",
      row = row,
      col = col,
    },
    cursor = {
      relative = "cursor",
      row = cursor_mode_row,
      col = 0,
      anchor = "NW",
    },
  }

  local win_opts = vim.tbl_deep_extend("force", {
    relative = "editor",
    width = math.max(width, 20),
    height = math.max(height, 3),
    row = row,
    col = col,
    style = "minimal",
    border = opts.border or "rounded",
    title = " Translation ",
    title_pos = "center",
  }, mode_opts[mode], user_win_opts)

  -- Create window
  -- Close previous float if still open to prevent stacking
  if current_win and vim.api.nvim_win_is_valid(current_win) then
    pcall(vim.api.nvim_win_close, current_win, true)
    current_win = nil
  end
  local source_buf = vim.api.nvim_get_current_buf()
  local ok, win = pcall(vim.api.nvim_open_win, buf, enter, win_opts)
  if not ok then
    pcall(vim.api.nvim_buf_delete, buf, { force = true })
    vim.notify("Babel: failed to open float window: " .. win, vim.log.levels.ERROR)
    return
  end
  current_win = win

  local is_pinned = false
  local timer_generation = 0

  local function close_float()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if current_win == win then
      current_win = nil
    end
  end

  local function schedule_auto_close()
    if auto_close_ms <= 0 or is_pinned then
      return
    end

    timer_generation = timer_generation + 1
    local generation = timer_generation

    vim.defer_fn(function()
      if generation ~= timer_generation or is_pinned then
        return
      end
      close_float()
    end, auto_close_ms)
  end

  -- Window options
  vim.wo[win].wrap = true
  vim.wo[win].cursorline = false

  -- Keymaps to close
  local close_keys = { "q", "<Esc>", "<CR>" }
  for _, key in ipairs(close_keys) do
    vim.keymap.set("n", key, function()
      close_float()
    end, { buffer = buf, nowait = true })
  end

  -- Copy to clipboard on yank
  vim.keymap.set("n", "y", function()
    vim.fn.setreg("+", text)
    vim.notify("Translation copied to clipboard", vim.log.levels.INFO)
  end, { buffer = buf, nowait = true })

  if allow_copy_original and type(original) == "string" and original ~= "" then
    vim.keymap.set("n", "Y", function()
      vim.fn.setreg("+", original)
      vim.notify("Original copied to clipboard", vim.log.levels.INFO)
    end, { buffer = buf, nowait = true })
  end

  -- Open language picker from float
  vim.keymap.set("n", "L", function()
    M.show_lang_picker()
  end, { buffer = buf, nowait = true })

  if auto_close_ms > 0 and allow_pin then
    vim.keymap.set("n", "p", function()
      is_pinned = not is_pinned
      timer_generation = timer_generation + 1

      if is_pinned then
        vim.notify("Babel: float pinned", vim.log.levels.INFO)
      else
        vim.notify("Babel: float unpinned", vim.log.levels.INFO)
        schedule_auto_close()
      end
    end, { buffer = buf, nowait = true })
  end

  schedule_auto_close()

  -- Auto-close on CursorMoved in the source buffer
  if auto_close then
    local group = vim.api.nvim_create_augroup("BabelAutoClose" .. win, { clear = true })

    vim.api.nvim_create_autocmd("CursorMoved", {
      group = group,
      buffer = source_buf,
      once = true,
      callback = function()
        if not is_pinned then
          close_float()
        end
      end,
    })

    -- Clean up autocmd if window is closed by other means
    vim.api.nvim_create_autocmd("WinClosed", {
      group = group,
      pattern = tostring(win),
      once = true,
      callback = function()
        pcall(vim.api.nvim_del_augroup_by_id, group)
      end,
    })
  end
end

---Show language picker for source and target selection
---@param callback? fun(source: string, target: string) Called with selected languages
function M.show_lang_picker(callback)
  local languages = require("babel.languages")
  local lang_list = languages.get_list(config.options.languages)
  local current_source = config.options.source
  local current_target = config.options.target

  local function format_entry(entry)
    local marker = ""
    if entry.code == current_source then
      marker = " [source]"
    elseif entry.code == current_target then
      marker = " [target]"
    end
    return entry.label .. " (" .. entry.code .. ")" .. marker
  end

  local source_items = {}
  local target_items = {}
  for _, entry in ipairs(lang_list) do
    table.insert(source_items, format_entry(entry))
    -- Exclude "auto" from target selection — target must be explicit
    if entry.code ~= "auto" then
      table.insert(target_items, format_entry(entry))
    end
  end

  -- Step 1: pick source
  vim.ui.select(source_items, { prompt = "Source language" }, function(_, idx)
    if not idx then
      return
    end
    local picked_source = lang_list[idx].code
    config.options.source = picked_source

    -- Step 2: pick target (no "auto" option)
    local target_list = vim.tbl_filter(function(e)
      return e.code ~= "auto"
    end, lang_list)

    vim.ui.select(target_items, { prompt = "Target language" }, function(_, tidx)
      if not tidx then
        return
      end
      local picked_target = target_list[tidx].code
      config.options.target = picked_target

      if callback then
        callback(picked_source, picked_target)
      end
    end)
  end)
end

---Show translation using Telescope
---@param text string Translated text
---@param _original string Original text (reserved for future use)
function M.show_telescope(text, _original)
  -- Use Telescope's preview window as simple text display
  local pickers = require("telescope.pickers")
  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")

  local lines = vim.split(text, "\n")

  pickers
    .new({}, {
      prompt_title = "Babel Translation",
      finder = finders.new_table({
        results = lines,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          vim.fn.setreg("+", text)
          vim.notify("Translation copied to clipboard", vim.log.levels.INFO)
        end)
        return true
      end,
    })
    :find()
end

---Show translation using fzf-lua
---@param text string Translated text
---@param _original string Original text (reserved for future use)
function M.show_fzf(text, _original)
  local fzf = require("fzf-lua")
  local lines = vim.split(text, "\n")

  fzf.fzf_exec(lines, {
    prompt = "Babel> ",
    actions = {
      ["default"] = function()
        vim.fn.setreg("+", text)
        vim.notify("Translation copied to clipboard", vim.log.levels.INFO)
      end,
    },
  })
end

---Show translation using Snacks window
---@param text string Translated text
---@param _original string Original text (reserved for future use)
function M.show_snacks(text, _original)
  local snacks = require("snacks")
  local lines = vim.split(text, "\n")

  snacks.win({
    title = " Translation ",
    title_pos = "center",
    text = lines,
    width = 0.8,
    height = 0.6,
    border = "rounded",
    wo = {
      wrap = true,
      cursorline = false,
    },
    bo = {
      filetype = "babel",
      modifiable = false,
    },
    keys = {
      q = "close",
      ["<Esc>"] = "close",
      ["<CR>"] = "close",
      y = function(self)
        vim.fn.setreg("+", text)
        vim.notify("Translation copied to clipboard", vim.log.levels.INFO)
        self:close()
      end,
    },
  })
end

---Show translation using mini.pick
---@param text string Translated text
---@param _original string Original text (reserved for future use)
function M.show_mini(text, _original)
  local pick = require("mini.pick")
  local lines = vim.split(text, "\n")

  pick.start({
    source = {
      name = "Babel Translation",
      items = lines,
      choose = function()
        vim.fn.setreg("+", text)
        vim.notify("Translation copied to clipboard", vim.log.levels.INFO)
      end,
    },
  })
end

---Show translation using configured picker
---@param text string Translated text
---@param original string Original text
function M.show_picker(text, original)
  local picker = get_picker()

  if not picker then
    vim.notify("Babel: no picker available, using float", vim.log.levels.WARN)
    M.show_float(text, original)
    return
  end

  local handlers = {
    telescope = M.show_telescope,
    fzf = M.show_fzf,
    snacks = M.show_snacks,
    mini = M.show_mini,
  }

  handlers[picker](text, original)
end

---Main show function - routes to correct display method
---@param text string Translated text
---@param original string Original text
function M.show(text, original)
  local display = config.options.display

  if display == "picker" then
    M.show_picker(text, original)
  else
    M.show_float(text, original)
  end
end

return M
