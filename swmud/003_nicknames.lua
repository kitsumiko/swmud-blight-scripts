-- helper functions
function create_nickname(n_in, n_out)
  NICKNAME_TABLE[n_out] = regex.new(" "..n_in.." ")
end

function NICKNAME_REPLACE(str_in)
  local str_out = str_in
  for i, v in pairs(NICKNAME_TABLE) do
    str_out = v:replace(str_out, " "..i.." ")
  end
  return str_out
end
