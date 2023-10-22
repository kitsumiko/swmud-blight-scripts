-- calculate the character_levels from score
local function update_character_status()
  if SET_CONTAINS(LEVEL_TABLE, CHAR_DATA.prime_guild) then
    local out_string = CHAR_DATA.prime_guild.." ("..tostring(LEVEL_TABLE[CHAR_DATA.prime_guild])..") "
    local score_hint_append = 0
    if SET_CONTAINS(EXP_TABLE, CHAR_DATA.prime_guild) then
      if type(EXP_TABLE[CHAR_DATA.prime_guild])=="number" then
        local new_exp = EXP_TABLE[CHAR_DATA.prime_guild] - PROMPT_INFO.exp
        local new_exp_ratio = PROMPT_INFO.exp / EXP_TABLE[CHAR_DATA.prime_guild]
        out_string = out_string .. "(" .. GET_COLOR(new_exp_ratio) .. tostring(new_exp) .. C_RESET .. ") / "
      else
        out_string = out_string .. "(" .. C_BWHITE .. EXP_TABLE[CHAR_DATA.prime_guild] .. C_RESET .. ") / "
      end
    else
      score_hint_append = 1
    end
    local saved_val = 0
    local guild_level = 0
    local second_guild = "None"
    for k,v in pairs(LEVEL_TABLE) do
      if k~=CHAR_DATA.prime_guild and k~="High Mortal" then
        if tonumber(v) >= saved_val then
          second_guild = k
          guild_level = v
          saved_val = v
        end
      end
    end
    out_string = out_string .. second_guild .." ("..tostring(guild_level)..") "
    if SET_CONTAINS(EXP_TABLE, second_guild) then
      if type(EXP_TABLE[second_guild])=="number" then
        local new_exp = EXP_TABLE[second_guild] - PROMPT_INFO.exp
        local new_exp_ratio = PROMPT_INFO.exp / EXP_TABLE[second_guild]
        out_string = out_string .. "(" .. GET_COLOR(new_exp_ratio) .. tostring(new_exp) .. C_RESET .. ") / "
      else
        out_string = out_string .. "(" .. C_BWHITE .. EXP_TABLE[second_guild] .. C_RESET .. ") / "
      end
    end
    local saved_val = 0
    local guild_level = 0
    local third_guild = "None"
    for k,v in pairs(LEVEL_TABLE) do
      if k~=CHAR_DATA.prime_guild and k~=second_guild and k~="High Mortal" then
        if tonumber(v) >= saved_val then
          third_guild = k
          guild_level = v
          saved_val = v
        end
      end
    end
    out_string = out_string .. third_guild .." ("..tostring(guild_level)..") "
    if SET_CONTAINS(EXP_TABLE, third_guild) then
      if type(EXP_TABLE[third_guild])=="number" then
        local new_exp = EXP_TABLE[third_guild] - PROMPT_INFO.exp
        local new_exp_ratio = PROMPT_INFO.exp / EXP_TABLE[third_guild]
        out_string = out_string .. "(" .. GET_COLOR(new_exp_ratio) .. tostring(new_exp) .. C_RESET .. ")"
      else
        out_string = out_string .. "(" .. C_BWHITE .. EXP_TABLE[third_guild] .. C_RESET .. ")"
      end
    else
      out_string = out_string .. "(" .. C_WHITE .. "max" .. C_RESET .. ")"
    end
    if score_hint_append == 1 then
      out_string = out_string .. " "..C_BYELLOW.."<expcheck>"..C_RESET
    end
    CHAR_DATA.character_levels = out_string
  end
end

local function update_skill_status()
  local out_str = "De: "
  local temp_add = ""
  if TABLE_LENGTH(SKILL_TABLE_WIN)>0 then
    for k,v in pairs(SKILL_TABLE_WIN) do
      if v ~= nil then
        local total_time = 4
        local max_time = 4
        if SET_CONTAINS(SKILL_DELAY_TABLE_WIN, k) then
          total_time = SKILL_DELAY_TABLE_WIN[k]
          max_time = SKILL_DELAY_TABLE_WIN[k]
        end
        if SET_CONTAINS(SKILL_DELAY_TABLE_SHIM, k) then
          total_time = SKILL_DELAY_TABLE_SHIM[k]
          max_time = math.max(SKILL_DELAY_TABLE_WIN[k], SKILL_DELAY_TABLE_SHIM[k])
        end
        local rep_time = math.floor(total_time - os.difftime(os.time(), v))
        -- blight.output(tostring(rep_time))
        if rep_time <= 0 then
          rep_time = total_time + math.floor(max_time - os.difftime(os.time(), v))
        end
        -- blight.output(tostring(rep_time))
        -- blight.output(tostring(rep_time) .. " " .. tostring(v) .. " " .. tostring(os.difftime(os.time(), v)))
        if rep_time > 0 then
          temp_add = temp_add .. k .. " (".. GET_COLOR(total_time / max_time) .. tostring(rep_time) .. C_RESET..") "
        else
          SKILL_TABLE_WIN[k] = nil
        end
      end
    end
  end
  if TABLE_LENGTH(SKILL_TABLE_FAIL)>0 then
    for k,v in pairs(SKILL_TABLE_FAIL) do
      if v ~= nil then
        local total_time = SKILL_DELAY_TABLE_FAIL[k]
        local time_check = math.floor(total_time - os.difftime(os.time(), v))
        if time_check > 0 then
          temp_add = temp_add .. k .. " (".. GET_COLOR(1 - time_check / total_time) .. tostring(time_check) .. C_RESET..") "
        else
          SKILL_TABLE_FAIL[k] = nil
        end
      end
    end

  end
  if temp_add == "" then
    temp_add =  C_BYELLOW .. "<delays>" .. C_RESET
  end
  out_str = out_str .. temp_add
  CHAR_DATA.skill_delays = out_str
end

local function update_durable_skill_status()
  local out_str = "S: "
  local caught_status = 0
  if TABLE_LENGTH(SKILL_STATUS_TABLE)>0 then
    for sk_name,v in pairs(SKILL_STATUS_TABLE) do
      if v == 1 then
        caught_status = 1
        local sk_ttl = "??"
        local sk_color = GET_COLOR(0)
        local base_len = nil
        if SKILL_STATUS_LEN[sk_name] ~= nil then
          base_len = SKILL_STATUS_LEN[sk_name]
        end
        if SKILL_STATUS_EST[sk_name] ~= nil then
          base_len = SKILL_STATUS_EST[sk_name]
        end
        if base_len ~= nil then
          sk_ttl = tostring(base_len - math.floor(os.difftime(os.time(), SKILL_STATUS_START[sk_name])))
          sk_color = GET_COLOR(1 - tonumber(sk_ttl) / base_len)
        end
        if sk_color == nil then
          sk_color = GET_COLOR(0)
        end
        out_str = out_str .. sk_name .. " (" .. sk_color .. sk_ttl .. C_RESET .. ") "
      end
    end
  end
  if caught_status == 0 then
    out_str = ""
  end
  PROMPT_INFO.durable_skill_status = out_str
end

local function score_process(line)
  local score_matches = PROMPT_INFO.level_regexp:match_all(line:line())
  if score_matches ~= nil then
    for s_ind, cur_match in pairs(score_matches) do
      if SET(PROMPT_INFO.guilds)[TRIM_STRING(cur_match[2])] then
        if tonumber(cur_match[3]) > 0 then
          LEVEL_TABLE[TRIM_STRING(cur_match[2])] = tonumber(cur_match[3])
        else
          if SET_VALUE_CONTAINS(LEVEL_TABLE, cur_match[2]) then
            REMOVE_FROM_SET(LEVEL_TABLE, cur_match[2])
          end
        end
      end
    end
  end
  local guild_matches = PROMPT_INFO.primary_guild_regexp:match(line:line())
  if guild_matches ~= nil then
    CHAR_DATA.prime_guild = guild_matches[3]
  end
  local char_matches = PROMPT_INFO.char_regexp:match(line:line())
  if char_matches ~= nil then
    CHAR_DATA.character_name = char_matches[2]
  end
  PROMPT_INFO.score_catch = PROMPT_INFO.score_catch + 1
  if PROMPT_INFO.score_catch >= 20 then
    PROMPT_INFO.score_catch = 0
  end
end

local function get_time_diff(delay_match, inc_line)
  local time_diff = 0
  if TABLE_LENGTH(delay_match) == 3 then
    if string.find(inc_line, 'minute')~=nil then
      time_diff = 60*tonumber(TRIM_STRING(delay_match[3]))
    end
    if string.find(inc_line, 'second')~=nil then
      time_diff = tonumber(TRIM_STRING(delay_match[3]))
    end
  end
  if TABLE_LENGTH(delay_match) == 4 then
    if string.find(inc_line, 'minute')~=nil and string.find(inc_line, 'second')~=nil then
      time_diff = 60*tonumber(TRIM_STRING(delay_match[3])) + tonumber(TRIM_STRING(delay_match[4]))
    end
    if string.find(inc_line, 'hour')~=nil and string.find(inc_line, 'second')~=nil then
      time_diff = 60*60*tonumber(TRIM_STRING(delay_match[3])) + tonumber(TRIM_STRING(delay_match[4]))
    end
    if string.find(inc_line, 'hour')~=nil and string.find(inc_line, 'minute')~=nil then
      time_diff = 60*60*tonumber(TRIM_STRING(delay_match[3])) + 60*tonumber(TRIM_STRING(delay_match[4]))
    end
  end
  if TABLE_LENGTH(delay_match) == 5 then
    time_diff = 60*60*tonumber(TRIM_STRING(delay_match[3])) + 60*tonumber(TRIM_STRING(delay_match[4])) + tonumber(TRIM_STRING(delay_match[5]))
  end
  -- blight.output(inc_line .. "  " .. tostring(time_diff) .. "  " .. tostring(TABLE_LENGTH(delay_match)))
  return time_diff
end

local function update_skill_table(table_key, time_diff)
  -- blight.output("Before - Delay")
  -- if SET_CONTAINS(SKILL_DELAY_TABLE_WIN, table_key) then
  --   blight.output(SKILL_DELAY_TABLE_WIN[table_key])
  -- end
  -- blight.output("Before - skill succeed")
  -- if SET_CONTAINS(SKILL_TABLE_WIN, table_key) then
  --   blight.output(SKILL_TABLE_WIN[table_key])
  -- end
  -- -- time diff is in seconds
  -- blight.output("Before - key")
  -- blight.output(table_key)
  -- blight.output("Before - time diff")
  -- blight.output(time_diff)
  -- blight.output("Before - current table")
  -- for k,v in pairs(SKILL_TABLE_WIN) do
  --   blight.output(tostring(k))
  --   blight.output(tostring(v))
  -- end
  if tonumber(time_diff) ~= 0 then

    ---- DELAY SECTION - delays are in seconds
    -- exist_delay = the delay calculated off of existing skill win delay data
    local exist_delay = 4
    if SET_CONTAINS(SKILL_TABLE_WIN, table_key) then
      exist_delay = ((os.time() - SKILL_TABLE_WIN[table_key]))
    end
    -- recorded_delay = the delay calculated off of existing skill delay data
    local recorded_delay = 4
    if SET_CONTAINS(SKILL_DELAY_TABLE_WIN, table_key) then
      recorded_delay = SKILL_DELAY_TABLE_WIN[table_key]
    end
    -- provided_delay = the delay calculated off of the delays command feed
    -- this will always be accurate for the end, but never for the total time
    local provided_delay = math.floor((time_diff))
    -- always place the most recent delay in the shim
    SKILL_DELAY_TABLE_SHIM[table_key] = provided_delay
    -- first adjust the delay table if we think it's wrong
    if exist_delay > recorded_delay then
      SKILL_DELAY_TABLE_WIN[table_key] = exist_delay
    end
    -- blight.output(tostring(provided_delay))
    -- blight.output(tostring(recorded_delay))
    if provided_delay > recorded_delay then
      SKILL_DELAY_TABLE_WIN[table_key] = provided_delay
    end
    SKILL_TABLE_WIN[table_key] = os.time() - time_diff
    -- blight.output("After")
    -- for k,v in pairs(SKILL_TABLE_WIN) do
    --   blight.output(tostring(k))
    --   blight.output(tostring(v))
    -- end
    
    -- blight.output(SKILL_DELAY_TABLE_WIN[table_key])
    -- blight.output(SKILL_TABLE_WIN[table_key])
  end
end

local function delays_process(line)
  for k,v in pairs(DELAYS_HOOKS) do
    local delay_match = v:match(line:line())
    if delay_match ~= nil then
      local table_key = delay_match[2]
      -- blight.output(table_key)
      local time_diff = get_time_diff(delay_match, line:line())
      -- blight.output(time_diff)
      -- blight.output(line:line() .. "  " .. tostring(time_diff) .. "  " .. tostring(TABLE_LENGTH(delay_match)) .. " " .. tostring(delay_match[2]))
      if SET_VALUE_CONTAINS(DELAYS_REMAP, delay_match[2]) then
        table_key = SET_REVERSE_LOOKUP(DELAYS_REMAP, delay_match[2])
        -- blight.output(table_key .. " " .. tostring(time_diff))
        update_skill_table(table_key, time_diff)
      end
      if SET_VALUE_CONTAINS(DELAYS_REMAP2, delay_match[2]) then
        table_key = SET_REVERSE_LOOKUP(DELAYS_REMAP2, delay_match[2])
        -- blight.output(table_key .. " " .. tostring(time_diff))
        update_skill_table(table_key, time_diff)
      end
      if rematch_caught == nil then
        update_skill_table(table_key, time_diff)
      end
    end
  end
  PROMPT_INFO.delays_catch = PROMPT_INFO.delays_catch + 1
  if PROMPT_INFO.delays_catch >= 10 then
    PROMPT_INFO.delays_catch = 0
  end
end

local function droid_process(line)
  local room_match = PROMPT_INFO.room_match:match(line:line())
  if room_match ~= nil then
    ROOM_TABLE["my_droids"] = {}
  else
    local droid_match = PROMPT_INFO.droid_match:match(line:line())
    if droid_match ~= nil then
      ADD_TO_SET(ROOM_TABLE["my_droids"],droid_match[2]..droid_match[3])
    end
  end
end

local function bsense_process(line)
  if SET_CONTAINS(DPR_INFO, TARGET_INFO['last_target']) then
    -- bsense puts the proper name into sentence case
    -- local new_regex = regex.new("^"..TARGET_INFO['last_target'].." is "..concat_string)
    local health_match = BSENSE_REGEX:match(line:line())
    if health_match ~= nil then
      -- from dpr.lua
      update_total_damage(health_match[2])
      local health_pct = BSENSE_TIERS_TOP[INDEX_OF(BSENSE_TIERS, health_match[3])]
      if DPR_INFO[TARGET_INFO['last_target']]["total"] ~= nil then
        table.insert(TARGET_INFO[TARGET_INFO['last_target']]["h_bsense"], "health="..tostring(health_pct)..", damage="..tostring(DPR_INFO[TARGET_INFO['last_target']]["total"]))
      end
    end
  end
  PROMPT_INFO.bsense_catch = PROMPT_INFO.bsense_catch + 1
  if PROMPT_INFO.bsense_catch >= 3 then
    PROMPT_INFO.bsense_catch = 0
  end
end

local function blook_process(line)
  if SET_CONTAINS(DPR_INFO, TARGET_INFO['last_target']) then
    local health_match = BSENSE_REGEX:match(line:line())
    if health_match ~= nil then
      -- from dpr.lua
      update_total_damage(health_match[2])
      local health_pct = BSENSE_TIERS_TOP[INDEX_OF(BSENSE_TIERS, health_match[3])]
      if DPR_INFO[TARGET_INFO['last_target']]["total"] ~= nil then
        table.insert(TARGET_INFO[TARGET_INFO['last_target']]["h_blook"], "health="..tostring(health_pct)..", damage="..tostring(DPR_INFO[TARGET_INFO['last_target']]["total"]))
      end
    end
  end
  PROMPT_INFO.blook_catch = PROMPT_INFO.blook_catch + 1
  if PROMPT_INFO.blook_catch >= 10 then
    PROMPT_INFO.blook_catch = 0
  end
end

-- prompt draw
local function status_draw()
  update_character_status()
  update_skill_status()
  update_target_status()
  update_durable_skill_status()
  if SETUP_STATE.prompt_set==0 then
    blight.status_height(4)
    SETUP_STATE.prompt_set = 1
  end
  if SETUP_STATE.uptime_set==0 then
    local test_str = store.session_read("uptime_data")
    if test_str ~= nil then
      SETUP_STATE.uptime_str = test_str
      SETUP_STATE.uptime_set = 1
    end
  end
  if SETUP_STATE.reboot_set==0 then
    local test_str = store.session_read("reboot_data")
    if test_str ~= nil then
      SETUP_STATE.reboot_set = 1
    end
  end
  local term_w, term_h = blight.terminal_dimensions()

  -- Vitals Line
  local vitals_line = C_RESET
  if PROMPT_INFO.char_active==1 then
    local name_max = string.len(CHAR_DATA.character_name)
    if SET_CONTAINS(DPR_INFO, TARGET_INFO['last_target']) then
      name_max = math.max(string.len(TARGET_INFO["last_target"]), name_max)
    end
    local name_pad = string.rep(" ", name_max - string.len(CHAR_DATA.character_name))
    vitals_line = vitals_line .. "C: " .. CHAR_DATA.character_name .. name_pad .. STATUS_SEP
    PROMPT_INFO.hp_length = string.len(STRIP_COLOR(PROMPT_INFO.hp)) + string.len(STRIP_COLOR(PROMPT_INFO.hp_max))
    local add_space = get_add_space('t')
    local hp_string = "H: " .. PROMPT_INFO.hp .. "/" .. PROMPT_INFO.hp_max .. PAD_PERCENT(tonumber(STRIP_COLOR(PROMPT_INFO.hp))/tonumber(STRIP_COLOR(PROMPT_INFO.hp_max)), add_space)
    vitals_line = vitals_line .. hp_string .. STATUS_SEP
    vitals_line = vitals_line .. "Dr: " .. PROMPT_INFO.drug .. STATUS_SEP
    vitals_line = vitals_line .. "W: " .. PROMPT_INFO.wimpy .. STATUS_SEP
    vitals_line = vitals_line .. "X: " .. PROMPT_INFO.exp .. STATUS_SEP
    vitals_line = vitals_line .. "$: " .. PROMPT_INFO.credits .. STATUS_SEP
    vitals_line = vitals_line .. "A: " .. PROMPT_INFO.align_team .. "/" .. PROMPT_INFO.align_jedi .. STATUS_SEP
    vitals_line = vitals_line .. "Sps: " .. PROMPT_INFO.sp .. "/" .. PROMPT_INFO.sp_max .. STATUS_SEP
    vitals_line = vitals_line .. "L: " .. CHAR_DATA.character_levels
  else
    vitals_line = vitals_line .. "Character and vitals unknown" .. C_BYELLOW .. " <reprompt>" .. C_RESET
  end
  vitals_line = vitals_line .. C_RESET

  -- Cmd Info + Move Info + Date Line + durable skills
  local lst_cmd = PROMPT_INFO.last_repeat_command
  if lst_cmd == "" then
    lst_cmd = C_BYELLOW .. "None" .. C_RESET
  end
  local rep_cmd_line = C_RESET .. "Cmd: " .. C_BYELLOW .. tostring(lst_cmd) .. C_RESET .. STATUS_SEP
  local rep_cmd_len = string.len(STRIP_COLOR(rep_cmd_line))
  local move_cmd = PROMPT_INFO.move_cmd
  if move_cmd == "" then
    move_cmd = C_BYELLOW .. "<set_move>" .. C_RESET
  end
  local move_line = C_RESET .. "Move: " .. C_BYELLOW .. tostring(move_cmd) .. C_RESET
  if PROMPT_INFO.move_cmd == "" then
    move_line = move_line
  else
    move_line = move_line .. C_BYELLOW .." (set_move)" .. C_RESET
  end
  local move_line_len = string.len(STRIP_COLOR(move_line))
  
  local durable_skill_line = " "
  local durable_skill_line_len = string.len(STRIP_COLOR(PROMPT_INFO.durable_skill_status))
  if durable_skill_line_len>0 then
    durable_skill_line = STATUS_SEP .. PROMPT_INFO.durable_skill_status
  end
  
  local date_line = rep_cmd_line .. move_line .. durable_skill_line .. C_RESET

  local reboot_diff = SETUP_STATE.uptime_str
  if SETUP_STATE.reboot_set == 1 and SETUP_STATE.uptime_set == 1 then
    local reboot_ttl = math.floor(os.difftime(CONVERT_MUD_DATE(SETUP_STATE.uptime_str), os.time()))
    reboot_diff = tostring(math.floor(reboot_ttl/24/60/60)) .. "d " .. os.date("!%Hh %Mm %Ss", reboot_ttl)
  end
  
  local idle_diff = os.difftime(os.time(), PROMPT_INFO.last_command_time)
  local session_diff = os.difftime(os.time(), SESSION_INFO.session_start)
  local date_line_end = "Idle: " .. os.date("!%H:%M:%S", idle_diff) .. STATUS_SEP
  date_line_end = date_line_end .. "S: " .. os.date("!%H:%M:%S", session_diff) .. STATUS_SEP
  date_line_end = date_line_end .. "R: " .. reboot_diff .. STATUS_SEP
  date_line_end = date_line_end .. "T: " .. os.date("%c") .. C_RESET

  local date_line_end_len = string.len(STRIP_COLOR(date_line_end))
  local date_start = term_w - rep_cmd_len - move_line_len - date_line_end_len - durable_skill_line_len - 6
  date_line = date_line .. C_GREEN .. string.rep("-", date_start) .. C_RESET .. "  " .. date_line_end

  -- Status + Char Data + exp etc...
  local info_line = TARGET_INFO.status_line .. STATUS_SEP
  info_line = info_line .. DPR_INFO.status_line .. STATUS_SEP
  info_line = info_line .. CHAR_DATA.skill_delays

  -- Line Draw
  blight.status_line(0, date_line)
  blight.status_line(1, info_line)
  blight.status_line(2, vitals_line)
 
  -- autosave check for DC
  local autos_diff = os.difftime(os.time(), PROMPT_INFO.last_autosave)
  if autos_diff > 10*60 and mud.is_connected() then
    blight.output(C_BYELLOW .. "Autosave Missed! " .. os.date("%c") .. C_RESET)
    mud.send("", {gag=1,})
    PROMPT_INFO.last_autosave = os.time()
  end
end

local function prompt_loop(m, line)
  PROMPT_INFO.hp = m[2]
  PROMPT_INFO.hp_max = m[3]
  PROMPT_INFO.exp = m[4]
  PROMPT_INFO.credits = m[5]
  PROMPT_INFO.align_team = m[6]
  PROMPT_INFO.align_jedi = m[7]
  PROMPT_INFO.wimpy = m[8]
  PROMPT_INFO.sp = m[9]
  PROMPT_INFO.sp_max = m[10]
  PROMPT_INFO.drug = m[11]
  PROMPT_INFO.char_active = 1
  status_draw()
end

local function all_output_loop(line)
  if line:prompt() then
    prompt_matches = PROMPT_INFO.prompt_re:match(line:raw())
    if prompt_matches ~= nil then
      if TABLE_LENGTH(prompt_matches)==11 then
        prompt_loop(prompt_matches, line)
        line:gag(1)
      end
    else
      PROMPT_INFO.last_repeat_command = ""
      PROMPT_INFO.save_raw_command = 0
    end
  else
    -- dpr code loops
    local match_found = 0
    for cur_priority=0,1,1 do
      for s_ind, cur_obj in pairs(DPR_TRIGGER_TABLE["t"..tostring(cur_priority)]) do
        if match_found == 0 then
          local line_matches = cur_obj["r"]:match(line:line())
          if line_matches ~= nil then
            -- blight.output("Match Found...")
            -- blight.output(tostring(TABLE_LENGTH(line_matches)))
            local new_damage = 0
            if TABLE_LENGTH(line_matches)>=4 then
              new_damage = dpr_primary_loop(line_matches[2], cur_obj["t"], line_matches[4], cur_obj["n"])
            else
              if TABLE_LENGTH(line_matches)==1 then
                new_damage = dpr_primary_loop("You", cur_obj["t"], nil, cur_obj["n"])
              else
                new_damage = dpr_primary_loop(line_matches[2], cur_obj["t"], nil, cur_obj["n"])
              end
            end
            local display_damage = false
            if TABLE_LENGTH(line_matches)>=4 then
              if line_matches[4]~="you" then
                display_damage = true
              end
            end
            if line_matches[2]=="You" then
              display_damage = true
            end
            if TABLE_LENGTH(line_matches)==1 then
              display_damage = true
            end
            if display_damage then
              line:gag(1)
              if new_damage==0 then
                -- we do this because regular black doesn't show up on black terminal backgrounds
                blight.output(C_BBLACK .. line:line() .. C_RESET .. " (" .. C_BYELLOW .. tostring(new_damage) .. C_RESET .. ")" )
              else
                blight.output(line:raw() .. C_RESET .. " (" .. C_BYELLOW .. "-" .. tostring(new_damage) .. C_RESET .. ")" )
              end
            end
            PROMPT_INFO.prev_damager = line_matches[2]
            match_found = 1
          end
        end
      end
    end
    if match_found then
      -- we found a match, so set our flags for next time
      PROMPT_INFO.prev_line_dpr_match = 1
    else
      -- no match was found for dpr, so run post processing logic
      if PROMPT_INFO.prev_line_dpr_match==0 then
        -- the previous line did not have a dpr match
        local dmg_matches = PROMPT_INFO.damage_regexp:match(line:line())
        if dmg_matches ~= nil then
          PROMPT_INFO.hp = dmg_matches[2]
          PROMPT_INFO.hp_max = dmg_matches[3]
          local new_dmg = math.abs(tonumber(dmg_matches[4]))
          local new_tier = (new_dmg - 2)/5 + 1
          local new_damage = dpr_primary_loop(PROMPT_INFO.prev_damager, "t"..tostring(new_tier), "you", 0)
        end
      end
      PROMPT_INFO.prev_line_dpr_match = 0
    end

    -- score catch Information
    if PROMPT_INFO.score_catch ~=0 then
      score_process(line)
    end

    -- delays catch information
    if PROMPT_INFO.delays_catch ~= 0 then
      delays_process(line)
    end

    -- target sense
    if PROMPT_INFO.bsense_catch ~= 0 then
      bsense_process(line)
    end
    if PROMPT_INFO.blook_catch ~= 0 then
      blook_process(line)
    end

    -- self contained processes
    droid_process(line)

  end
  PROMPT_INFO.prev_line = line:line()
  status_draw()
  return line
end

mud.add_output_listener(all_output_loop)

function GLOBAL_SEND(cur_string, suppressReflect)
  if suppressReflect == nil then
    suppressReflect = false
  end
  -- reset a bunch of command caches
  PROMPT_INFO.delays_catch = 0

  local test_string = NICKNAME_REPLACE(cur_string)
  if cur_string == "" then
    -- blight.output(C_BYELLOW .. "Skipped Command Save" .. C_RESET)
    PROMPT_INFO.save_raw_command = 0
  else
    -- blight.output(C_BYELLOW .. "SEND: " .. cur_string .. C_RESET)
    mud.send(cur_string, {gag = suppressReflect,})
    PROMPT_INFO.last_repeat_command = cur_string
    PROMPT_INFO.save_raw_command = 0
  end
  if cur_string == " " then
    mud.send(cur_string, {gag = suppressReflect,})
    PROMPT_INFO.last_repeat_command = cur_string
    PROMPT_INFO.save_raw_command = 0
  end
end

local function all_input_loop(line)
  PROMPT_INFO.score_catch = 0
  if PROMPT_INFO.score_regexp:match(line:line()) ~= nil then
    PROMPT_INFO.score_catch = 1
  end
  PROMPT_INFO.delays_catch = 0
  if PROMPT_INFO.delays_regexp:match(line:line()) ~= nil then
    PROMPT_INFO.delays_catch = 1
  end
  -- blight.output(C_BYELLOW .. line:line() .. C_RESET)

  -- reset all prompt caches on new line inputs
  PROMPT_INFO.bsense_catch = 0
  PROMPT_INFO.blook_catch = 0

  --- Repeat Function for last command
  if PROMPT_INFO.save_raw_command then
    if line:line() == "" then
      -- blight.output(C_BYELLOW .. "Empty String Sent" .. C_RESET)
      -- blight.output(C_BYELLOW .. "Last Command: " .. tostring(PROMPT_INFO.last_repeat_command) .. C_RESET)
      if tostring(PROMPT_INFO.last_repeat_command) == "" then
        -- blight.output(C_BYELLOW .. "Normal Send: " .. line:line() .. C_RESET)
      else
        -- blight.output(C_BYELLOW .. "Repeat Send: " .. tostring(PROMPT_INFO.last_repeat_command) .. C_RESET)
        line:replace(PROMPT_INFO.last_repeat_command)
        -- blight.output(C_BYELLOW .. "Repeat Line: " .. line:line() .. C_RESET)
        -- blight.output(C_BYELLOW .. "Repeat Raw: " .. line:raw() .. C_RESET)
        -- blight.output(C_BYELLOW .. "Repeat Replacement: " .. line:replacement() .. C_RESET)
      end
    else
      -- blight.output(C_BYELLOW .. "Normal Send: " .. line:line() .. C_RESET)
      -- now set all of the new state updates
      line:replace(NICKNAME_REPLACE(line:raw()))
    end
  end
  
  -- it will go through all of this and then hit GLOBAL SEND for alias
  PROMPT_INFO.last_command_time = os.time()
  PROMPT_INFO.last_command = line:line()
  if line:line() == "" or line:replacement() == "" then
    -- blight.output(C_BYELLOW .. "Skipped Command Save" .. C_RESET)
  else
    if PROMPT_INFO.save_raw_command == 1 then
      PROMPT_INFO.last_repeat_command = line:raw()
      -- blight.output(C_BYELLOW .. "Saved Command" .. C_RESET)
    end
    if line:line() == " " then
      PROMPT_INFO.last_repeat_command = line:line()
    end
  end
  PROMPT_INFO.last_autosave = os.time()
  PROMPT_INFO.save_raw_command = 1
  return line
end

mud.add_input_listener(all_input_loop)

--- TODO HERE
-- delete key bind to remove last prompt
-- blight.bind("\x7f", function()
--   blight.ui("delete")
--   PROMPT_INFO.last_repeat_command = ""
--   blight.output(C_BYELLOW .. "Cleared Repeat Send." .. C_RESET)
-- end)

-- add a timer to update every second
timer.add(1, 0, status_draw)

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

-- bsense trigger
trigger.add("^Your senses tell you that:$", {}, function (m)
  PROMPT_INFO.bsense_catch = 1
  -- TODO set this to only reset on a damage tier change
  TARGET_INFO.unrec_damage = 0
end)

-- blook trigger
trigger.add("^You look over the (.*)", {}, function (m)
  PROMPT_INFO.blook_catch = 1
  -- TODO set this to only reset on a damage tier change
  TARGET_INFO.unrec_damage = 0
end)
trigger.add("^(.*) is carrying:$", {}, function (m)
  PROMPT_INFO.blook_catch = 0
end)
