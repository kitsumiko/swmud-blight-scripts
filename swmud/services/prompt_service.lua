-- Main prompt processing service
-- Note: Parsers are loaded via script.load() and available as modules

local PromptService = {}

function PromptService.process_prompt(matches, line)
  PROMPT_INFO.hp = matches[2]
  PROMPT_INFO.hp_max = matches[3]
  PROMPT_INFO.exp = matches[4]
  PROMPT_INFO.credits = matches[5]
  PROMPT_INFO.align_team = matches[6]
  PROMPT_INFO.align_jedi = matches[7]
  PROMPT_INFO.wimpy = matches[8]
  PROMPT_INFO.sp = matches[9]
  PROMPT_INFO.sp_max = matches[10]
  PROMPT_INFO.drug = matches[11]
  PROMPT_INFO.char_active = 1
  status_draw()
end

function PromptService.process_bsense(line)
  if SET_CONTAINS(DPR_INFO, TARGET_INFO['last_target']) then
    local health_match = BSENSE_REGEX:match(line:line())
    if health_match ~= nil then
      if update_total_damage then
        update_total_damage(health_match[2])
      end
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

function PromptService.process_blook(line)
  if SET_CONTAINS(DPR_INFO, TARGET_INFO['last_target']) then
    local health_match = BSENSE_REGEX:match(line:line())
    if health_match ~= nil then
      if update_total_damage then
        update_total_damage(health_match[2])
      end
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

function PromptService.output_loop(line)
  if line:prompt() then
    local prompt_matches = PROMPT_INFO.prompt_re:match(line:raw())
    if prompt_matches ~= nil then
      if TABLE_LENGTH(prompt_matches)==11 then
        PromptService.process_prompt(prompt_matches, line)
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
            local new_damage = 0
            if TABLE_LENGTH(line_matches)>=4 then
              if dpr_primary_loop then
                new_damage = dpr_primary_loop(line_matches[2], cur_obj["t"], line_matches[4], cur_obj["n"])
              end
            else
              if TABLE_LENGTH(line_matches)==1 then
                if dpr_primary_loop then
                  new_damage = dpr_primary_loop("You", cur_obj["t"], nil, cur_obj["n"])
                end
              else
                if dpr_primary_loop then
                  new_damage = dpr_primary_loop(line_matches[2], cur_obj["t"], nil, cur_obj["n"])
                end
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
      PROMPT_INFO.prev_line_dpr_match = 1
    else
      if PROMPT_INFO.prev_line_dpr_match==0 then
        local dmg_matches = PROMPT_INFO.damage_regexp:match(line:line())
        if dmg_matches ~= nil then
          PROMPT_INFO.hp = dmg_matches[2]
          PROMPT_INFO.hp_max = dmg_matches[3]
          local new_dmg = math.abs(tonumber(dmg_matches[4]))
          local new_tier = (new_dmg - 2)/5 + 1
          if dpr_primary_loop then
            dpr_primary_loop(PROMPT_INFO.prev_damager, "t"..tostring(new_tier), "you", 0)
          end
        end
      end
      PROMPT_INFO.prev_line_dpr_match = 0
    end

    -- score catch Information
    if PROMPT_INFO.score_catch ~=0 then
      if LOG_DEBUG then
        LOG_DEBUG("PromptService: Processing score line, score_catch=" .. tostring(PROMPT_INFO.score_catch))
      end
      if ScoreParser and ScoreParser.process then
        ScoreParser.process(line)
      else
        if LOG_DEBUG then
          LOG_DEBUG("PromptService: ScoreParser not available! ScoreParser=" .. tostring(ScoreParser))
        end
      end
    end

    -- delays catch information
    if PROMPT_INFO.delays_catch ~= 0 then
      if DelaysParser and DelaysParser.process then
        DelaysParser.process(line)
      end
    end

    -- target sense
    if PROMPT_INFO.bsense_catch ~= 0 then
      PromptService.process_bsense(line)
    end
    if PROMPT_INFO.blook_catch ~= 0 then
      PromptService.process_blook(line)
    end

    -- self contained processes
    if RoomParser and RoomParser.process_droid then
      RoomParser.process_droid(line)
    end
  end
  PROMPT_INFO.prev_line = line:line()
  status_draw()
  return line
end

function PromptService.input_loop(line)
  local line_text = line:line()
  
  -- Handle /reload command
  if line_text == "/reload" then
    blight.output((C_BYELLOW or "") .. "Reloading scripts..." .. (C_RESET or ""))
    line:gag(1)  -- Prevent sending to MUD
    if RELOAD_SCRIPTS then
      -- Use a timer to call RELOAD_SCRIPTS after this function returns
      -- This prevents issues with modifying state during input processing
      timer.add(0.1, 1, function()
        RELOAD_SCRIPTS()
        blight.output((C_BGREEN or "") .. "Scripts reloaded successfully!" .. (C_RESET or ""))
      end)
    else
      blight.output((C_BRED or "") .. "ERROR: RELOAD_SCRIPTS function not available!" .. (C_RESET or ""))
    end
    return line
  end
  
  PROMPT_INFO.score_catch = 0
  if PROMPT_INFO.score_regexp:match(line_text) ~= nil then
    PROMPT_INFO.score_catch = 1
    if LOG_DEBUG then
      LOG_DEBUG("PromptService: score command detected, score_catch set to 1")
    end
  end
  PROMPT_INFO.delays_catch = 0
  if PROMPT_INFO.delays_regexp:match(line_text) ~= nil then
    PROMPT_INFO.delays_catch = 1
    SKILL_TABLE_WIN = {}
    -- Reset delays_checked flag when delays command is run
    -- It will be set to true if "no skills" message is received
    DELAYS_CHECKED = false
  end

  -- reset all prompt caches on new line inputs
  PROMPT_INFO.bsense_catch = 0
  PROMPT_INFO.blook_catch = 0

  --- Repeat Function for last command
  if PROMPT_INFO.save_raw_command then
    if line:line() == "" then
      if tostring(PROMPT_INFO.last_repeat_command) ~= "" then
        line:replace(PROMPT_INFO.last_repeat_command)
      end
    else
      line:replace(NICKNAME_REPLACE(line:raw()))
    end
  end
  
  PROMPT_INFO.last_command_time = os.time()
  PROMPT_INFO.last_command = line:line()
  if line:line() ~= "" and line:replacement() ~= "" then
    if PROMPT_INFO.save_raw_command == 1 then
      PROMPT_INFO.last_repeat_command = line:raw()
    end
    if line:line() == " " then
      PROMPT_INFO.last_repeat_command = line:line()
    end
  end
  PROMPT_INFO.last_autosave = os.time()
  PROMPT_INFO.save_raw_command = 1
  return line
end

function GLOBAL_SEND(cur_string, suppressReflect)
  if suppressReflect == nil then
    suppressReflect = false
  end
  PROMPT_INFO.delays_catch = 0

  local test_string = NICKNAME_REPLACE(cur_string)
  if cur_string == "" then
    PROMPT_INFO.save_raw_command = 0
  else
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

-- Export as global
PromptService = PromptService

-- Set up listeners
blight.output("DEBUG: Setting up prompt service listeners...")
if mud and mud.add_output_listener then
  mud.add_output_listener(PromptService.output_loop)
  blight.output("DEBUG: Output listener added")
else
  blight.output("Warning: mud.add_output_listener not available")
end

if mud and mud.add_input_listener then
  mud.add_input_listener(PromptService.input_loop)
  blight.output("DEBUG: Input listener added")
else
  blight.output("Warning: mud.add_input_listener not available")
end

-- Add timer to update every second
if timer and timer.add and status_draw then
  timer.add(1, 0, status_draw)
  blight.output("DEBUG: Timer added for status_draw")
else
  blight.output("Warning: timer.add or status_draw not available")
  if not timer then
    blight.output("  - timer is nil")
  end
  if not timer.add then
    blight.output("  - timer.add is nil")
  end
  if not status_draw then
    blight.output("  - status_draw is nil")
  end
end

blight.output("DEBUG: Prompt service setup complete")
return PromptService

