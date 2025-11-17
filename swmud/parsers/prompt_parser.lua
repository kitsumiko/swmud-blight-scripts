-- Prompt parsing

local PromptParser = {}

function PromptParser.parse(matches)
  if matches and TABLE_LENGTH(matches) == 11 then
    return {
      hp = matches[2],
      hp_max = matches[3],
      exp = matches[4],
      credits = matches[5],
      align_team = matches[6],
      align_jedi = matches[7],
      wimpy = matches[8],
      sp = matches[9],
      sp_max = matches[10],
      drug = matches[11],
    }
  end
  return nil
end

return PromptParser

