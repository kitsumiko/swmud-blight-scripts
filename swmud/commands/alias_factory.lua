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
    
    -- Map short direction to long form if DIRECTION_MAP is defined (can be set in character file)
    local direction = a_in
    local was_mapped = false
    if DIRECTION_MAP and DIRECTION_MAP[a_in] then
      direction = DIRECTION_MAP[a_in]
      was_mapped = true
    end
    
    -- Build the final command to send
    local cmd_to_send = direction
    if PROMPT_INFO.move_cmd ~= "" then
      cmd_to_send = tostring(PROMPT_INFO.move_cmd) .. " " .. direction
    end
    
    -- If GLOBAL_SEND is already processing, this means mud.input() re-triggered the alias
    -- In this case, just send directly with mud.send() to break the loop
    if GLOBAL_SEND_PROCESSING then
      -- Send directly without going through GLOBAL_SEND to prevent infinite loop
      mud.send(cmd_to_send)
      return
    end
    
    -- If the direction was mapped (short -> long), use GLOBAL_SEND to show the expansion (e -> east)
    -- If it wasn't mapped (already long form like "east"), send directly to prevent loop
    if was_mapped then
      -- Short form was mapped to long form, use GLOBAL_SEND to show expansion
      if PROMPT_INFO.move_cmd == "" then
        GLOBAL_SEND(cmd_to_send)
      else
        -- move_cmd is set, we want aliases to trigger on "enter shuttle w"
        GLOBAL_SEND(cmd_to_send)
      end
    else
      -- Already long form (e.g., "east"), send directly to prevent infinite loop
      -- This prevents "east" from triggering the "east" alias again
      if PROMPT_INFO.move_cmd == "" then
        mud.send(cmd_to_send, {gag = true})
      else
        mud.send(cmd_to_send)
      end
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

-- Table to store no-space aliases for preprocessing in input listener
-- Format: {pattern = replacement_function}
-- pattern is a Lua pattern, replacement_function takes the matched text and returns the replacement
NO_SPACE_ALIASES = NO_SPACE_ALIASES or {}

-- Create alias without space requirement (e.g., $'hello works, not just $' hello)
-- This is for aliases that use $ prefix or special characters that don't require spaces
-- These are preprocessed in the input listener before BlightMud's alias system tries to handle them
-- We don't use alias.add() because BlightMud doesn't handle these patterns well
function AliasFactory.create_no_space(a_in, a_out)
  -- Escape special regex characters in a_in for Lua pattern matching
  -- Note: backtick (`) is a literal character in Lua patterns and doesn't need escaping
  local escaped_in = string.gsub(a_in, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
  -- Register for preprocessing in input listener
  -- Handle both with and without space: "aliastext" and "aliastext " both work
  local pattern_no_space = "^" .. escaped_in .. "(.+)$"
  local pattern_with_space = "^" .. escaped_in .. "%s+(.+)$"
  NO_SPACE_ALIASES[pattern_no_space] = function(matched_text, capture)
    return a_out .. " " .. capture
  end
  NO_SPACE_ALIASES[pattern_with_space] = function(matched_text, capture)
    return a_out .. " " .. capture
  end
end

-- Create alias without space requirement with suffix (e.g., -e becomes lpeer e 10)
-- These are preprocessed in the input listener before BlightMud's alias system tries to handle them
-- We don't use alias.add() because BlightMud doesn't handle these patterns well
function AliasFactory.create_no_space_nested(a_in, a_out, a_last)
  -- Escape special regex characters in a_in for Lua pattern matching
  -- Note: backtick (`) is a literal character in Lua patterns and doesn't need escaping
  local escaped_in = string.gsub(a_in, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
  -- Register for preprocessing in input listener
  -- Handle both with and without space: "-e" and "- e" both work
  local pattern_no_space = "^" .. escaped_in .. "(.+)$"
  local pattern_with_space = "^" .. escaped_in .. "%s+(.+)$"
  NO_SPACE_ALIASES[pattern_no_space] = function(matched_text, capture)
    return a_out .. " " .. capture .. a_last
  end
  NO_SPACE_ALIASES[pattern_with_space] = function(matched_text, capture)
    return a_out .. " " .. capture .. a_last
  end
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
create_no_space_alias = AliasFactory.create_no_space
create_no_space_nested_alias = AliasFactory.create_no_space_nested

return AliasFactory

