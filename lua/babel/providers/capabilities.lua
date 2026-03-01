local M = {}

local CAPABILITIES = {
  google = {
    supports_formality = false,
    supports_auto_source = true,
    requires_api_key = false,
    supports_fallback = true,
    supports_cache = true,
  },
  deepl = {
    supports_formality = true,
    supports_auto_source = true,
    requires_api_key = true,
    supports_fallback = true,
    supports_cache = true,
  },
}

---Get capability table for one provider or all providers
---@param provider? string
---@return table|nil
function M.get(provider)
  if provider ~= nil then
    local capabilities = CAPABILITIES[provider]
    if not capabilities then
      return nil
    end

    return vim.deepcopy(capabilities)
  end

  return vim.deepcopy(CAPABILITIES)
end

return M
