-- Simple module loader for Lua
-- Provides require() functionality for loading modules

local module_cache = {}
local base_path = "~/.config/blightmud/swmud/"

local function normalize_path(path)
  -- Convert module path to file path
  -- e.g., "swmud/utils/string_utils" -> "swmud/utils/string_utils.lua"
  if not path:match("%.lua$") then
    path = path .. ".lua"
  end
  return path
end

function require(module_path)
  -- Check cache first
  if module_cache[module_path] then
    return module_cache[module_path]
  end
  
  -- Load the module
  local file_path = normalize_path(module_path)
  local success, result = pcall(function()
    local chunk, err = loadfile(file_path)
    if not chunk then
      error("Failed to load module " .. module_path .. ": " .. tostring(err))
    end
    return chunk()
  end)
  
  if not success then
    error("Error loading module " .. module_path .. ": " .. tostring(result))
  end
  
  -- Cache and return
  module_cache[module_path] = result
  return result
end

-- Make require available globally
_G.require = require

