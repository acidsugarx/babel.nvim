-- Minimal init for mini.test
-- This file sets up a minimal Neovim environment for testing

-- Add babel.nvim to runtimepath
vim.cmd([[set runtimepath=$VIMRUNTIME]])
vim.cmd([[set packpath=]])

local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":h:h")
vim.opt.rtp:append(root)

-- Add mini.test to runtimepath (will be cloned by CI)
local deps_path = root .. "/deps"
vim.opt.rtp:append(deps_path .. "/mini.test")

-- Setup mini.test
require("mini.test").setup()
