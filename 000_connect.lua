SESSION_INFO = {}

local function primary_setup()
  settings.set("logging_enabled", 1)
  settings.set("mouse_enabled", 1)
  mud.connect("swmud.org", 7777, true, false)
  SESSION_INFO["session_start"] = os.time()
end

function RECONNECT()
  PROMPT_INFO.last_autosave = os.time()
  SESSION_INFO["session_start"] = os.time()
  mud.connect("swmud.org", 6666)
end

primary_setup()

function to_boolean(str)
  local bool = false
  if str == "true" then
      bool = true
  end
  return bool
end

function script_load()
  -- start all of the settings
  blight.output()
  blight.output(C_BYELLOW .. "SWmud Scripts Version: " .. C_RESET .. C_BWHITE .. tostring(core.exec("cat ~/.config/blightmud/100_version.txt"):stdout():gsub("^%s*(.-)%s*$", "%1")) .. C_RESET)
  blight.output(C_BYELLOW .. "Created by: Miko (kishimiko@gmail.com)" .. C_RESET)
  blight.output()
  script.load('~/.config/blightmud/swmud/001_state_classes.lua')
  script.load('~/.config/blightmud/swmud/002_prompt.lua')
  script.load('~/.config/blightmud/swmud/003_nicknames.lua')
  script.load('~/.config/blightmud/swmud/004_aliases.lua')
  script.load('~/.config/blightmud/swmud/005_colors.lua')
  script.load('~/.config/blightmud/swmud/006_skills.lua')
  script.load('~/.config/blightmud/swmud/007_dpr.lua')
  script.load('~/.config/blightmud/swmud/008_room.lua')
  script.load('~/.config/blightmud/swmud/010_utilities.lua')
  -- script.load('~/.config/blightmud/swmud/011_data_readers.lua')
  if not to_boolean(tostring(core.exec("ls ~/.config/blightmud/private/020_character.lua"):stdout():gsub("^%s*(.-)%s*$", "%1")=="")) then
    script.load('~/.config/blightmud/private/020_character.lua')
  end
end

script_load()

function RELOAD_SCRIPTS()
  set_status_default()
  script.reset()
  trigger.clear()
  alias.clear()
  script_load()
  blight.output()
end