-- Experience tracking service
-- Tracks experience gain over time, calculates rates, estimates leveling time, and tracks milestones

local ExpTracker = {}

-- Initialize experience tracking data
function ExpTracker.init()
  if not EXP_TRACKER_DATA then
    EXP_TRACKER_DATA = {
      session_start_exp = 0,
      session_start_time = os.time(),
      last_exp = 0,
      last_exp_time = os.time(),
      exp_history = {},  -- Array of {exp, timestamp} entries
      milestones = {},   -- Array of {exp, timestamp, description} entries
      leveling_estimates = {},  -- Cache of leveling time estimates per guild
    }
  end
  
  -- Initialize session data if not set
  if EXP_TRACKER_DATA.session_start_exp == 0 then
    local current_exp = 0
    if PROMPT_INFO and PROMPT_INFO.exp then
      current_exp = tonumber(STRIP_COLOR(PROMPT_INFO.exp)) or 0
    end
    EXP_TRACKER_DATA.session_start_exp = current_exp
    EXP_TRACKER_DATA.last_exp = current_exp
    EXP_TRACKER_DATA.session_start_time = os.time()
    EXP_TRACKER_DATA.last_exp_time = os.time()
  end
end

-- Record experience change
function ExpTracker.record_exp_change(new_exp)
  if not EXP_TRACKER_DATA then
    ExpTracker.init()
  end
  
  local current_time = os.time()
  local old_exp = EXP_TRACKER_DATA.last_exp
  local exp_gain = new_exp - old_exp
  
  -- Only record if there's a meaningful change (at least 1 exp)
  if exp_gain > 0 then
    -- Add to history (keep last 100 entries)
    table.insert(EXP_TRACKER_DATA.exp_history, {
      exp = new_exp,
      timestamp = current_time,
      gain = exp_gain
    })
    
    -- Limit history to last 100 entries
    if #EXP_TRACKER_DATA.exp_history > 100 then
      table.remove(EXP_TRACKER_DATA.exp_history, 1)
    end
    
    -- Update last values
    EXP_TRACKER_DATA.last_exp = new_exp
    EXP_TRACKER_DATA.last_exp_time = current_time
  end
end

-- Calculate experience per hour
function ExpTracker.get_exp_per_hour()
  if not EXP_TRACKER_DATA or EXP_TRACKER_DATA.session_start_exp == 0 then
    return 0
  end
  
  local current_exp = tonumber(STRIP_COLOR(PROMPT_INFO.exp)) or 0
  local exp_gained = current_exp - EXP_TRACKER_DATA.session_start_exp
  local time_elapsed = os.difftime(os.time(), EXP_TRACKER_DATA.session_start_time)
  
  if time_elapsed <= 0 then
    return 0
  end
  
  -- Calculate exp per hour
  local exp_per_hour = (exp_gained / time_elapsed) * 3600
  return ROUND_FLOAT(exp_per_hour, 2)
end

-- Calculate experience per minute
function ExpTracker.get_exp_per_minute()
  if not EXP_TRACKER_DATA or EXP_TRACKER_DATA.session_start_exp == 0 then
    return 0
  end
  
  local current_exp = tonumber(STRIP_COLOR(PROMPT_INFO.exp)) or 0
  local exp_gained = current_exp - EXP_TRACKER_DATA.session_start_exp
  local time_elapsed = os.difftime(os.time(), EXP_TRACKER_DATA.session_start_time)
  
  if time_elapsed <= 0 then
    return 0
  end
  
  -- Calculate exp per minute
  local exp_per_minute = (exp_gained / time_elapsed) * 60
  return ROUND_FLOAT(exp_per_minute, 2)
end

-- Estimate time to next level for a guild
function ExpTracker.estimate_time_to_level(guild_name)
  if not LEVEL_TABLE or not SET_CONTAINS(LEVEL_TABLE, guild_name) then
    return nil
  end
  
  local current_level = LEVEL_TABLE[guild_name]
  local current_exp = tonumber(STRIP_COLOR(PROMPT_INFO.exp)) or 0
  local exp_per_hour = ExpTracker.get_exp_per_hour()
  
  if exp_per_hour <= 0 then
    return nil
  end
  
  -- Get exp needed for next level
  local guild_type = ExpTableService.get_guild_type(guild_name)
  local exp_to_next = ExpTableService.get_exp_to_next_level(current_level, current_exp, guild_type)
  
  if not exp_to_next or exp_to_next <= 0 then
    return nil
  end
  
  -- Calculate time in seconds
  local time_seconds = (exp_to_next / exp_per_hour) * 3600
  
  -- Cache the estimate
  EXP_TRACKER_DATA.leveling_estimates[guild_name] = {
    time_seconds = time_seconds,
    timestamp = os.time(),
    exp_to_next = exp_to_next
  }
  
  return time_seconds
end

-- Get formatted time estimate string
function ExpTracker.get_time_estimate_string(guild_name)
  local time_seconds = ExpTracker.estimate_time_to_level(guild_name)
  if not time_seconds then
    return nil
  end
  
  local days = math.floor(time_seconds / 86400)
  local hours = math.floor((time_seconds % 86400) / 3600)
  local minutes = math.floor((time_seconds % 3600) / 60)
  
  local parts = {}
  if days > 0 then
    table.insert(parts, tostring(days) .. "d")
  end
  if hours > 0 then
    table.insert(parts, tostring(hours) .. "h")
  end
  if minutes > 0 or #parts == 0 then
    table.insert(parts, tostring(minutes) .. "m")
  end
  
  return table.concat(parts, " ")
end

-- Record a milestone
function ExpTracker.record_milestone(description)
  if not EXP_TRACKER_DATA then
    ExpTracker.init()
  end
  
  local current_exp = tonumber(STRIP_COLOR(PROMPT_INFO.exp)) or 0
  table.insert(EXP_TRACKER_DATA.milestones, {
    exp = current_exp,
    timestamp = os.time(),
    description = description or "Milestone"
  })
  
  -- Keep last 50 milestones
  if #EXP_TRACKER_DATA.milestones > 50 then
    table.remove(EXP_TRACKER_DATA.milestones, 1)
  end
end

-- Get session statistics
function ExpTracker.get_session_stats()
  if not EXP_TRACKER_DATA or EXP_TRACKER_DATA.session_start_exp == 0 then
    return nil
  end
  
  local current_exp = tonumber(STRIP_COLOR(PROMPT_INFO.exp)) or 0
  local exp_gained = current_exp - EXP_TRACKER_DATA.session_start_exp
  local time_elapsed = os.difftime(os.time(), EXP_TRACKER_DATA.session_start_time)
  local exp_per_hour = ExpTracker.get_exp_per_hour()
  local exp_per_minute = ExpTracker.get_exp_per_minute()
  
  return {
    session_start_exp = EXP_TRACKER_DATA.session_start_exp,
    current_exp = current_exp,
    exp_gained = exp_gained,
    time_elapsed = time_elapsed,
    exp_per_hour = exp_per_hour,
    exp_per_minute = exp_per_minute,
    history_count = #EXP_TRACKER_DATA.exp_history,
    milestone_count = #EXP_TRACKER_DATA.milestones
  }
end

-- Display experience statistics
function ExpTracker.display_stats()
  local stats = ExpTracker.get_session_stats()
  if not stats then
    blight.output(C_BYELLOW .. "Experience tracking not initialized. Run 'score' to start tracking." .. C_RESET)
    return
  end
  
  blight.output(C_BYELLOW .. "####### Experience Statistics #######" .. C_RESET)
  blight.output(C_BWHITE .. "Session Start: " .. C_RESET .. os.date("%c", EXP_TRACKER_DATA.session_start_time))
  blight.output(C_BWHITE .. "Session Duration: " .. C_RESET .. os.date("!%H:%M:%S", stats.time_elapsed))
  blight.output()
  blight.output(C_BWHITE .. "Experience:" .. C_RESET)
  blight.output("  Start: " .. tostring(stats.session_start_exp))
  blight.output("  Current: " .. tostring(stats.current_exp))
  blight.output("  Gained: " .. C_BGREEN .. tostring(stats.exp_gained) .. C_RESET)
  blight.output()
  blight.output(C_BWHITE .. "Rates:" .. C_RESET)
  blight.output("  Per Hour: " .. C_BGREEN .. tostring(stats.exp_per_hour) .. C_RESET)
  blight.output("  Per Minute: " .. C_BGREEN .. tostring(stats.exp_per_minute) .. C_RESET)
  blight.output()
  
  -- Show leveling estimates for primary guild
  if CHAR_DATA.prime_guild and SET_CONTAINS(LEVEL_TABLE, CHAR_DATA.prime_guild) then
    local time_est = ExpTracker.get_time_estimate_string(CHAR_DATA.prime_guild)
    if time_est then
      blight.output(C_BWHITE .. "Time to Next Level (" .. CHAR_DATA.prime_guild .. "): " .. C_RESET .. C_BYELLOW .. time_est .. C_RESET)
    end
  end
  
  blight.output()
  blight.output(C_BWHITE .. "History: " .. C_RESET .. tostring(stats.history_count) .. " entries")
  blight.output(C_BWHITE .. "Milestones: " .. C_RESET .. tostring(stats.milestone_count))
  blight.output()
end

-- Reset session tracking
function ExpTracker.reset_session()
  local current_exp = tonumber(STRIP_COLOR(PROMPT_INFO.exp)) or 0
  EXP_TRACKER_DATA.session_start_exp = current_exp
  EXP_TRACKER_DATA.last_exp = current_exp
  EXP_TRACKER_DATA.session_start_time = os.time()
  EXP_TRACKER_DATA.last_exp_time = os.time()
  blight.output(C_BGREEN .. "Experience tracking session reset." .. C_RESET)
end

-- Initialize on load
ExpTracker.init()

-- Export as globals
record_exp_change = ExpTracker.record_exp_change
get_exp_per_hour = ExpTracker.get_exp_per_hour
get_exp_per_minute = ExpTracker.get_exp_per_minute
estimate_time_to_level = ExpTracker.estimate_time_to_level
get_time_estimate_string = ExpTracker.get_time_estimate_string
record_milestone = ExpTracker.record_milestone
get_session_stats = ExpTracker.get_session_stats
display_exp_stats = ExpTracker.display_stats
reset_exp_session = ExpTracker.reset_session

ExpTracker = ExpTracker

return ExpTracker

