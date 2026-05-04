-- Room parsing (droid detection and room information)

local RoomParser = {}

-- Droid type prefixes (must mirror the alternation in PROMPT_INFO.droid_match
-- defined in core/state.lua). Used to filter follow/summon events so non-droid
-- names never get added to ROOM_TABLE["my_droids"].
local DROID_PREFIXES = {
  "C3","T5","SLR","GNK","B1","RX","G2","MLR","R4P","NR","FX","IF",
  "IG","RA","XLR","BLX","T7","C5","S9E","B2","DD","ALR","MSE","OOM",
  "R8","2-1C","HK","FA-5","X7",
}

local function get_droid_prefix(name)
  if not name then return nil end
  for _, prefix in ipairs(DROID_PREFIXES) do
    if name:sub(1, #prefix) == prefix then
      return prefix
    end
  end
  return nil
end

local function add_if_droid(name)
  if get_droid_prefix(name) then
    if not ROOM_TABLE["my_droids"] then ROOM_TABLE["my_droids"] = {} end
    ADD_TO_SET(ROOM_TABLE["my_droids"], name)
    -- Mirror into the per-room set: follow/summon events imply the droid is
    -- here with us right now.
    if not ROOM_TABLE["current_room_droids"] then ROOM_TABLE["current_room_droids"] = {} end
    ADD_TO_SET(ROOM_TABLE["current_room_droids"], name)
  end
end

local function remove_droid(name)
  if ROOM_TABLE["my_droids"] then ROOM_TABLE["my_droids"][name] = nil end
  if ROOM_TABLE["droid_status"] then ROOM_TABLE["droid_status"][name] = nil end
  if ROOM_TABLE["current_room_droids"] then ROOM_TABLE["current_room_droids"][name] = nil end
end

-- Public hook: clear the per-room droid set. Called when the player moves
-- (record_exit) or when a new room display starts, so dreg/aliases that act
-- on "droids in this room" don't see stragglers from a previous room.
function RoomParser.reset_current_room_droids()
  ROOM_TABLE["current_room_droids"] = {}
end

function RoomParser.process_droid(line)
  -- blight.output("[DROID_PARSER] process_droid called with line: '" .. line:line() .. "'")
  local room_match = PROMPT_INFO.room_match:match(line:line())
  if room_match ~= nil then
    -- Note: we intentionally do NOT clear ROOM_TABLE["my_droids"] here.
    -- Droids that belong to us follow us across rooms, so wiping the set on
    -- every room change makes the alias check unreliable. We rely on the
    -- "You have lost X." event below to remove droids that leave us.
    -- However, we DO reset the per-room droid set here: this MUD prints the
    -- exits line BEFORE the room contents, so any droid line that follows
    -- will repopulate it for the new room.
    RoomParser.reset_current_room_droids()
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
      -- Also track this droid as physically present in the current room. This
      -- set is reset on movement / new room display, so dreg can register only
      -- the droids actually here with us.
      if not ROOM_TABLE["current_room_droids"] then
        ROOM_TABLE["current_room_droids"] = {}
      end
      ADD_TO_SET(ROOM_TABLE["current_room_droids"], droid_name)
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

    -- Droid ownership events. Only match signals that confirm (or strongly
    -- imply) the droid is OURS. We deliberately do NOT match "X enters."
    -- because that fires for any droid walking into the room, including
    -- droids owned by other players.
    local function try_event(text)
      local n
      -- Unique to our droids responding to our `droids summon` command:
      n = text:match("^(%S+) zips into the room and beeps to inform you of its presence%.$")
      if n then add_if_droid(n); return true end
      -- Our droid starts following us (filtered by droid prefix in add_if_droid):
      n = text:match("^(%S+) is now following you%.$")
      if n then add_if_droid(n); return true end
      -- Removal: lost the droid (destroyed, dismissed, out of range, etc.)
      n = text:match("^You have lost (%S+)%.$")
      if n then remove_droid(n); return true end
      return false
    end
    if not try_event(line_text) then
      try_event(raw_text)
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

