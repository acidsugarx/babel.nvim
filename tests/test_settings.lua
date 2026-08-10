local T = MiniTest.new_set()

local function eq(actual, expected)
  assert(actual == expected, string.format("Expected %s, got %s", vim.inspect(expected), vim.inspect(actual)))
end

---Run fn with a temporary settings file path.
local function with_temp_settings(fn)
  local settings = require("babel.settings")
  local original_path = settings.get_path()

  -- Override path to a temp file
  local tmp = vim.fn.tempname()
  -- Inject via package path override (settings.lua uses module-local `path`)
  package.loaded["babel.settings"] = nil
  package.loaded["babel.settings"] = require("babel.settings")
  -- Re-require and override the upvalue by reloading
  local settings_mod = package.loaded["babel.settings"]
  -- Monkey-patch the functions to use our temp path
  local real_load = settings_mod.load
  local real_save = settings_mod.save
  local real_set = settings_mod.set

  settings_mod.load = function()
    local file = io.open(tmp, "r")
    if not file then
      return {}
    end
    local content = file:read("*a")
    file:close()
    if not content or content == "" then
      return {}
    end
    local ok, data = pcall(vim.json.decode, content)
    if not ok or type(data) ~= "table" then
      return {}
    end
    return data
  end
  settings_mod.save = function(opts)
    local file = io.open(tmp, "w")
    if not file then
      return
    end
    file:write(vim.json.encode(opts))
    file:close()
  end
  settings_mod.set = function(key, value)
    local current = settings_mod.load()
    current[key] = value
    settings_mod.save(current)
  end

  local ok, err = pcall(fn, settings_mod)

  settings_mod.load = real_load
  settings_mod.save = real_save
  settings_mod.set = real_set
  os.remove(tmp)

  assert(ok, err)
end

T["settings load returns empty when file missing"] = function()
  with_temp_settings(function(s)
    local result = s.load()
    eq(type(result), "table")
    eq(vim.tbl_isempty(result), true)
  end)
end

T["settings save and load roundtrip"] = function()
  with_temp_settings(function(s)
    s.save({ provider = "deepl", source = "en", target = "ru" })
    local loaded = s.load()
    eq(loaded.provider, "deepl")
    eq(loaded.source, "en")
    eq(loaded.target, "ru")
  end)
end

T["settings set persists a single key"] = function()
  with_temp_settings(function(s)
    s.set("provider", "google")
    local loaded = s.load()
    eq(loaded.provider, "google")
  end)
end

T["config setup merges persisted settings"] = function()
  with_temp_settings(function(s)
    s.save({ provider = "deepl", target = "es" })
    package.loaded["babel.config"] = nil
    local config = require("babel.config")
    config.setup({})
    eq(config.options.provider, "deepl")
    eq(config.options.target, "es")
    package.loaded["babel.config"] = nil
  end)
end

T["config setup persisted overrides user opts"] = function()
  with_temp_settings(function(s)
    s.save({ provider = "deepl" })
    package.loaded["babel.config"] = nil
    local config = require("babel.config")
    config.setup({ provider = "google" })
    -- persisted wins: last interactive choice should not be killed by config
    eq(config.options.provider, "deepl")
    package.loaded["babel.config"] = nil
  end)
end

return T
