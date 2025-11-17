-- Status line rendering

local StatusRenderer = {}

function StatusRenderer.render()
  -- Update all status data first
  update_character_status()
  update_skill_status()
  if update_target_status then
    update_target_status()
  end
  update_durable_skill_status()
  
  -- Initialize status height
  if SETUP_STATE.prompt_set==0 then
    blight.status_height(4)
    SETUP_STATE.prompt_set = 1
  end
  
  -- Load uptime data
  if SETUP_STATE.uptime_set==0 then
    local test_str = store.session_read("uptime_data")
    if test_str ~= nil then
      SETUP_STATE.uptime_str = test_str
      SETUP_STATE.uptime_set = 1
    end
  end
  
  -- Load reboot data
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
    local add_space = 0
    if get_add_space then
      add_space = get_add_space('t')
    end
    local hp_string = "H: " .. PROMPT_INFO.hp .. "/" .. PROMPT_INFO.hp_max .. PAD_PERCENT(tonumber(STRIP_COLOR(PROMPT_INFO.hp))/tonumber(STRIP_COLOR(PROMPT_INFO.hp_max)), add_space)
    vitals_line = vitals_line .. hp_string .. STATUS_SEP
    vitals_line = vitals_line .. "Dr: " .. PROMPT_INFO.drug .. STATUS_SEP
    vitals_line = vitals_line .. "W: " .. PROMPT_INFO.wimpy .. STATUS_SEP
    
    -- Display exp with exp to next level or exp over
    local exp_display = "X: " .. PROMPT_INFO.exp
    if SET_CONTAINS(LEVEL_TABLE, CHAR_DATA.prime_guild) and format_exp_display then
      local current_level = LEVEL_TABLE[CHAR_DATA.prime_guild]
      local current_exp = tonumber(STRIP_COLOR(PROMPT_INFO.exp)) or 0
      local exp_info = format_exp_display(current_level, current_exp, CHAR_DATA.prime_guild)
      if exp_info then
        exp_display = exp_display .. " (" .. exp_info .. ")"
      end
    end
    vitals_line = vitals_line .. exp_display .. STATUS_SEP
    
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
  if PROMPT_INFO.move_cmd ~= "" then
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

-- Export as global for backward compatibility
status_draw = StatusRenderer.render

return StatusRenderer

