-- Experience table service
-- Handles loading and querying the experience table

local ExpTableService = {}

-- Guild type mapping
-- Jedi guilds use Jedi exp requirements
-- All other guilds use Primary or Secondary based on their position
local JEDI_GUILDS = {
  ["Jedi"] = true,
}

-- Load experience table from file
function ExpTableService.load_exp_table(file_path)
  local exp_table = {}
  local file = io.open(file_path, "r")
  
  if file == nil then
    blight.output("Error: could not open exp table file: " .. file_path)
    return exp_table
  end
  
  local data = file:read("*all")
  file:close()
  
  local lines = {}
  for line in data:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  
  -- Parse the table (skip header lines 1-2, parse data lines 3-52, skip total line 53)
  for i = 3, 52 do
    if lines[i] then
      -- Parse line: "  X |      YYYY  |      ZZZZ  |      WWWW"
      local parts = {}
      for part in lines[i]:gmatch("[^|]+") do
        local trimmed = TRIM_STRING(part)
        table.insert(parts, trimmed)
      end
      
      if #parts >= 4 then
        local level = tonumber(parts[1])
        local primary = tonumber(parts[2])
        local secondary = tonumber(parts[3])
        local jedi = tonumber(parts[4])
        
        if level and primary and secondary and jedi then
          exp_table[level] = {
            primary = primary,
            secondary = secondary,
            jedi = jedi
          }
        end
      end
    end
  end
  
  return exp_table
end

-- Determine guild type (primary, secondary, or jedi)
function ExpTableService.get_guild_type(guild_name)
  if JEDI_GUILDS[guild_name] then
    return "jedi"
  end
  -- For now, we'll determine primary vs secondary based on LEVEL_TABLE
  -- Primary guild is the one with highest level, or the one in CHAR_DATA.prime_guild
  if guild_name == CHAR_DATA.prime_guild then
    return "primary"
  else
    return "secondary"
  end
end

-- Get exp required for a specific level and guild type
function ExpTableService.get_exp_for_level(level, guild_type)
  if not EXP_TABLE_DATA or not EXP_TABLE_DATA[level] then
    return nil
  end
  
  guild_type = guild_type or "primary"
  return EXP_TABLE_DATA[level][guild_type]
end

-- Get exp required for next level
function ExpTableService.get_exp_for_next_level(current_level, guild_type)
  local next_level = current_level + 1
  -- Max level is 50
  if next_level > 50 then
    return nil
  end
  return ExpTableService.get_exp_for_level(next_level, guild_type)
end

-- Calculate exp to next level
function ExpTableService.get_exp_to_next_level(current_level, current_exp, guild_type)
  local exp_needed = ExpTableService.get_exp_for_next_level(current_level, guild_type)
  if not exp_needed then
    return nil
  end
  
  local exp_to_next = exp_needed - current_exp
  return exp_to_next
end

-- Calculate exp over if ready to level
function ExpTableService.get_exp_over(current_level, current_exp, guild_type)
  local exp_for_next = ExpTableService.get_exp_for_next_level(current_level, guild_type)
  if not exp_for_next then
    return nil
  end
  
  if current_exp >= exp_for_next then
    local exp_over = current_exp - exp_for_next
    return exp_over
  end
  
  return 0
end

-- Get formatted exp display string for UI
function ExpTableService.format_exp_display(current_level, current_exp, guild_name)
  if not current_level or not current_exp or current_level <= 0 then
    return nil
  end
  
  local guild_type = ExpTableService.get_guild_type(guild_name)
  local exp_to_next = ExpTableService.get_exp_to_next_level(current_level, current_exp, guild_type)
  local exp_over = ExpTableService.get_exp_over(current_level, current_exp, guild_type)
  
  if exp_to_next == nil then
    return nil
  end
  
  local display = ""
  
  if exp_over and exp_over > 0 then
    -- Ready to level - show exp over
    display = display .. C_BGREEN .. "+" .. tostring(exp_over) .. C_RESET
  else
    -- Not ready - show exp to next level
    local exp_needed = ExpTableService.get_exp_for_next_level(current_level, guild_type)
    if exp_needed then
      local exp_ratio = current_exp / exp_needed
      if exp_ratio > 1 then exp_ratio = 1 end
      if exp_ratio < 0 then exp_ratio = 0 end
      display = display .. GET_COLOR(exp_ratio) .. tostring(exp_to_next) .. C_RESET
    else
      display = display .. tostring(exp_to_next)
    end
  end
  
  return display
end

-- Export as globals for backward compatibility
get_exp_for_level = ExpTableService.get_exp_for_level
get_exp_for_next_level = ExpTableService.get_exp_for_next_level
get_exp_to_next_level = ExpTableService.get_exp_to_next_level
get_exp_over = ExpTableService.get_exp_over
format_exp_display = ExpTableService.format_exp_display

return ExpTableService

