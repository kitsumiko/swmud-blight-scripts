-- Alias definitions and setup

-- Move command alias
alias.add("^set_move(.*)$", function (m)
  if m ~= nil then
    PROMPT_INFO.move_cmd = TRIM_STRING(tostring(m[2]))
    if m[2] == "" then
      blight.output(C_BYELLOW .. "Removed move prepend.")
    else
      blight.output(C_BYELLOW .. "Set move prepend: " .. PROMPT_INFO.move_cmd .. " (example:" .. PROMPT_INFO.move_cmd .. " south)")
    end
  else
    PROMPT_INFO.move_cmd = ""
    blight.output(C_BYELLOW .. "Removed move prepend.")
  end
end)

-- Create move aliases for all move commands
for k,v in pairs(PROMPT_INFO.move_commands) do
  create_move_alias(v)
end

-- Reprompt alias
create_alias("^reprompt$", "prompt 2 5 6 9 12 4 11")

