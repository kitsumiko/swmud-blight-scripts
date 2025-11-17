-- Entry point for SWMud scripts
-- This file is auto-loaded first by blightmud (due to 000_ prefix)

local function primary_setup()
  settings.set("logging_enabled", 1)
  settings.set("mouse_enabled", 1)
  mud.connect("swmud.org", 7777, true, false)
end

-- Initialize connection
primary_setup()

blight.output("DEBUG: 000_connect.lua - Loading init.lua...")
-- Load core initialization module which handles all script loading
script.load('~/.config/blightmud/swmud/core/init.lua')

-- Wait a moment for the script to execute (if needed)
-- Then check for script_load in multiple ways
blight.output("DEBUG: 000_connect.lua - Checking for script_load...")
blight.output("DEBUG: 000_connect.lua - _G.script_load type: " .. type(_G.script_load))
blight.output("DEBUG: 000_connect.lua - script_load type: " .. type(script_load))

-- Try to get script_load from _G or global scope
local load_func = _G.script_load or script_load

if not load_func then
  -- If still not available, try loading the module and calling it directly
  blight.output("DEBUG: 000_connect.lua - script_load not found, trying alternative approach...")
  -- Re-define script_load here as a fallback that loads everything
  load_func = function()
    blight.output("DEBUG: Fallback script_load called")
    -- This will be replaced by the real one from init.lua if it loads
    if _G.script_load then
      return _G.script_load()
    end
    blight.output("ERROR: Cannot load scripts - script_load not available")
  end
end

-- Initialize SESSION_INFO (will be set by state module, but set it here for early access)
SESSION_INFO = SESSION_INFO or {session_start = os.time()}

-- RECONNECT function (will be available after modules load, but define here for early access)
function RECONNECT()
  if PROMPT_INFO then
    PROMPT_INFO.last_autosave = os.time()
  end
  if SESSION_INFO then
    SESSION_INFO["session_start"] = os.time()
  end
  mud.connect("swmud.org", 6666)
end

-- Call script_load
blight.output("DEBUG: 000_connect.lua - Calling load_func...")
if load_func then
  load_func()
  blight.output("DEBUG: 000_connect.lua - load_func() completed")
else
  blight.output("DEBUG: 000_connect.lua - ERROR: load_func is nil!")
end