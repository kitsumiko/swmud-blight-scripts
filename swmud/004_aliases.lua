-- simplification functions
function create_alias(a_in, a_out)
  alias.add(a_in, function (m)
    GLOBAL_SEND(a_out)
    end)
end

function create_standard_alias(a_in, a_out)
  create_alias("^" .. a_in .. "$", a_out)
end

function create_sub_alias(a_in, a_out)
  create_standard_alias(a_in, a_out)
  alias.add("^" .. a_in .. " (.*)$", function (m)
    if m ~= nil then
      GLOBAL_SEND(a_out .. " "..m[2])
    end
  end)
end

function create_nested_alias(a_in, a_out, a_last)
  alias.add("^" .. a_in .. " (.*)$", function (m)
    if m ~= nil then
      GLOBAL_SEND(a_out .. " "..m[2] .. a_last)
    end
  end)
end

function create_target_alias(a_in, a_out)
  alias.add("^" .. a_in .. " (.*)$", function (m)
    if m ~= nil and m[2]~= "" then
      GLOBAL_SEND(a_out .. " " .. m[2])
    end
  end)
  alias.add("^" .. a_in .. "$", function (m)
    if TARGET_INFO.last_target=="None" then
      GLOBAL_SEND(a_out)
    else
      GLOBAL_SEND(a_out .. " " .. TARGET_INFO.last_target)
    end
  end)
end

-- move aliases (sneak, ride, etc...)
function create_move_alias(a_in)
  alias.add("^" .. a_in .. "$", function (m)
    if PROMPT_INFO.move_cmd == "" then
      GLOBAL_SEND(a_in, true)
    else
      GLOBAL_SEND(tostring(PROMPT_INFO.move_cmd) .. " " .. a_in)
    end
  end)
end

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

for k,v in pairs(PROMPT_INFO.move_commands) do
  create_move_alias(v)
end

create_alias("^reprompt$", "prompt 2 5 6 9 12 4 11")