local T = MiniTest.new_set()

local function eq(actual, expected)
  assert(actual == expected, string.format("Expected %s, got %s", vim.inspect(expected), vim.inspect(actual)))
end

local function plugin_path()
  local this_file = debug.getinfo(1, "S").source:sub(2)
  local root = vim.fn.fnamemodify(this_file, ":h:h")
  return root .. "/plugin/babel.lua"
end

local function unload_commands()
  pcall(vim.api.nvim_del_user_command, "Babel")
  pcall(vim.api.nvim_del_user_command, "BabelWord")
end

local function with_stubbed_babel(stub, fn)
  local original_babel = package.loaded["babel"]

  unload_commands()
  package.loaded["babel"] = stub
  dofile(plugin_path())

  local ok, err = pcall(fn)

  unload_commands()
  package.loaded["babel"] = original_babel

  assert(ok, err)
end

T["registers Babel user commands"] = function()
  with_stubbed_babel({
    translate = function() end,
    translate_selection = function() end,
    translate_word = function() end,
  }, function()
    eq(vim.fn.exists(":Babel"), 2)
    eq(vim.fn.exists(":BabelWord"), 2)
  end)
end

T["Babel with args calls translate"] = function()
  local called = {}

  with_stubbed_babel({
    translate = function(text)
      called.translate = text
    end,
    translate_selection = function()
      called.selection = true
    end,
    translate_word = function()
      called.word = true
    end,
  }, function()
    vim.cmd([[Babel hello world]])

    eq(called.translate, "hello world")
    eq(called.selection, nil)
    eq(called.word, nil)
  end)
end

T["Babel without args calls translate_selection"] = function()
  local called = {}

  with_stubbed_babel({
    translate = function(text)
      called.translate = text
    end,
    translate_selection = function()
      called.selection = true
    end,
    translate_word = function()
      called.word = true
    end,
  }, function()
    vim.cmd("Babel")

    eq(called.translate, nil)
    eq(called.selection, true)
    eq(called.word, nil)
  end)
end

T["BabelWord calls translate_word"] = function()
  local called = {}

  with_stubbed_babel({
    translate = function(text)
      called.translate = text
    end,
    translate_selection = function()
      called.selection = true
    end,
    translate_word = function()
      called.word = true
    end,
  }, function()
    vim.cmd("BabelWord")

    eq(called.translate, nil)
    eq(called.selection, nil)
    eq(called.word, true)
  end)
end

return T
