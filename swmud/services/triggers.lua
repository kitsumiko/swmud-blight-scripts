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
trigger.add("^You need ([0-9]*) more experience to advance ([a-zA-Z]* ?[a-zA-Z]*) to ([0-9]*)\\.", {}, function (m)
  EXP_TABLE["x_snapshot"] = PROMPT_INFO.exp
  EXP_TABLE[TITLE_CASE(m[3])] = PROMPT_INFO.exp + tonumber(m[2])
end)

trigger.add("^You can advance guild ([a-zA-Z]* ?[a-zA-Z]*) to level ([0-9]*) now\\.", {}, function (m)
  EXP_TABLE["x_snapshot"] = PROMPT_INFO.exp
  EXP_TABLE[TITLE_CASE(m[3])] = "adv"
end)

trigger.add("^You can advance ([a-zA-Z]* ?[a-zA-Z]*) to ([0-9]*)\\.", {}, function (m)
  EXP_TABLE["x_snapshot"] = PROMPT_INFO.exp
  EXP_TABLE[TITLE_CASE(m[2])] = "adv"
end)

trigger.add("^You are level ([0-9]*) ([a-zA-Z]* ?[a-zA-Z]*)\\.", {}, function (m)
  EXP_TABLE["x_snapshot"] = PROMPT_INFO.exp
  EXP_TABLE[TITLE_CASE(m[3])] = "max"
end)

trigger.add("^You must advance (.*) before advancing ([a-zA-Z]* ?[a-zA-Z]*)\\. \\(([0-9]*) more experience to advance both\\)\\.", {}, function (m)
  EXP_TABLE["x_snapshot"] = PROMPT_INFO.exp
  EXP_TABLE[TITLE_CASE(m[3])] = PROMPT_INFO.exp + tonumber(m[4])
end)

-- reconnect triggers
trigger.add("^/reconnect$", {}, function (m)
  RECONNECT()
end)

-- reload scripts trigger
trigger.add("^/reload$", {}, function (m)
  blight.output((C_BYELLOW or "") .. "Reloading scripts..." .. (C_RESET or ""))
  if RELOAD_SCRIPTS then
    RELOAD_SCRIPTS()
    blight.output((C_BGREEN or "") .. "Scripts reloaded successfully!" .. (C_RESET or ""))
  else
    blight.output((C_BRED or "") .. "ERROR: RELOAD_SCRIPTS function not available!" .. (C_RESET or ""))
  end
end)

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

