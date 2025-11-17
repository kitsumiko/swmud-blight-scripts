-- Nickname handling functions

local Nicknames = {}

function Nicknames.create(n_in, n_out)
  NICKNAME_TABLE[n_out] = regex.new(" "..n_in.." ")
end

function Nicknames.replace(str_in)
  local str_out = str_in
  for i, v in pairs(NICKNAME_TABLE) do
    str_out = v:replace(str_out, " "..i.." ")
  end
  return str_out
end

-- Export as globals for backward compatibility
create_nickname = Nicknames.create
NICKNAME_REPLACE = Nicknames.replace

return Nicknames

