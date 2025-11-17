-- Score command parsing

local ScoreParser = {}

function ScoreParser.process(line)
  local score_matches = PROMPT_INFO.level_regexp:match_all(line:line())
  if score_matches ~= nil then
    for s_ind, cur_match in pairs(score_matches) do
      -- cur_match[1] is the guild name, cur_match[2] is the level
      local guild_name = TRIM_STRING(cur_match[1])
      if SET(PROMPT_INFO.guilds)[guild_name] then
        local level = tonumber(cur_match[2])
        if level and level > 0 then
          LEVEL_TABLE[guild_name] = level
        else
          if SET_VALUE_CONTAINS(LEVEL_TABLE, guild_name) then
            REMOVE_FROM_SET(LEVEL_TABLE, guild_name)
          end
        end
      end
    end
  end
  local guild_matches = PROMPT_INFO.primary_guild_regexp:match(line:line())
  if guild_matches ~= nil then
    -- The regex now captures the guild name directly in group 1
    CHAR_DATA.prime_guild = TRIM_STRING(guild_matches[1])
  end
  local char_matches = PROMPT_INFO.char_regexp:match(line:line())
  if char_matches ~= nil then
    -- The regex now captures the full name in group 1
    CHAR_DATA.character_name = TRIM_STRING(char_matches[1])
  end
  PROMPT_INFO.score_catch = PROMPT_INFO.score_catch + 1
  if PROMPT_INFO.score_catch >= 20 then
    PROMPT_INFO.score_catch = 0
  end
end

-- Export as global for script.load() compatibility
ScoreParser = ScoreParser
return ScoreParser

