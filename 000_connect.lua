-- Entry point for SWMud scripts
-- This file is auto-loaded first by blightmud (due to 000_ prefix)

local function primary_setup()
  settings.set("logging_enabled", 1)
  settings.set("mouse_enabled", 1)
  mud.connect("swmud.org", 7777, true, false)
end

-- Initialize connection
primary_setup()

-- Load core initialization module which handles all script loading
script.load('~/.config/blightmud/swmud/core/init.lua')

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

-- Call script_load from init module
if script_load then
  script_load()
end