-- Room parsing (droid detection and room information)

local RoomParser = {}

function RoomParser.process_droid(line)
  -- blight.output("[DROID_PARSER] process_droid called with line: '" .. line:line() .. "'")
  local room_match = PROMPT_INFO.room_match:match(line:line())
  if room_match ~= nil then
    -- blight.output("[DROID_PARSER] Room match found, clearing droids")
    ROOM_TABLE["my_droids"] = {}
    ROOM_TABLE["droid_status"] = {}
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
    -- Try both line() and raw() to catch droids - raw() may have color codes that affect matching
    local line_text = line:line()
    local raw_text = line:raw()
    local droid_match = PROMPT_INFO.droid_match:match(line_text)
    if droid_match == nil then
      droid_match = PROMPT_INFO.droid_match:match(raw_text)
    end
    if droid_match ~= nil then
      -- droid_match structure:
      -- [1] = full match
      -- [2] = droid type prefix (e.g., "HK", "T5", "C3")
      -- [3] = droid suffix (e.g., "-89K", "XU9", "P0")
      -- [4] = space + status (e.g., " (Yours)" or " [Listening]")
      -- [5] = status text (e.g., "(Yours)" or "[Listening]")
      local droid_name = droid_match[2]..droid_match[3]
      -- blight.output("[DROID_PARSER] Matched droid: '" .. droid_name .. "' from line: '" .. line_text .. "'")
      -- blight.output("[DROID_PARSER] Match groups: [2]='" .. tostring(droid_match[2]) .. "', [3]='" .. tostring(droid_match[3]) .. "', [5]='" .. tostring(droid_match[5]) .. "'")
      ADD_TO_SET(ROOM_TABLE["my_droids"], droid_name)
      -- Store droid status (Yours or Listening) for registration checking
      if not ROOM_TABLE["droid_status"] then
        ROOM_TABLE["droid_status"] = {}
      end
      -- droid_match[5] contains "(Yours)" or "[Listening]"
      if droid_match[5] then
        if string.find(droid_match[5], "Listening") then
          ROOM_TABLE["droid_status"][droid_name] = "Listening"
        else
          ROOM_TABLE["droid_status"][droid_name] = "Yours"
        end
      end
      -- Record being (droid)
      if record_being then
        record_being(droid_name)
      end
    -- else
    --   -- Log lines that look like droids but didn't match
    --   if string.find(line_text, "HK") or string.find(line_text, "T5") or string.find(line_text, "C3") or string.find(line_text, "Yours") or string.find(line_text, "Listening") then
    --     blight.output("[DROID_PARSER] No match for line: '" .. line_text .. "' (raw: '" .. raw_text .. "')")
    --   end
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

-- Export as global for script.load() compatibility (multiple ways to ensure it's available)
RoomParser = RoomParser
_G.RoomParser = RoomParser
return RoomParser

