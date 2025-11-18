-- Core initialization and module loading

-- Use LOG_DEBUG if available, otherwise fallback to blight.output
-- if LOG_DEBUG then
--   LOG_DEBUG("init.lua - File is executing!")
-- else
--   blight.output("DEBUG: init.lua - File is executing!")
-- end

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
  script.load('~/.config/blightmud/swmud/utils/log_utils.lua')
  
  -- Load UI (colors must be loaded before using color constants)
  script.load('~/.config/blightmud/swmud/ui/colors.lua')
  
  -- Now safe to use color constants - display version info
  local version_text = "Unknown"
  local version_result = core.exec("cat ~/.config/blightmud/100_version.txt")
  if version_result and version_result:stdout() then
    version_text = tostring(version_result:stdout():gsub("^%s*(.-)%s*$", "%1"))
  end
  blight.output((C_BYELLOW or "") .. "SWmud Scripts Version: " .. (C_RESET or "") .. (C_BWHITE or "") .. version_text .. (C_RESET or ""))
  blight.output((C_BYELLOW or "") .. "Created by: Miko (kitsumiko@zenkoken.io)" .. (C_RESET or ""))
  blight.output()
  
  -- Set STATUS_SEP after colors are loaded
  if CONFIG then
    CONFIG.STATUS_SEP = (C_GREEN or "").." | "..(C_RESET or "")
  end
  STATUS_SEP = STATUS_SEP or ((C_GREEN or "").." | "..(C_RESET or ""))
  -- Export STATUS_SEP as global
  _G.STATUS_SEP = STATUS_SEP
  
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
  
  -- Load experience and room tracking services (after exp_table_service for dependencies)
  script.load('~/.config/blightmud/swmud/services/exp_tracker.lua')
  script.load('~/.config/blightmud/swmud/services/room_service.lua')
  
  -- Load experience and room tracking commands
  script.load('~/.config/blightmud/swmud/commands/exp_commands.lua')
  script.load('~/.config/blightmud/swmud/commands/room_commands.lua')
  
  -- Load character script if it exists
  if file_exists('~/.config/blightmud/private/020_character.lua') then
    script.load('~/.config/blightmud/private/020_character.lua')
  end
  
  -- Initial status display
  -- Note: status_draw is defined by status_renderer.lua which was just loaded
  -- Since script.load() is deferred, we need to wait a moment or check if it's available
  -- if LOG_DEBUG then
  --   LOG_DEBUG("Checking status_draw...")
  -- else
  --   blight.output("DEBUG: Checking status_draw...")
  -- end
  
  -- Try calling status_draw - it should be available since status_renderer.lua was loaded
  -- If it's not, the timer in prompt_service.lua will handle it
  if status_draw then
    -- if LOG_DEBUG then
    --   LOG_DEBUG("status_draw exists, calling it...")
    -- else
    --   blight.output("DEBUG: status_draw exists, calling it...")
    -- end
    status_draw()
    -- if LOG_DEBUG then
    --   LOG_DEBUG("status_draw called")
    -- else
    --   blight.output("DEBUG: status_draw called")
    -- end
  else
    -- if LOG_DEBUG then
    --   LOG_DEBUG("WARNING - status_draw is nil (may be deferred, timer will handle it)")
    -- else
    --   blight.output("DEBUG: WARNING - status_draw is nil (may be deferred, timer will handle it)")
    -- end
  end
  -- if LOG_DEBUG then
  --   LOG_DEBUG("script_load() completed")
  -- else
  --   blight.output("DEBUG: script_load() completed")
  -- end
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
  -- Use a timer to ensure script_load happens after reset completes
  timer.add(0.1, 1, function()
    script_load()
    blight.output()
  end)
end

-- Export for use in entry point (multiple ways to ensure it's available)
-- if LOG_DEBUG then
--   LOG_DEBUG("init.lua - About to export functions...")
--   LOG_DEBUG("init.lua - script_load type before export: " .. type(script_load))
-- else
--   blight.output("DEBUG: init.lua - About to export functions...")
--   blight.output("DEBUG: init.lua - script_load type before export: " .. type(script_load))
-- end

_G.script_load = script_load
_G.RELOAD_SCRIPTS = RELOAD_SCRIPTS
_G.set_status_default = set_status_default

-- Also export directly to global scope (not just _G)
script_load = script_load
RELOAD_SCRIPTS = RELOAD_SCRIPTS
set_status_default = set_status_default

-- if LOG_DEBUG then
--   LOG_DEBUG("init.lua - Exported script_load, type: " .. type(script_load))
--   LOG_DEBUG("init.lua - _G.script_load type: " .. type(_G.script_load))
--   LOG_DEBUG("init.lua - Global script_load type: " .. type(_G.script_load or script_load))
-- else
--   blight.output("DEBUG: init.lua - Exported script_load, type: " .. type(script_load))
--   blight.output("DEBUG: init.lua - _G.script_load type: " .. type(_G.script_load))
--   blight.output("DEBUG: init.lua - Global script_load type: " .. type(_G.script_load or script_load))
-- end

-- Auto-call script_load now that we're loaded
-- This ensures script_load runs after init.lua has fully executed
-- if LOG_DEBUG then
--   LOG_DEBUG("init.lua - Auto-calling script_load()...")
-- else
--   blight.output("DEBUG: init.lua - Auto-calling script_load()...")
-- end
script_load()
-- if LOG_DEBUG then
--   LOG_DEBUG("init.lua - script_load() completed")
-- else
--   blight.output("DEBUG: init.lua - script_load() completed")
-- end

