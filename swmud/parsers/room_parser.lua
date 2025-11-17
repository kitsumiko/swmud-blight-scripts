-- Room parsing (droid detection)

local RoomParser = {}

function RoomParser.process_droid(line)
  local room_match = PROMPT_INFO.room_match:match(line:line())
  if room_match ~= nil then
    ROOM_TABLE["my_droids"] = {}
  else
    local droid_match = PROMPT_INFO.droid_match:match(line:line())
    if droid_match ~= nil then
      ADD_TO_SET(ROOM_TABLE["my_droids"],droid_match[2]..droid_match[3])
    end
  end
end

-- Export as global for script.load() compatibility
RoomParser = RoomParser
return RoomParser

