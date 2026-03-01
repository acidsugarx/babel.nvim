local M = {}

---Get visually selected text
---@return string Selected text or empty string if nothing selected
function M.get_visual_selection()
  -- Save current register content
  local saved_reg = vim.fn.getreg("v")
  local saved_regtype = vim.fn.getregtype("v")

  -- Yank selection to register "v"
  vim.cmd('noautocmd normal! "vy')

  -- Get yanked text
  local text = vim.fn.getreg("v")

  -- Restore register
  vim.fn.setreg("v", saved_reg, saved_regtype)

  return text
end

---Get word under cursor
---@return string Word under cursor
function M.get_word_under_cursor()
  return vim.fn.expand("<cword>")
end

---Get text from line range
---@param line1 number Start line (1-based)
---@param line2 number End line (1-based)
---@return string
function M.get_line_range(line1, line2)
  local start_line = math.max(line1 - 1, 0)
  local end_line = math.max(line2, start_line)
  local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line, false)

  return table.concat(lines, "\n")
end

return M
