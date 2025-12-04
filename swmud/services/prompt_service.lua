-- Main prompt processing service
-- Note: Parsers are loaded via script.load() and available as modules

local PromptService = {}

-- Flag to prevent recursion when processing aliases in GLOBAL_SEND
-- This is set when mud.input() is called from GLOBAL_SEND to prevent infinite loops
-- Made global so aliases can check it
GLOBAL_SEND_PROCESSING = false
-- Track the command currently being processed to prevent re-processing
GLOBAL_SEND_CURRENT_COMMAND = ""
-- Track the last command sent to prevent immediate repetition
local LAST_SENT_COMMAND = ""
local LAST_SENT_TIME = 0

function PromptService.process_prompt(matches, line)
  local old_exp = tonumber(STRIP_COLOR(PROMPT_INFO.exp)) or 0
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
  
  -- Track experience changes
  local new_exp = tonumber(STRIP_COLOR(PROMPT_INFO.exp)) or 0
  if record_exp_change and new_exp ~= old_exp then
    record_exp_change(new_exp)
  end
  
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
      -- Try multiple ways to get ScoreParser (handle deferred loading)
      -- Check both global scope and _G table
      local parser = ScoreParser or _G.ScoreParser
      if not parser then
        -- If still not available, try to reload it (shouldn't happen, but safety check)
        -- This is a fallback for edge cases during reload
        -- if LOG_DEBUG then
        --   LOG_DEBUG("PromptService: ScoreParser not available, attempting to reload score_parser")
        -- end
        script.load('~/.config/blightmud/swmud/parsers/score_parser.lua')
        parser = ScoreParser or _G.ScoreParser
      end
      if parser and parser.process then
        parser.process(line)
      end
    end

    -- delays catch information
    -- Check both the flag (set by input listener) and directly check for delay patterns
    -- This handles cases where delays command is sent via mud.send() (bypassing input listener)
    local should_process_delays = false
    if PROMPT_INFO.delays_catch ~= 0 then
      should_process_delays = true
    else
      -- Check if this line matches a delay pattern (even if flag wasn't set)
      -- This catches delays sent via mud.send() from aliases like 'de'
      -- Try both line() and raw() to catch the delay pattern
      if DELAYS_HOOKS then
        local line_text = line:line()
        local raw_line = line:raw()
        for k, v in pairs(DELAYS_HOOKS) do
          local delay_match = v:match(line_text)
          if delay_match == nil then
            delay_match = v:match(raw_line)
          end
          if delay_match ~= nil then
            should_process_delays = true
            -- Set the flag so subsequent delay lines are also processed
            PROMPT_INFO.delays_catch = 1
            break
          end
        end
      end
    end
    
    if should_process_delays then
      -- Try multiple ways to get DelaysParser (handle deferred loading)
      local parser = DelaysParser or _G.DelaysParser
      if parser and parser.process then
        parser.process(line)
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
  local line_raw = line:raw()
  
  -- Preprocess no-space aliases that BlightMud doesn't handle well
  -- These are registered by create_no_space_alias and create_no_space_nested_alias
  -- Check against all registered patterns and replace if matched
  -- Use raw() to get the exact input before any processing, strip newlines
  -- blight.output("[PREPROCESS] Checking NO_SPACE_ALIASES, exists=" .. tostring(NO_SPACE_ALIASES ~= nil) .. ", has_entries=" .. tostring(NO_SPACE_ALIASES and next(NO_SPACE_ALIASES) ~= nil))
  if NO_SPACE_ALIASES and next(NO_SPACE_ALIASES) then
    -- Clean the raw input - remove newlines and trim
    local clean_raw = line_raw:gsub("[\r\n]", ""):match("^%s*(.-)%s*$") or line_raw:gsub("[\r\n]", "")
    -- blight.output("[PREPROCESS] clean_raw='" .. clean_raw .. "', line_text='" .. line_text .. "'")
    -- local pattern_count = 0
    -- for _ in pairs(NO_SPACE_ALIASES) do pattern_count = pattern_count + 1 end
    -- blight.output("[PREPROCESS] Found " .. pattern_count .. " patterns in NO_SPACE_ALIASES")
    -- Try matching against cleaned raw input first (most accurate)
    for pattern, replacement_fn in pairs(NO_SPACE_ALIASES) do
      -- blight.output("[PREPROCESS] Trying pattern: '" .. pattern .. "'")
      local capture = clean_raw:match(pattern)
      -- blight.output("[PREPROCESS] Pattern match result: " .. tostring(capture))
      if capture then
        local replacement = replacement_fn(clean_raw, capture)
        -- blight.output("[PREPROCESS] Match found! Replacement: '" .. replacement .. "'")
        if replacement then
          -- Replace the line with empty string and gag it to prevent it from being sent
          line:replace("")
          line:gag(1)
          -- Save the preprocessed command for repeat functionality
          if PROMPT_INFO.save_raw_command == 1 then
            PROMPT_INFO.last_repeat_command = replacement
          end
          -- Send the replacement command using mud.send() without gag so it shows in terminal
          -- This sends directly to MUD without triggering input listener again
          mud.send(replacement)
          -- Return the line object (required by BlightMud) - it's gagged and empty so won't be sent
          return line
        end
      end
    end
    -- If no match on raw, try line_text as fallback
    if line_text == line:line() then
      -- blight.output("[PREPROCESS] No match on raw, trying line_text fallback")
      local clean_text = line_text:gsub("[\r\n]", ""):match("^%s*(.-)%s*$") or line_text:gsub("[\r\n]", "")
      for pattern, replacement_fn in pairs(NO_SPACE_ALIASES) do
        local capture = clean_text:match(pattern)
        if capture then
          local replacement = replacement_fn(clean_text, capture)
          -- blight.output("[PREPROCESS] Match found on line_text! Replacement: '" .. replacement .. "'")
          if replacement then
            -- Replace the line with empty string and gag it to prevent it from being sent
            line:replace("")
            line:gag(1)
            if PROMPT_INFO.save_raw_command == 1 then
              PROMPT_INFO.last_repeat_command = replacement
            end
            -- Send the replacement command using mud.send() without gag so it shows in terminal
            -- This sends directly to MUD without triggering input listener again
            mud.send(replacement)
            -- Return the line object (required by BlightMud) - it's gagged and empty so won't be sent
            return line
          end
        end
      end
    end
  -- else
  --   blight.output("[PREPROCESS] NO_SPACE_ALIASES not available or empty")
  end
  
  -- blight.output("[input_loop] Processing line: '" .. line_text .. "', GLOBAL_SEND_PROCESSING=" .. tostring(GLOBAL_SEND_PROCESSING))
  
  -- When GLOBAL_SEND_PROCESSING is true, we're processing a command from GLOBAL_SEND
  -- We need to allow normal alias processing but prevent recursive GLOBAL_SEND calls
  -- The key is to let the command go through normally but skip state updates that cause loops
  if GLOBAL_SEND_PROCESSING then
    -- blight.output("[input_loop] GLOBAL_SEND_PROCESSING is true, processing from GLOBAL_SEND")
    -- Allow nickname replacement
    line:replace(NICKNAME_REPLACE(line:raw()))
    
    -- Prevent immediate repetition of the same command
    local processed_cmd = line:replacement() or line_text
    -- blight.output("[input_loop] Processed command: '" .. processed_cmd .. "', LAST_SENT_COMMAND='" .. LAST_SENT_COMMAND .. "'")
    local current_time = os.time()
    if processed_cmd == LAST_SENT_COMMAND and (current_time - LAST_SENT_TIME) < 0.5 then
      -- blight.output("[input_loop] Same command sent within 0.5s, gagging to prevent repetition")
      -- Same command sent within 0.5 seconds - gag it to prevent repetition
      line:gag(1)
      return line
    end
    LAST_SENT_COMMAND = processed_cmd
    LAST_SENT_TIME = current_time
    
    -- Save the processed command (after aliases) instead of raw input
    -- This happens after aliases have been processed, so line:replacement() contains the final command
    if line:replacement() ~= "" then
      PROMPT_INFO.last_repeat_command = line:replacement()
      -- blight.output("[input_loop] Saved last_repeat_command: '" .. PROMPT_INFO.last_repeat_command .. "'")
    end
    
    -- blight.output("[input_loop] Continuing to normal processing (not returning early)")
    -- IMPORTANT: Don't return early - let the command continue through normal processing
    -- so it actually gets sent to the MUD. Just skip the state updates that cause loops.
    -- Continue to normal processing below, but skip the parts that update state
  end
  
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
    -- if LOG_DEBUG then
    --   LOG_DEBUG("PromptService: score command detected, score_catch set to 1")
    -- end
  end
  PROMPT_INFO.delays_catch = 0
  if PROMPT_INFO.delays_regexp:match(line_text) ~= nil then
    PROMPT_INFO.delays_catch = 1
    SKILL_TABLE_WIN = {}
    -- Reset delays_checked flag when delays command is run
    -- It will be set to true if "no skills" message is received
    DELAYS_CHECKED = false
  end

  -- reset all prompt caches on new line inputs (skip if from GLOBAL_SEND to prevent loops)
  if not GLOBAL_SEND_PROCESSING then
    PROMPT_INFO.bsense_catch = 0
    PROMPT_INFO.blook_catch = 0
  end

  --- Repeat Function for last command
  if PROMPT_INFO.save_raw_command then
    if line:line() == "" then
      if tostring(PROMPT_INFO.last_repeat_command) ~= "" then
        line:replace(PROMPT_INFO.last_repeat_command)
      end
    else
      if not GLOBAL_SEND_PROCESSING then
        -- Only do nickname replacement if not already done above
        line:replace(NICKNAME_REPLACE(line:raw()))
      end
    end
  end
  
  -- Skip state updates if from GLOBAL_SEND to prevent loops
  if not GLOBAL_SEND_PROCESSING then
    PROMPT_INFO.last_command_time = os.time()
    PROMPT_INFO.last_command = line:line()
    if line:line() ~= "" and line:replacement() ~= "" then
      if PROMPT_INFO.save_raw_command == 1 then
        -- Save the processed command (after aliases) instead of raw input
        -- line:replacement() contains the final command that will be sent after alias processing
        PROMPT_INFO.last_repeat_command = line:replacement()
      end
      if line:line() == " " then
        PROMPT_INFO.last_repeat_command = line:replacement()
      end
    end
    PROMPT_INFO.last_autosave = os.time()
    PROMPT_INFO.save_raw_command = 1
  end
  return line
end

function GLOBAL_SEND(cur_string, suppressReflect)
  if suppressReflect == nil then
    suppressReflect = false
  end
  
  -- blight.output("[GLOBAL_SEND] Called with: '" .. cur_string .. "', suppressReflect=" .. tostring(suppressReflect) .. ", GLOBAL_SEND_PROCESSING=" .. tostring(GLOBAL_SEND_PROCESSING))
  
  -- Prevent infinite recursion - if we're already processing, send directly
  if GLOBAL_SEND_PROCESSING then
    -- blight.output("[GLOBAL_SEND] Already processing, sending directly with mud.send()")
    mud.send(cur_string, {gag = suppressReflect,})
    return
  end
  
  PROMPT_INFO.delays_catch = 0

  local test_string = NICKNAME_REPLACE(cur_string)
  if cur_string == "" then
    PROMPT_INFO.save_raw_command = 0
  else
    -- Process nicknames first
    local processed_cmd = NICKNAME_REPLACE(cur_string)
    -- blight.output("[GLOBAL_SEND] Processed command (after nicknames): '" .. processed_cmd .. "'")
    
    -- Check if we're already processing this exact command (prevents infinite loops)
    if GLOBAL_SEND_PROCESSING and GLOBAL_SEND_CURRENT_COMMAND == processed_cmd then
      -- blight.output("[GLOBAL_SEND] Already processing same command, sending directly to break loop")
      -- Already processing this exact command, send directly to break the loop
      mud.send(processed_cmd, {gag = suppressReflect,})
      return
    end
    
    -- Set flag and track current command BEFORE calling mud.input() so aliases can check it
    -- blight.output("[GLOBAL_SEND] Setting GLOBAL_SEND_PROCESSING=true, GLOBAL_SEND_CURRENT_COMMAND='" .. processed_cmd .. "'")
    GLOBAL_SEND_PROCESSING = true
    GLOBAL_SEND_CURRENT_COMMAND = processed_cmd
    
    -- Use mud.input() which will trigger aliases through the normal input pipeline
    -- The flag is set so that if aliases match again, they'll send directly instead of calling GLOBAL_SEND
    -- Use pcall to ensure flag is reset even if there's an error
    -- blight.output("[GLOBAL_SEND] Calling mud.input('" .. processed_cmd .. "')")
    local success, err = pcall(function()
      mud.input(processed_cmd)
    end)
    
    -- blight.output("[GLOBAL_SEND] mud.input() returned, success=" .. tostring(success))
    
    -- Always reset flag, even if there was an error
    -- blight.output("[GLOBAL_SEND] Resetting flags")
    GLOBAL_SEND_PROCESSING = false
    GLOBAL_SEND_CURRENT_COMMAND = ""
    
    if not success then
      -- blight.output("[GLOBAL_SEND] Error occurred, falling back to mud.send()")
      -- If there was an error, fall back to mud.send()
      mud.send(processed_cmd, {gag = suppressReflect,})
      -- On error, save the original command since we can't get the processed version
      PROMPT_INFO.last_repeat_command = processed_cmd
    end
    
    -- Save the processed command (will be updated by input listener if mud.input() succeeded)
    PROMPT_INFO.last_repeat_command = processed_cmd
    PROMPT_INFO.save_raw_command = 0
  end
  if cur_string == " " then
    GLOBAL_SEND_PROCESSING = true
    local success, err = pcall(function()
      mud.input(cur_string)
    end)
    GLOBAL_SEND_PROCESSING = false
    if not success then
      mud.send(cur_string, {gag = suppressReflect,})
      PROMPT_INFO.last_repeat_command = cur_string
    end
    PROMPT_INFO.save_raw_command = 0
  end
end

-- Export as global
PromptService = PromptService

-- Set up listeners
-- if LOG_DEBUG then
--   LOG_DEBUG("Setting up prompt service listeners...")
-- else
--   blight.output("DEBUG: Setting up prompt service listeners...")
-- end

if mud and mud.add_output_listener then
  mud.add_output_listener(PromptService.output_loop)
  -- if LOG_DEBUG then
  --   LOG_DEBUG("Output listener added")
  -- else
  --   blight.output("DEBUG: Output listener added")
  -- end
else
  local msg = "Warning: mud.add_output_listener not available"
  -- if LOG_DEBUG then
  --   LOG_DEBUG(msg)
  -- else
  --   blight.output(msg)
  -- end
end

if mud and mud.add_input_listener then
  mud.add_input_listener(PromptService.input_loop)
  -- if LOG_DEBUG then
  --   LOG_DEBUG("Input listener added")
  -- else
  --   blight.output("DEBUG: Input listener added")
  -- end
else
  local msg = "Warning: mud.add_input_listener not available"
  -- if LOG_DEBUG then
  --   LOG_DEBUG(msg)
  -- else
  --   blight.output(msg)
  -- end
end

-- Add timer to update every second
if timer and timer.add and status_draw then
  timer.add(1, 0, status_draw)
  -- if LOG_DEBUG then
  --   LOG_DEBUG("Timer added for status_draw")
  -- else
  --   blight.output("DEBUG: Timer added for status_draw")
  -- end
else
  local msg = "Warning: timer.add or status_draw not available"
  -- if LOG_DEBUG then
  --   LOG_DEBUG(msg)
  -- else
  --   blight.output(msg)
  -- end
  if not timer then
    local msg2 = "  - timer is nil"
    -- if LOG_DEBUG then LOG_DEBUG(msg2) else blight.output(msg2) end
  end
  if timer and not timer.add then
    local msg2 = "  - timer.add is nil"
    -- if LOG_DEBUG then LOG_DEBUG(msg2) else blight.output(msg2) end
  end
  if not status_draw then
    local msg2 = "  - status_draw is nil"
    -- if LOG_DEBUG then LOG_DEBUG(msg2) else blight.output(msg2) end
  end
end

-- if LOG_DEBUG then
--   LOG_DEBUG("Prompt service setup complete")
-- else
--   blight.output("DEBUG: Prompt service setup complete")
-- end
return PromptService

