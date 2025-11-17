-- Core initialization and module loading

local function to_boolean(str)
  local bool = false
  if str == "true" then
    bool = true
  end
  return bool
end

local function file_exists(path)
  local result = core.exec("ls " .. path)
  return not to_boolean(tostring(result:stdout():gsub("^%s*(.-)%s*$", "%1") == ""))
end

function script_load()
  -- Load all modules in order
  blight.output()
  
  -- Load core modules first
  script.load('~/.config/blightmud/swmud/core/module_loader.lua')
  script.load('~/.config/blightmud/swmud/core/config.lua')
  
  -- Load utilities
  script.load('~/.config/blightmud/swmud/utils/table_utils.lua')
  script.load('~/.config/blightmud/swmud/utils/string_utils.lua')
  script.load('~/.config/blightmud/swmud/utils/math_utils.lua')
  script.load('~/.config/blightmud/swmud/utils/time_utils.lua')
  
  -- Load UI (colors must be loaded before using color constants)
  script.load('~/.config/blightmud/swmud/ui/colors.lua')
  
  -- Now safe to use color constants - display version info
  local version_text = "Unknown"
  local version_result = core.exec("cat ~/.config/blightmud/100_version.txt")
  if version_result and version_result:stdout() then
    version_text = tostring(version_result:stdout():gsub("^%s*(.-)%s*$", "%1"))
  end
  blight.output((C_BYELLOW or "") .. "SWmud Scripts Version: " .. (C_RESET or "") .. (C_BWHITE or "") .. version_text .. (C_RESET or ""))
  blight.output((C_BYELLOW or "") .. "Created by: Miko (kishimiko@gmail.com)" .. (C_RESET or ""))
  blight.output()
  
  -- Set STATUS_SEP after colors are loaded
  if CONFIG then
    CONFIG.STATUS_SEP = (C_GREEN or "").." | "..(C_RESET or "")
  end
  STATUS_SEP = STATUS_SEP or ((C_GREEN or "").." | "..(C_RESET or ""))
  
  -- Load state (must be after utilities and colors)
  script.load('~/.config/blightmud/swmud/core/state.lua')
  
  -- Load commands
  script.load('~/.config/blightmud/swmud/commands/alias_factory.lua')
  script.load('~/.config/blightmud/swmud/commands/nicknames.lua')
  script.load('~/.config/blightmud/swmud/commands/aliases.lua')
  
  -- Load skill tracker (defines DELAYS_REMAP and skill functions)
  script.load('~/.config/blightmud/swmud/services/skill_tracker.lua')
  script.load('~/.config/blightmud/swmud/services/skill_definitions.lua')
  
  -- Load combat models (defines tier_lookup, BSENSE data, target functions)
  script.load('~/.config/blightmud/swmud/models/combat.lua')
  
  -- Load DPR calculator (defines update_total_damage, update_target_status, dpr_primary_loop, get_add_space, etc.)
  script.load('~/.config/blightmud/swmud/services/dpr_calculator.lua')
  
  -- Load damage parser (sets up damage triggers)
  script.load('~/.config/blightmud/swmud/parsers/damage_parser.lua')
  
  -- Load parsers (depend on skills for DELAYS_REMAP)
  script.load('~/.config/blightmud/swmud/parsers/prompt_parser.lua')
  script.load('~/.config/blightmud/swmud/parsers/score_parser.lua')
  script.load('~/.config/blightmud/swmud/parsers/delays_parser.lua')
  script.load('~/.config/blightmud/swmud/parsers/room_parser.lua')
  
  -- Load services
  script.load('~/.config/blightmud/swmud/services/status_updater.lua')
  script.load('~/.config/blightmud/swmud/services/triggers.lua')
  
  -- Load UI
  script.load('~/.config/blightmud/swmud/ui/status_renderer.lua')
  
  -- Load main prompt service (sets up listeners, depends on parsers and DPR)
  script.load('~/.config/blightmud/swmud/services/prompt_service.lua')
  
  -- Load data loader
  script.load('~/.config/blightmud/swmud/services/data_loader.lua')
  
  -- Load exp table service and load the exp table
  script.load('~/.config/blightmud/swmud/services/exp_table_service.lua')
  if ExpTableService then
    EXP_TABLE_DATA = ExpTableService.load_exp_table('~/.config/blightmud/swmud/data/100_data_exp.txt')
  end
  
  -- Load character script if it exists
  if file_exists('~/.config/blightmud/private/020_character.lua') then
    script.load('~/.config/blightmud/private/020_character.lua')
  end
  
  -- Initial status display
  blight.output("DEBUG: Checking status_draw...")
  if status_draw then
    blight.output("DEBUG: status_draw exists, calling it...")
    status_draw()
    blight.output("DEBUG: status_draw called")
  else
    blight.output("DEBUG: ERROR - status_draw is nil!")
  end
  blight.output("DEBUG: script_load() completed")
end

function set_status_default()
  blight.status_height(2)
  blight.status_line(0, "")
end

function RELOAD_SCRIPTS()
  set_status_default()
  script.reset()
  trigger.clear()
  alias.clear()
  script_load()
  blight.output()
end

-- Export for use in entry point (multiple ways to ensure it's available)
blight.output("DEBUG: init.lua - About to export functions...")
blight.output("DEBUG: init.lua - script_load type before export: " .. type(script_load))

_G.script_load = script_load
_G.RELOAD_SCRIPTS = RELOAD_SCRIPTS
_G.set_status_default = set_status_default

-- Also export directly to global scope (not just _G)
script_load = script_load
RELOAD_SCRIPTS = RELOAD_SCRIPTS
set_status_default = set_status_default

blight.output("DEBUG: init.lua - Exported script_load, type: " .. type(script_load))
blight.output("DEBUG: init.lua - _G.script_load type: " .. type(_G.script_load))
blight.output("DEBUG: init.lua - Global script_load type: " .. type(_G.script_load or script_load))

