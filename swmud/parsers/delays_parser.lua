-- Delays command parsing

local DelaysParser = {}

-- Export to global scope immediately
_G.DelaysParser = DelaysParser

local function get_time_diff(delay_match, inc_line)
  local time_diff = 0
  -- delay_match structure: [1] = full match, [2] = skill name, [3+] = time values
  -- Pattern 1: "X seconds" -> length 3 (full, skill, seconds)
  -- Pattern 2: "X minutes" -> length 3 (full, skill, minutes)
  -- Pattern 3-7: "X minutes and Y seconds" or "X hours and Y seconds/minutes" -> length 4 (full, skill, first_time, second_time)
  -- Pattern 8-9: "X hours, Y minutes, and Z seconds" -> length 5 (full, skill, hours, minutes, seconds)
  
  if TABLE_LENGTH(delay_match) == 3 then
    -- Single time unit: seconds or minutes
    local time_value = tonumber(TRIM_STRING(delay_match[3]))
    if time_value == nil then
      return 0
    end
    if string.find(inc_line, 'minute')~=nil then
      time_diff = 60 * time_value
    elseif string.find(inc_line, 'second')~=nil then
      time_diff = time_value
    end
  elseif TABLE_LENGTH(delay_match) == 4 then
    -- Two time units: minutes+seconds, hours+seconds, or hours+minutes
    local first_value = tonumber(TRIM_STRING(delay_match[3]))
    local second_value = tonumber(TRIM_STRING(delay_match[4]))
    if first_value == nil or second_value == nil then
      return 0
    end
    if string.find(inc_line, 'minute')~=nil and string.find(inc_line, 'second')~=nil then
      -- "X minutes and Y seconds"
      time_diff = 60 * first_value + second_value
    elseif string.find(inc_line, 'hour')~=nil and string.find(inc_line, 'second')~=nil then
      -- "X hours and Y seconds"
      time_diff = 60 * 60 * first_value + second_value
    elseif string.find(inc_line, 'hour')~=nil and string.find(inc_line, 'minute')~=nil then
      -- "X hours and Y minutes"
      time_diff = 60 * 60 * first_value + 60 * second_value
    end
  elseif TABLE_LENGTH(delay_match) == 5 then
    -- Three time units: hours, minutes, and seconds
    local hours = tonumber(TRIM_STRING(delay_match[3]))
    local minutes = tonumber(TRIM_STRING(delay_match[4]))
    local seconds = tonumber(TRIM_STRING(delay_match[5]))
    if hours == nil or minutes == nil or seconds == nil then
      return 0
    end
    time_diff = 60 * 60 * hours + 60 * minutes + seconds
  end
  return time_diff
end

local function update_skill_table(table_key, time_diff)
  if tonumber(time_diff) ~= 0 then
    -- time_diff is the remaining time until the skill is ready (from MUD response)
    local remaining_time = math.floor(time_diff)
    local current_time = os.time()
    
    -- Store the remaining time as a reference
    SKILL_DELAY_TABLE_SHIM[table_key] = remaining_time
    
    -- Calculate the total cooldown time
    local total_cooldown = remaining_time
    local recorded_delay = 4
    if SET_CONTAINS(SKILL_DELAY_TABLE_WIN, table_key) then
      recorded_delay = SKILL_DELAY_TABLE_WIN[table_key]
    end
    
    if SET_CONTAINS(SKILL_TABLE_WIN, table_key) then
      local previous_time = SKILL_TABLE_WIN[table_key]
      
      -- Check if previous_time is in the past (skill was used) or future (skill ready time from previous delays command)
      if previous_time <= current_time then
        -- Previous time is in the past, meaning skill was used at previous_time
        -- Calculate total cooldown: elapsed_time + remaining_time
        local elapsed_time = current_time - previous_time
        total_cooldown = elapsed_time + remaining_time
        
        -- Update recorded delay if this gives us a better estimate
        if total_cooldown > recorded_delay then
          SKILL_DELAY_TABLE_WIN[table_key] = total_cooldown
        elseif remaining_time > recorded_delay then
          SKILL_DELAY_TABLE_WIN[table_key] = remaining_time
        else
          SKILL_DELAY_TABLE_WIN[table_key] = recorded_delay
        end
      else
        -- Previous time is in the future, meaning it was set by a previous delays command
        -- Calculate how much time has elapsed since then
        local previous_remaining = previous_time - current_time
        if previous_remaining > remaining_time then
          -- Time has passed, we can calculate the total cooldown
          local elapsed_time = previous_remaining - remaining_time
          total_cooldown = elapsed_time + remaining_time
          
          if total_cooldown > recorded_delay then
            SKILL_DELAY_TABLE_WIN[table_key] = total_cooldown
          elseif remaining_time > recorded_delay then
            SKILL_DELAY_TABLE_WIN[table_key] = remaining_time
          else
            SKILL_DELAY_TABLE_WIN[table_key] = recorded_delay
          end
        elseif remaining_time > recorded_delay then
          SKILL_DELAY_TABLE_WIN[table_key] = remaining_time
        else
          SKILL_DELAY_TABLE_WIN[table_key] = recorded_delay
        end
      end
    else
      -- First time seeing this skill in delays, use remaining time as initial estimate
      if remaining_time > recorded_delay then
        SKILL_DELAY_TABLE_WIN[table_key] = remaining_time
      else
        SKILL_DELAY_TABLE_WIN[table_key] = recorded_delay
      end
    end
    
    -- Store the absolute time when the skill will be ready (future time)
    SKILL_TABLE_WIN[table_key] = current_time + remaining_time
  end
end

function DelaysParser.process(line)
  local found_delay = false
  for k,v in pairs(DELAYS_HOOKS) do
    local delay_match = v:match(line:line())
    if delay_match ~= nil then
      found_delay = true
      local table_key = delay_match[2]
      local time_diff = get_time_diff(delay_match, line:line())
      if SET_VALUE_CONTAINS(DELAYS_REMAP, delay_match[2]) then
        table_key = SET_REVERSE_LOOKUP(DELAYS_REMAP, delay_match[2])
        update_skill_table(table_key, time_diff)
      end
      if SET_VALUE_CONTAINS(DELAYS_REMAP2, delay_match[2]) then
        table_key = SET_REVERSE_LOOKUP(DELAYS_REMAP2, delay_match[2])
        update_skill_table(table_key, time_diff)
      end
      if rematch_caught == nil then
        update_skill_table(table_key, time_diff)
      end
    end
  end
  -- If we found any delays, reset the checked flag (delays exist)
  if found_delay and DELAYS_CHECKED then
    DELAYS_CHECKED = false
  end
  PROMPT_INFO.delays_catch = PROMPT_INFO.delays_catch + 1
  if PROMPT_INFO.delays_catch >= 10 then
    PROMPT_INFO.delays_catch = 0
  end
end

-- Export as global for script.load() compatibility (multiple ways to ensure it's available)
DelaysParser = DelaysParser
_G.DelaysParser = DelaysParser

return DelaysParser

