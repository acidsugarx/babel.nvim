local M = {}

local config = require("babel.config")

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
---@param _original string Original text (reserved for future use)
---@param opts? BabelFloatOptions
function M.show_float(text, _original, opts)
  opts = opts or config.options.float
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

  -- Create window
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = math.max(width, 20),
    height = math.max(height, 3),
    row = row,
    col = col,
    style = "minimal",
    border = opts.border or "rounded",
    title = " Translation ",
    title_pos = "center",
  })

  -- Window options
  vim.wo[win].wrap = true
  vim.wo[win].cursorline = false

  -- Keymaps to close
  local close_keys = { "q", "<Esc>", "<CR>" }
  for _, key in ipairs(close_keys) do
    vim.keymap.set("n", key, function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = buf, nowait = true })
  end

  -- Copy to clipboard on yank
  vim.keymap.set("n", "y", function()
    vim.fn.setreg("+", text)
    vim.notify("Translation copied to clipboard", vim.log.levels.INFO)
  end, { buffer = buf, nowait = true })
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
