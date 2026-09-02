-- Trigger definitions

-- healing capture trigger
trigger.add("^hp: ([^ ]*)/([^ ]*) \\(([^ ]*)\\)([ ]*)dr: ([^ ]* ?[^ ]*? ?[^ ]*?)$", {}, function (m)
  PROMPT_INFO.hp = m[2]
  PROMPT_INFO.hp_max = m[3]
  PROMPT_INFO.drug = m[6]
end)

-- damage capture trigger
trigger.add("^hp: ([^ ]*)/([^ ]*) \\(([^ ]*)\\)([ ]*)", {}, function (m)
  PROMPT_INFO.hp = m[2]
  PROMPT_INFO.hp_max = m[3]
end)

-- Force deflection (You feel the Force guide you, and you maneuver...)
if COMBAT_EXTRAS then
  trigger.add("^You feel the Force guide you", {}, function (m)
    COMBAT_EXTRAS.force_deflections_combat = COMBAT_EXTRAS.force_deflections_combat + 1
    COMBAT_EXTRAS.force_deflections_session = COMBAT_EXTRAS.force_deflections_session + 1
  end)
end

-- autosaving timestamp
trigger.add("^Autosaving.", {gag = 1,}, function (m)
  blight.output(C_BYELLOW .. "Autosaving - " .. os.date("%c") .. C_RESET)
  PROMPT_INFO.last_autosave = os.time()
end)

-- uptime capture trigger
trigger.add("^Next scheduled reboot: (.*) [()](.*) EST[)]$", {}, function (m)
  store.session_write("uptime_data", m[3])
  SETUP_STATE.uptime_set = 0
end)

-- reboot capture trigger
trigger.add("^SWmud has been up for:([ ]*)([0-9]*)d([ ]*)([0-9]*)h([ ]*)([0-9]*)m([ ]*)([0-9]*)s. ", {}, function (m)
  local boot_time_delta = tonumber(m[3])*24*60*60 + tonumber(m[5])*60*60 + tonumber(m[7])*60 + tonumber(m[9])
  local boot_time = os.time() - boot_time_delta
  store.session_write("reboot_data", boot_time)
  SETUP_STATE.reboot_set = 1
end)

-- expcheck triggers
--
-- Besides recording the exp target for each guild in EXP_TABLE, these also
-- update LEVEL_TABLE so guild levels stay current without needing a `score`.
--   "You need N more experience to advance slicer to 48."  -> Slicer = 47
--   "You can advance jedi to 31."                           -> Jedi   = 30
--   "You can advance guild jedi to level 31 now."           -> Jedi   = 30
--   "You are level 19 scientist."                           -> Scientist = 19
-- High Mortal is not reported by expcheck, so it still comes from `score`.
local function set_guild_level_from_expcheck(guild_raw, level)
  local guild = (TITLE_CASE(TRIM_STRING(guild_raw)))
  level = tonumber(level)
  if not guild or not level or not LEVEL_TABLE then
    return
  end
  local guilds_set = SET(PROMPT_INFO.guilds)
  if not guilds_set[guild] then
    return
  end
  if level > 0 then
    LEVEL_TABLE[guild] = level
  elseif SET_CONTAINS(LEVEL_TABLE, guild) then
    REMOVE_FROM_SET(LEVEL_TABLE, guild)
  end
end

trigger.add("^You need ([0-9]*) more experience to advance ([a-zA-Z]* ?[a-zA-Z]*) to ([0-9]*)\\.", {}, function (m)
  EXP_TABLE["x_snapshot"] = PROMPT_INFO.exp
  EXP_TABLE[TITLE_CASE(m[3])] = PROMPT_INFO.exp + tonumber(m[2])
  set_guild_level_from_expcheck(m[3], tonumber(m[4]) - 1)
end)

trigger.add("^You can advance guild ([a-zA-Z]* ?[a-zA-Z]*) to level ([0-9]*) now\\.", {}, function (m)
  EXP_TABLE["x_snapshot"] = PROMPT_INFO.exp
  EXP_TABLE[TITLE_CASE(m[2])] = "adv"
  set_guild_level_from_expcheck(m[2], tonumber(m[3]) - 1)
end)

trigger.add("^You can advance ([a-zA-Z]* ?[a-zA-Z]*) to ([0-9]*)\\.", {}, function (m)
  EXP_TABLE["x_snapshot"] = PROMPT_INFO.exp
  EXP_TABLE[TITLE_CASE(m[2])] = "adv"
  set_guild_level_from_expcheck(m[2], tonumber(m[3]) - 1)
end)

trigger.add("^You are level ([0-9]*) ([a-zA-Z]* ?[a-zA-Z]*)\\.", {}, function (m)
  EXP_TABLE["x_snapshot"] = PROMPT_INFO.exp
  EXP_TABLE[TITLE_CASE(m[3])] = "max"
  set_guild_level_from_expcheck(m[3], m[2])
end)

trigger.add("^You must advance (.*) before advancing ([a-zA-Z]* ?[a-zA-Z]*)\\. \\(([0-9]*) more experience to advance both\\)\\.", {}, function (m)
  EXP_TABLE["x_snapshot"] = PROMPT_INFO.exp
  EXP_TABLE[TITLE_CASE(m[3])] = PROMPT_INFO.exp + tonumber(m[4])
end)

-- reconnect triggers
trigger.add("^/reconnect$", {}, function (m)
  RECONNECT()
end)

-- Note: /reload is handled in prompt_service.lua input_loop, not here
-- This is because triggers match output, not input commands

-- bsense trigger
trigger.add("^Your senses tell you that:$", {}, function (m)
  PROMPT_INFO.bsense_catch = 1
  TARGET_INFO.unrec_damage = 0
end)

-- blook trigger
trigger.add("^You look over the (.*)", {}, function (m)
  PROMPT_INFO.blook_catch = 1
  TARGET_INFO.unrec_damage = 0
end)
trigger.add("^(.*) is carrying:$", {}, function (m)
  PROMPT_INFO.blook_catch = 0
end)

