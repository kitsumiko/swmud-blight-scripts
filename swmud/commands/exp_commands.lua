-- Experience tracking commands

-- Display experience statistics
alias.add("^expstats$", function()
  if display_exp_stats then
    display_exp_stats()
  else
    blight.output(C_BRED .. "Experience tracking not available. Run /reload to load modules." .. C_RESET)
  end
end)

-- Reset experience session
alias.add("^expreset$", function()
  if reset_exp_session then
    reset_exp_session()
  else
    blight.output(C_BRED .. "Experience tracking not available. Run /reload to load modules." .. C_RESET)
  end
end)

-- Record milestone
alias.add("^milestone(.*)$", function(m)
  if record_milestone then
    local description = TRIM_STRING(m[2] or "")
    if description == "" then
      description = "Milestone"
    end
    record_milestone(description)
    blight.output(C_BGREEN .. "Milestone recorded: " .. description .. C_RESET)
  else
    blight.output(C_BRED .. "Experience tracking not available. Run /reload to load modules." .. C_RESET)
  end
end)

