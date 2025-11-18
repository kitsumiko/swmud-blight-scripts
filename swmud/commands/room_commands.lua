-- Room information commands

-- Display current room information
alias.add("^room$", function()
  if display_current_room then
    display_current_room()
  else
    blight.output(C_BRED .. "Room tracking not available. Run /reload to load modules." .. C_RESET)
  end
end)

-- Display room statistics
alias.add("^roomstats$", function()
  if display_room_stats then
    display_room_stats()
  else
    blight.output(C_BRED .. "Room tracking not available. Run /reload to load modules." .. C_RESET)
  end
end)

-- Display room history
alias.add("^roomhistory(.*)$", function(m)
  if display_room_history then
    local count_str = TRIM_STRING(m[2] or "")
    local count = 10
    if count_str ~= "" then
      count = tonumber(count_str) or 10
    end
    display_room_history(count)
  else
    blight.output(C_BRED .. "Room tracking not available. Run /reload to load modules." .. C_RESET)
  end
end)

-- Reset room tracking
alias.add("^roomreset$", function()
  if reset_room_tracking then
    reset_room_tracking()
  else
    blight.output(C_BRED .. "Room tracking not available. Run /reload to load modules." .. C_RESET)
  end
end)

