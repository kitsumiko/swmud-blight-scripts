-- Alias creation factory functions

local AliasFactory = {}

function AliasFactory.create(a_in, a_out)
  alias.add(a_in, function (m)
    GLOBAL_SEND(a_out)
  end)
end

function AliasFactory.create_standard(a_in, a_out)
  AliasFactory.create("^" .. a_in .. "$", a_out)
end

function AliasFactory.create_sub(a_in, a_out)
  AliasFactory.create_standard(a_in, a_out)
  alias.add("^" .. a_in .. " (.*)$", function (m)
    if m ~= nil then
      GLOBAL_SEND(a_out .. " "..m[2])
    end
  end)
end

function AliasFactory.create_nested(a_in, a_out, a_last)
  alias.add("^" .. a_in .. " (.*)$", function (m)
    if m ~= nil then
      GLOBAL_SEND(a_out .. " "..m[2] .. a_last)
    end
  end)
end

function AliasFactory.create_target(a_in, a_out)
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

function AliasFactory.create_move(a_in)
  alias.add("^" .. a_in .. "$", function (m)
    -- Record exit usage for room tracking
    if record_exit then
      record_exit(a_in)
    end
    
    if PROMPT_INFO.move_cmd == "" then
      GLOBAL_SEND(a_in, true)
    else
      GLOBAL_SEND(tostring(PROMPT_INFO.move_cmd) .. " " .. a_in)
    end
  end)
end

function AliasFactory.create_chat(a_in, a_out, decoration)
  alias.add("^" .. a_in .. " (.*)$", function (m)
    if m ~= nil then
      mud.send(a_out .. " " .. decoration .. " " .. m[2], {gag=1,})
      emote_matches = PROMPT_INFO.emote_regexp:match(a_in)
      if emote_matches ~= nil then
        mud.send(a_out .. m[2], {gag=1,})
      else
        mud.send(a_out .. " " .. decoration .. " " .. m[2], {gag=1,})
      end
      PROMPT_INFO.save_raw_command = 0
    end
  end)
end

function AliasFactory.create_tell(a_in, a_out, decoration)
  alias.add("^" .. a_in .. " ([a-zA-Z,]*) (.*)$", function (m)
    if m ~= nil then
      mud.send(a_out .. " " .. m[2] .. " " .. decoration .. " " .. m[3], {gag=1,})
      PROMPT_INFO.save_raw_command = 0
    end
  end)
end

-- Export as globals for backward compatibility
create_alias = AliasFactory.create
create_standard_alias = AliasFactory.create_standard
create_sub_alias = AliasFactory.create_sub
create_nested_alias = AliasFactory.create_nested
create_target_alias = AliasFactory.create_target
create_move_alias = AliasFactory.create_move
create_chat_alias = AliasFactory.create_chat
create_tell_alias = AliasFactory.create_tell

return AliasFactory

