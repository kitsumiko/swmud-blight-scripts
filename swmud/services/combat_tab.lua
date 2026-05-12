-- Combat tab routing service
--
-- Owns all emit logic for the `combat` tab so the rest of the codebase can
-- call CombatTab.emit_* without caring about feature detection or env flags.
--
-- Routing model:
--   * Lifecycle markers (combat start / combat end) go through blight.output()
--     so they ALSO appear in main; a regex filter in 021_tabs.lua mirrors them
--     into the combat tab.
--   * Per-round summaries go through blight.output_to("combat", ...) which
--     bypasses filters and lands ONLY in the combat tab — never main.
--
-- Feature detection (checked once at load):
--   * blight.create_tab and blight.output_to must both exist (upstream build
--     lacks the tabs API).
--   * SWMUD_DISABLE_TABS=1 → all emits become no-ops, mirroring 021_tabs.lua.
--   * SWMUD_DISABLE_COMBAT_TAB_ROUND_SUMMARY=1 → only the per-round stream is
--     suppressed; markers and the filter-routed final summary still flow.

local CombatTab = {}

local tabs_api_present  = (blight ~= nil)
                          and (type(blight.create_tab) == "function")
                          and (type(blight.output_to) == "function")
local tabs_disabled_env = (os.getenv("SWMUD_DISABLE_TABS") == "1")
local round_disabled_env = (os.getenv("SWMUD_DISABLE_COMBAT_TAB_ROUND_SUMMARY") == "1")

CombatTab.enabled              = tabs_api_present and not tabs_disabled_env
CombatTab.round_summary_enabled = CombatTab.enabled and not round_disabled_env

-- Convenience colors with safe fallbacks for early-load paths where the
-- ui/colors module may not yet have populated globals.
local function YELLOW() return C_BYELLOW or "" end
local function RESET()  return C_RESET   or "" end

-- Combat started: <mob>
-- Filter-routed to tab via 021_tabs.lua "^Combat started:" regex.
function CombatTab.emit_start(mob)
  if not CombatTab.enabled then return end
  if mob == nil or mob == "" then return end
  blight.output(YELLOW() .. "Combat started: " .. tostring(mob) .. RESET())
end

-- Combat ended: <mob> in Nr — D dmg
-- Filter-routed to tab via 021_tabs.lua "^Combat ended:" regex.
function CombatTab.emit_end(mob, rounds, damage)
  if not CombatTab.enabled then return end
  if mob == nil or mob == "" then return end
  local r = tonumber(rounds) or 0
  local d = tonumber(damage) or 0
  blight.output(YELLOW() .. "Combat ended: " .. tostring(mob)
                .. " in " .. tostring(r) .. "r"
                .. " \xe2\x80\x94 " .. tostring(math.floor(d)) .. " dmg"
                .. RESET())
end

-- Two-line per-round summary. Tab-only via blight.output_to.
-- Caller builds the stats table; we just format it.
--
-- Expected fields on `stats`:
--   round_num, round_damage, best_round, cum_damage, dpr,
--   hits, misses,
--   mob_name, mob_pct, mob_health, mob_total_health,
--   player_hp, player_max_hp, player_hp_delta
function CombatTab.emit_round_end(stats)
  if not CombatTab.round_summary_enabled then return end
  if stats == nil then return end

  local round_num   = tonumber(stats.round_num) or 0
  local rd          = math.floor(tonumber(stats.round_damage) or 0)
  local best        = math.floor(tonumber(stats.best_round) or 0)
  local cum         = math.floor(tonumber(stats.cum_damage) or 0)
  local dpr         = tonumber(stats.dpr) or 0
  local hits        = tonumber(stats.hits) or 0
  local misses      = tonumber(stats.misses) or 0

  local mob_name    = tostring(stats.mob_name or "?")
  local mob_pct_raw = tonumber(stats.mob_pct) or 0
  local mob_pct     = math.floor(mob_pct_raw * 100 + 0.5)
  local mob_hp      = math.floor(tonumber(stats.mob_health) or 0)
  local mob_total   = math.floor(tonumber(stats.mob_total_health) or 0)

  local pl_hp       = math.floor(tonumber(stats.player_hp) or 0)
  local pl_max      = math.floor(tonumber(stats.player_max_hp) or 0)
  local pl_delta    = math.floor(tonumber(stats.player_hp_delta) or 0)

  -- Line 1: round bookkeeping
  local l1 = YELLOW() .. "[r" .. tostring(round_num) .. "]" .. RESET()
             .. "  " .. tostring(rd) .. " dmg"
             .. "  best " .. tostring(best)
             .. "  cum " .. tostring(cum)
             .. "  DPR " .. string.format("%.1f", dpr)
             .. "  hits " .. tostring(hits)
             .. " miss " .. tostring(misses)

  -- Line 2: indented mob/player state
  local mob_state
  if mob_total > 0 then
    mob_state = "mob: " .. mob_name .. " (~" .. tostring(mob_pct) .. "%, est "
                .. tostring(mob_hp) .. "/" .. tostring(mob_total) .. ")"
  else
    mob_state = "mob: " .. mob_name
  end

  local player_state
  if pl_max > 0 then
    player_state = "you: " .. tostring(pl_hp) .. "/" .. tostring(pl_max) .. " hp"
  else
    player_state = "you: " .. tostring(pl_hp) .. " hp"
  end
  local delta_sign = (pl_delta > 0 and "+") or ""
  player_state = player_state .. " (" .. delta_sign .. tostring(pl_delta) .. " this round)"

  local l2 = "      " .. mob_state .. "  " .. player_state

  blight.output_to("combat", l1)
  blight.output_to("combat", l2)
end

-- Export
_G.CombatTab = CombatTab

return CombatTab
