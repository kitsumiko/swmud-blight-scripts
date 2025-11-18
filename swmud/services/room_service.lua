-- Room information enhancement service
-- Tracks room history, exits, beings, and provides room-based automation

local RoomService = {}

-- Initialize room tracking data
function RoomService.init()
  if not ROOM_TRACKER_DATA then
    ROOM_TRACKER_DATA = {
      current_room = nil,
      room_history = {},  -- Array of {room_id, timestamp, description} entries
      room_database = {},  -- Map of room_id -> room_info
      exit_history = {},  -- Track exit usage
      being_history = {},  -- Track beings seen in rooms
      room_visit_count = {},  -- Count visits per room
      last_room_change_time = os.time(),
    }
  end
end

-- Record room entry/change
function RoomService.record_room_entry(room_description, exits_info)
  if not ROOM_TRACKER_DATA then
    RoomService.init()
  end
  
  local current_time = os.time()
  local room_id = RoomService.generate_room_id(room_description)
  
  -- Check if this is a new room or same room
  if ROOM_TRACKER_DATA.current_room ~= room_id then
    -- New room
    ROOM_TRACKER_DATA.last_room_change_time = current_time
    ROOM_TRACKER_DATA.current_room = room_id
    
    -- Add to history
    table.insert(ROOM_TRACKER_DATA.room_history, {
      room_id = room_id,
      timestamp = current_time,
      description = room_description or "Unknown room"
    })
    
    -- Limit history to last 200 entries
    if #ROOM_TRACKER_DATA.room_history > 200 then
      table.remove(ROOM_TRACKER_DATA.room_history, 1)
    end
    
    -- Update visit count
    if not ROOM_TRACKER_DATA.room_visit_count[room_id] then
      ROOM_TRACKER_DATA.room_visit_count[room_id] = 0
    end
    ROOM_TRACKER_DATA.room_visit_count[room_id] = ROOM_TRACKER_DATA.room_visit_count[room_id] + 1
    
    -- Store room info
    if not ROOM_TRACKER_DATA.room_database[room_id] then
      ROOM_TRACKER_DATA.room_database[room_id] = {
        description = room_description or "Unknown room",
        first_seen = current_time,
        last_seen = current_time,
        visit_count = 1,
        exits = exits_info or {},
        beings_seen = {},
      }
    else
      ROOM_TRACKER_DATA.room_database[room_id].last_seen = current_time
      ROOM_TRACKER_DATA.room_database[room_id].visit_count = ROOM_TRACKER_DATA.room_visit_count[room_id]
      if exits_info then
        -- Merge exits info
        for k, v in pairs(exits_info) do
          ROOM_TRACKER_DATA.room_database[room_id].exits[k] = v
        end
      end
    end
  else
    -- Same room, just update last seen
    if ROOM_TRACKER_DATA.room_database[room_id] then
      ROOM_TRACKER_DATA.room_database[room_id].last_seen = current_time
    end
  end
end

-- Generate a simple room ID from description
function RoomService.generate_room_id(description)
  if not description or description == "" then
    return "unknown_" .. tostring(os.time())
  end
  
  -- Use first 50 characters as ID (simple hash)
  local id = string.sub(description, 1, 50)
  -- Remove color codes for consistent IDs
  id = STRIP_COLOR(id)
  return id
end

-- Record exit usage
function RoomService.record_exit(direction)
  if not ROOM_TRACKER_DATA then
    RoomService.init()
  end
  
  local current_time = os.time()
  table.insert(ROOM_TRACKER_DATA.exit_history, {
    direction = direction,
    timestamp = current_time,
    from_room = ROOM_TRACKER_DATA.current_room
  })
  
  -- Limit exit history to last 500 entries
  if #ROOM_TRACKER_DATA.exit_history > 500 then
    table.remove(ROOM_TRACKER_DATA.exit_history, 1)
  end
end

-- Record being seen in room
function RoomService.record_being(being_name, room_id)
  if not ROOM_TRACKER_DATA then
    RoomService.init()
  end
  
  room_id = room_id or ROOM_TRACKER_DATA.current_room
  if not room_id then
    return
  end
  
  local current_time = os.time()
  
  -- Add to being history
  table.insert(ROOM_TRACKER_DATA.being_history, {
    being = being_name,
    room_id = room_id,
    timestamp = current_time
  })
  
  -- Limit being history to last 200 entries
  if #ROOM_TRACKER_DATA.being_history > 200 then
    table.remove(ROOM_TRACKER_DATA.being_history, 1)
  end
  
  -- Store in room database
  if ROOM_TRACKER_DATA.room_database[room_id] then
    if not ROOM_TRACKER_DATA.room_database[room_id].beings_seen[being_name] then
      ROOM_TRACKER_DATA.room_database[room_id].beings_seen[being_name] = {
        first_seen = current_time,
        last_seen = current_time,
        count = 1
      }
    else
      ROOM_TRACKER_DATA.room_database[room_id].beings_seen[being_name].last_seen = current_time
      ROOM_TRACKER_DATA.room_database[room_id].beings_seen[being_name].count = 
        ROOM_TRACKER_DATA.room_database[room_id].beings_seen[being_name].count + 1
    end
  end
end

-- Get current room info
function RoomService.get_current_room_info()
  if not ROOM_TRACKER_DATA or not ROOM_TRACKER_DATA.current_room then
    return nil
  end
  
  return ROOM_TRACKER_DATA.room_database[ROOM_TRACKER_DATA.current_room]
end

-- Get room statistics
function RoomService.get_room_stats()
  if not ROOM_TRACKER_DATA then
    return nil
  end
  
  local total_rooms = 0
  local total_visits = 0
  for k, v in pairs(ROOM_TRACKER_DATA.room_database) do
    total_rooms = total_rooms + 1
    total_visits = total_visits + v.visit_count
  end
  
  return {
    total_rooms = total_rooms,
    total_visits = total_visits,
    history_count = #ROOM_TRACKER_DATA.room_history,
    exit_count = #ROOM_TRACKER_DATA.exit_history,
    being_count = #ROOM_TRACKER_DATA.being_history,
    current_room = ROOM_TRACKER_DATA.current_room
  }
end

-- Display room information
function RoomService.display_current_room()
  local room_info = RoomService.get_current_room_info()
  if not room_info then
    blight.output(C_BYELLOW .. "No room information available." .. C_RESET)
    return
  end
  
  blight.output(C_BYELLOW .. "####### Current Room Information #######" .. C_RESET)
  blight.output(C_BWHITE .. "Description: " .. C_RESET .. room_info.description)
  blight.output(C_BWHITE .. "First Seen: " .. C_RESET .. os.date("%c", room_info.first_seen))
  blight.output(C_BWHITE .. "Last Seen: " .. C_RESET .. os.date("%c", room_info.last_seen))
  blight.output(C_BWHITE .. "Visit Count: " .. C_RESET .. tostring(room_info.visit_count))
  
  if next(room_info.exits) then
    blight.output(C_BWHITE .. "Exits: " .. C_RESET)
    for k, v in pairs(room_info.exits) do
      blight.output("  " .. k .. ": " .. tostring(v))
    end
  end
  
  local being_count = 0
  for k, v in pairs(room_info.beings_seen) do
    being_count = being_count + 1
  end
  
  if being_count > 0 then
    blight.output(C_BWHITE .. "Beings Seen (" .. tostring(being_count) .. "): " .. C_RESET)
    local count = 0
    for k, v in pairs(room_info.beings_seen) do
      if count < 10 then  -- Show first 10
        blight.output("  " .. k .. " (seen " .. tostring(v.count) .. " times)")
        count = count + 1
      end
    end
    if count >= 10 then
      blight.output("  ... and more")
    end
  end
  
  blight.output()
end

-- Display room statistics
function RoomService.display_stats()
  local stats = RoomService.get_room_stats()
  if not stats then
    blight.output(C_BYELLOW .. "Room tracking not initialized." .. C_RESET)
    return
  end
  
  blight.output(C_BYELLOW .. "####### Room Statistics #######" .. C_RESET)
  blight.output(C_BWHITE .. "Total Rooms Visited: " .. C_RESET .. tostring(stats.total_rooms))
  blight.output(C_BWHITE .. "Total Visits: " .. C_RESET .. tostring(stats.total_visits))
  blight.output(C_BWHITE .. "Room History Entries: " .. C_RESET .. tostring(stats.history_count))
  blight.output(C_BWHITE .. "Exit History Entries: " .. C_RESET .. tostring(stats.exit_count))
  blight.output(C_BWHITE .. "Being History Entries: " .. C_RESET .. tostring(stats.being_count))
  
  if stats.current_room then
    blight.output(C_BWHITE .. "Current Room ID: " .. C_RESET .. string.sub(stats.current_room, 1, 50))
  end
  
  blight.output()
end

-- Display recent room history
function RoomService.display_history(count)
  if not ROOM_TRACKER_DATA then
    blight.output(C_BYELLOW .. "Room tracking not initialized." .. C_RESET)
    return
  end
  
  count = count or 10
  local history = ROOM_TRACKER_DATA.room_history
  local start_idx = math.max(1, #history - count + 1)
  
  blight.output(C_BYELLOW .. "####### Recent Room History #######" .. C_RESET)
  
  if #history == 0 then
    blight.output("No room history available.")
  else
    for i = #history, start_idx, -1 do
      local entry = history[i]
      local time_str = os.date("%H:%M:%S", entry.timestamp)
      blight.output(C_BWHITE .. "[" .. time_str .. "] " .. C_RESET .. string.sub(entry.description, 1, 60))
    end
  end
  
  blight.output()
end

-- Reset room tracking
function RoomService.reset()
  ROOM_TRACKER_DATA = {
    current_room = nil,
    room_history = {},
    room_database = {},
    exit_history = {},
    being_history = {},
    room_visit_count = {},
    last_room_change_time = os.time(),
  }
  blight.output(C_BGREEN .. "Room tracking reset." .. C_RESET)
end

-- Initialize on load
RoomService.init()

-- Export as globals
record_room_entry = RoomService.record_room_entry
record_exit = RoomService.record_exit
record_being = RoomService.record_being
get_current_room_info = RoomService.get_current_room_info
get_room_stats = RoomService.get_room_stats
display_current_room = RoomService.display_current_room
display_room_stats = RoomService.display_stats
display_room_history = RoomService.display_history
reset_room_tracking = RoomService.reset

RoomService = RoomService

return RoomService

