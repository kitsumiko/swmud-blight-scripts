-- Score command parsing

local ScoreParser = {}

function ScoreParser.process(line)
  local line_text = line:line()
  
  -- Process level lines (e.g., "Jedi         : 30")
  local score_matches = PROMPT_INFO.level_regexp:match_all(line_text)
  if score_matches ~= nil then
    for s_ind, cur_match in pairs(score_matches) do
      -- cur_match[1] is the guild name, cur_match[2] is the level
      local guild_name = TRIM_STRING(cur_match[1])
      local level = tonumber(cur_match[2])
      
      -- Check if it's a valid guild or "High Mortal"
      local is_valid_guild = SET(PROMPT_INFO.guilds)[guild_name] or guild_name == "High Mortal"
      
      if is_valid_guild then
        if level and level > 0 then
          LEVEL_TABLE[guild_name] = level
          if LOG_DEBUG then
            LOG_DEBUG("ScoreParser: Set " .. guild_name .. " = " .. tostring(level))
          end
        else
          if SET_VALUE_CONTAINS(LEVEL_TABLE, guild_name) then
            REMOVE_FROM_SET(LEVEL_TABLE, guild_name)
          end
        end
      end
    end
  end
  
  -- Process primary guild line (e.g., "Levels:  (Primary Guild: Slicer)")
  local guild_matches = PROMPT_INFO.primary_guild_regexp:match(line_text)
  if guild_matches ~= nil then
    -- The regex now captures the guild name directly in group 1
    CHAR_DATA.prime_guild = TRIM_STRING(guild_matches[1])
    if LOG_DEBUG then
      LOG_DEBUG("ScoreParser: Set prime_guild = " .. CHAR_DATA.prime_guild)
    end
  end
  
  -- Process character name line (e.g., "You are: Miko the Mistress of Cyberspace")
  local char_matches = PROMPT_INFO.char_regexp:match(line_text)
  if char_matches ~= nil then
    -- The regex now captures the full name in group 1
    CHAR_DATA.character_name = TRIM_STRING(char_matches[1])
    if LOG_DEBUG then
      LOG_DEBUG("ScoreParser: Set character_name = " .. CHAR_DATA.character_name)
    end
  end
  
  PROMPT_INFO.score_catch = PROMPT_INFO.score_catch + 1
  if PROMPT_INFO.score_catch >= 20 then
    PROMPT_INFO.score_catch = 0
  end
end

-- Export as global for script.load() compatibility
ScoreParser = ScoreParser
return ScoreParser

