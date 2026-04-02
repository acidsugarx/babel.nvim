-- lua/babel/languages.lua
--- Built-in language list for picker
--- Keys are ISO 639-1 codes matching provider API expectations
---@type table<string, string>
local M = {
  auto = "Auto-detect",
  en = "English",
  ru = "Russian",
  de = "German",
  fr = "French",
  es = "Spanish",
  ja = "Japanese",
  zh = "Chinese",
  ko = "Korean",
  pt = "Portuguese",
  it = "Italian",
  ar = "Arabic",
  hi = "Hindi",
  tr = "Turkish",
  pl = "Polish",
  nl = "Dutch",
  sv = "Swedish",
  uk = "Ukrainian",
}

---Get language list as sorted {code, label} pairs
---@param override? table<string, string> User override table
---@return table<{code: string, label: string}>
function M.get_list(override)
  local langs = override or M
  local result = {}
  for code, label in pairs(langs) do
    if type(label) == "string" then
      table.insert(result, { code = code, label = label })
    end
  end
  table.sort(result, function(a, b)
    if a.code == "auto" then
      return true
    end
    if b.code == "auto" then
      return false
    end
    return a.label < b.label
  end)
  return result
end

return M
