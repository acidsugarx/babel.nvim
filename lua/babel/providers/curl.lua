local M = {}

local DEFAULT_CONNECT_TIMEOUT = 5
local DEFAULT_REQUEST_TIMEOUT = 15

local function trim(str)
  return (str:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function join_chunks(data)
  if type(data) ~= "table" then
    return ""
  end

  local chunks = {}
  for _, chunk in ipairs(data) do
    if chunk and chunk ~= "" then
      table.insert(chunks, chunk)
    end
  end

  return trim(table.concat(chunks, "\n"))
end

---Build curl timeout arguments
---@param opts? { connect_timeout?: number, request_timeout?: number }
---@return string[]
---@return number
---@return number
function M.timeout_args(opts)
  opts = opts or {}

  local connect_timeout = tonumber(opts.connect_timeout) or DEFAULT_CONNECT_TIMEOUT
  local request_timeout = tonumber(opts.request_timeout) or DEFAULT_REQUEST_TIMEOUT

  if connect_timeout <= 0 then
    connect_timeout = DEFAULT_CONNECT_TIMEOUT
  end
  if request_timeout <= 0 then
    request_timeout = DEFAULT_REQUEST_TIMEOUT
  end

  return {
    "--connect-timeout",
    tostring(connect_timeout),
    "--max-time",
    tostring(request_timeout),
  },
    connect_timeout,
    request_timeout
end

---Run curl command and normalize transport errors
---@param cmd string[]
---@param opts? { provider?: string, timeout?: number }
---@param callback fun(stdout: string|nil, err: table|nil)
function M.run(cmd, opts, callback)
  opts = opts or {}
  local provider = opts.provider or "provider"
  local timeout = tonumber(opts.request_timeout or opts.timeout) or DEFAULT_REQUEST_TIMEOUT

  local stdout_data = {}
  local stderr_data = {}
  local finished = false

  local function finish(stdout, err)
    if finished then
      return
    end
    finished = true
    callback(stdout, err)
  end

  local job_id = vim.fn.jobstart(cmd, {
    stdout_buffered = true,
    stderr_buffered = true,
    on_stdout = function(_, data)
      if type(data) == "table" then
        vim.list_extend(stdout_data, data)
      end
    end,
    on_stderr = function(_, data)
      if type(data) == "table" then
        vim.list_extend(stderr_data, data)
      end
    end,
    on_exit = function(_, code)
      local stdout = join_chunks(stdout_data)
      local stderr = join_chunks(stderr_data)

      if code ~= 0 then
        if code == 28 then
          finish(nil, {
            code = "timeout",
            provider = provider,
            exit_code = code,
            message = string.format("request timed out after %ss", timeout),
          })
          return
        end

        local message = string.format("request failed (curl exit %d)", code)
        if stderr ~= "" then
          message = message .. ": " .. stderr
        end

        finish(nil, {
          code = "curl_exit",
          provider = provider,
          exit_code = code,
          stderr = stderr,
          message = message,
        })
        return
      end

      finish(stdout, nil)
    end,
  })

  if job_id <= 0 then
    finish(nil, {
      code = "spawn_failed",
      provider = provider,
      message = "failed to start curl process",
    })
  end
end

return M
