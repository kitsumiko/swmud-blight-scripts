-- global helper functions
function TABLE_LENGTH(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function VALUES(t, start_index)
  local i = start_index
  return function() i = i + 1; return t[i] end
end

function ROUND_FLOAT(num, num_dp)
  local mult = 10^(num_dp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function set_status_default()
  blight.status_height(2)
  blight.status_line(0, "")
end

function SHALLOW_COPY(original)
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = value
	end
	return copy
end

-- set functions
function REMOVE_DUPLICATES(set)
  local hash = {}
  local res = {}
  for _,v in ipairs(set) do
    if (not hash[v]) then
      res[#res+1] = v -- you could print here instead of saving to result table if you wanted
      hash[v] = true
    end
  end
  return res
end

function ADD_TO_SET(set, key)
    set[key] = true
end

function REMOVE_FROM_SET(set, key)
    set[key] = nil
end

function SET_CONTAINS(set, key)
    return set[key] ~= nil
end

function SET_VALUE_CONTAINS(set, value)
  local out_val = nil
  for k,v in pairs(set) do
    if v == value then
      out_val = true
    end
  end
  return out_val
end

function SET_REVERSE_LOOKUP(set, value)
  local out_val = nil
  for k,v in pairs(set) do
    if v == value then
      out_val = tostring(k)
    end
  end
  return out_val
end

function SET(list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

-- string functions
function TRIM_STRING(s)
   return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function STRIP_COLOR(s)
  return (s:gsub('\x1b%[%d+;%d+;%d+;%d+;%d+m',''):gsub('\x1b%[%d+;%d+;%d+;%d+m',''):gsub('\x1b%[%d+;%d+;%d+m',''):gsub('\x1b%[%d+;%d+m',''):gsub('\x1b%[%d+m',''))
end

function TITLE_CASE(str)
  return str:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
end

function PAD_PERCENT(pct_in, add_space)
  local new_string = tostring(math.floor(pct_in*100))
  new_string = string.rep(" ", add_space) .. " ("..string.rep(" ", 3-string.len(new_string)) .. new_string .. "%"..")"
  return new_string
end

-- index functions
function INDEX_OF(array, value)
    for i, v in ipairs(array) do
        if v == value then
            return i
        end
    end
    return nil
end
