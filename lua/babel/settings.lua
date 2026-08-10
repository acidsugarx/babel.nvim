-- lua/babel/settings.lua
--- Persistent settings storage for babel.nvim.
--- Stores non-sensitive config (provider, source, target, formality) in a JSON file.
--- API keys are NEVER persisted — they come from env vars or setup() only.
local M = {}

local path = vim.fn.stdpath("data") .. "/babel.json"

--- List of config keys that are safe to persist (no secrets).
local PERSISTED_KEYS = {
  "provider",
  "source",
  "target",
}

---Get the settings file path.
---@return string
function M.get_path()
  return path
end

---Load persisted settings from disk.
---Returns an empty table if the file does not exist or is invalid.
---@return table
function M.load()
  local file = io.open(path, "r")
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

  -- Filter: only keep whitelisted keys (never trust arbitrary data)
  local result = {}
  for _, key in ipairs(PERSISTED_KEYS) do
    if data[key] ~= nil then
      result[key] = data[key]
    end
  end

  return result
end

---Save a subset of config options to disk.
---Only whitelisted keys are written; secrets are never persisted.
---@param opts table Config options (e.g. config.options)
function M.save(opts)
  local data = {}
  for _, key in ipairs(PERSISTED_KEYS) do
    if opts[key] ~= nil then
      data[key] = opts[key]
    end
  end

  local json = vim.json.encode(data)

  -- Ensure parent directory exists
  local dir = vim.fn.fnamemodify(path, ":h")
  vim.fn.mkdir(dir, "p")

  local file, err = io.open(path, "w")
  if not file then
    vim.notify("Babel: failed to save settings: " .. (err or "unknown"), vim.log.levels.WARN)
    return
  end
  file:write(json)
  file:close()
end

---Update a single key and persist immediately.
---@param key string One of PERSISTED_KEYS
---@param value string|number|boolean|nil
function M.set(key, value)
  local current = M.load()
  current[key] = value
  M.save(current)
end

return M
