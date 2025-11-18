-- Room parsing (droid detection and room information)

local RoomParser = {}

function RoomParser.process_droid(line)
  local room_match = PROMPT_INFO.room_match:match(line:line())
  if room_match ~= nil then
    ROOM_TABLE["my_droids"] = {}
    -- Record exit information
    if record_room_entry and room_match[2] then
      local exits_str = room_match[2]
      local exits_info = {}
      -- Parse exits (simple extraction)
      for exit in exits_str:gmatch("[%w]+") do
        exits_info[exit] = true
      end
      record_room_entry(nil, exits_info)
    end
  else
    local droid_match = PROMPT_INFO.droid_match:match(line:line())
    if droid_match ~= nil then
      ADD_TO_SET(ROOM_TABLE["my_droids"],droid_match[2]..droid_match[3])
      -- Record being (droid)
      if record_being then
        record_being(droid_match[2]..droid_match[3])
      end
    end
  end
end

-- Process room description (called from triggers)
function RoomParser.process_room_description(line)
  if record_room_entry then
    local room_desc = line:line()
    -- Strip color codes for cleaner storage
    room_desc = STRIP_COLOR(room_desc)
    record_room_entry(room_desc, nil)
  end
end

-- Process exit usage (called when player moves)
function RoomParser.process_exit(direction)
  if record_exit then
    record_exit(direction)
  end
end

-- Export as global for script.load() compatibility
RoomParser = RoomParser
return RoomParser

