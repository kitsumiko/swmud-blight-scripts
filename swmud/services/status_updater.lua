-- Status update services

local StatusUpdater = {}

function StatusUpdater.update_character_status()
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

function StatusUpdater.update_skill_status()
  local out_str = "De: "
  local temp_add = ""
  if TABLE_LENGTH(SKILL_TABLE_WIN)>0 then
    for k,v in pairs(SKILL_TABLE_WIN) do
      if v ~= nil then
        -- v is the absolute time when the skill will be ready (future time)
        local total_time = 4
        local max_time = 4
        if SET_CONTAINS(SKILL_DELAY_TABLE_WIN, k) then
          total_time = SKILL_DELAY_TABLE_WIN[k]
          max_time = SKILL_DELAY_TABLE_WIN[k]
        end
        if SET_CONTAINS(SKILL_DELAY_TABLE_SHIM, k) then
          -- Use the total cooldown time from WIN table if available, otherwise use SHIM (remaining time)
          if SET_CONTAINS(SKILL_DELAY_TABLE_WIN, k) then
            total_time = SKILL_DELAY_TABLE_WIN[k]
            max_time = math.max(SKILL_DELAY_TABLE_WIN[k], SKILL_DELAY_TABLE_SHIM[k])
          else
            total_time = SKILL_DELAY_TABLE_SHIM[k]
            max_time = SKILL_DELAY_TABLE_SHIM[k]
          end
        end
        -- Calculate remaining time: future_time - current_time
        local rep_time = math.floor(os.difftime(v, os.time()))
        if rep_time <= 0 then
          -- Skill is ready, remove it
          SKILL_TABLE_WIN[k] = nil
        else
          -- Calculate progress percentage for color (remaining / total)
          local progress_ratio = 1 - (rep_time / total_time)
          if progress_ratio < 0 then progress_ratio = 0 end
          if progress_ratio > 1 then progress_ratio = 1 end
          temp_add = temp_add .. k .. " (".. GET_COLOR(progress_ratio) .. tostring(rep_time) .. C_RESET..") "
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
    -- If delays have been checked and there are none, show "None"
    -- Otherwise show the hint to run delays command
    if DELAYS_CHECKED then
      temp_add = C_WHITE .. "None" .. C_RESET
    else
      temp_add = C_BYELLOW .. "<delays>" .. C_RESET
    end
  else
    -- If we have delays, reset the checked flag (delays exist now)
    DELAYS_CHECKED = false
  end
  out_str = out_str .. temp_add
  CHAR_DATA.skill_delays = out_str
end

function StatusUpdater.update_durable_skill_status()
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

-- Export as globals for backward compatibility
update_character_status = StatusUpdater.update_character_status
update_skill_status = StatusUpdater.update_skill_status
update_durable_skill_status = StatusUpdater.update_durable_skill_status

return StatusUpdater

