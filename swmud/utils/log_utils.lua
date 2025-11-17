-- Logging utility functions
-- Provides file-based logging for debugging

local LogUtils = {}

-- Log file path (can be configured via environment variable or default)
-- Default: ~/.local/share/blightmud/logs/syslogs/swmud_debug.log
-- Can be overridden by setting SWMUD_LOG_PATH environment variable
local log_path = os.getenv("SWMUD_LOG_PATH")
if not log_path then
  local log_dir = os.getenv("HOME") .. "/.local/share/blightmud/logs/syslogs"
  -- Create directory if it doesn't exist
  os.execute("mkdir -p " .. log_dir)
  log_path = log_dir .. "/swmud_debug.log"
end
LogUtils.log_file = log_path

function LogUtils.write(message)
  local file = io.open(LogUtils.log_file, "a")
  if file then
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    file:write("[" .. timestamp .. "] " .. message .. "\n")
    file:close()
  end
end

function LogUtils.write_debug(message)
  LogUtils.write("DEBUG: " .. message)
  -- Also output to blightmud console
  blight.output("DEBUG: " .. message)
end

function LogUtils.write_error(message)
  LogUtils.write("ERROR: " .. message)
  -- Also output to blightmud console
  blight.output("ERROR: " .. message)
end

function LogUtils.clear()
  local file = io.open(LogUtils.log_file, "w")
  if file then
    file:write("")
    file:close()
  end
end

-- Export as globals for easy access
LOG_WRITE = LogUtils.write
LOG_DEBUG = LogUtils.write_debug
LOG_ERROR = LogUtils.write_error
LOG_CLEAR = LogUtils.clear

return LogUtils

