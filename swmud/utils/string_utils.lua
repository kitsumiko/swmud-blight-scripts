-- String utility functions

local StringUtils = {}

function StringUtils.trim(s)
  return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function StringUtils.strip_color(s)
  -- Handle non-string values (numbers, nil, etc.)
  if type(s) ~= "string" then
    return tostring(s or "")
  end
  return (s:gsub('\x1b%[%d+;%d+;%d+;%d+;%d+m',''):gsub('\x1b%[%d+;%d+;%d+;%d+m',''):gsub('\x1b%[%d+;%d+;%d+m',''):gsub('\x1b%[%d+;%d+m',''):gsub('\x1b%[%d+m',''))
end

function StringUtils.title_case(str)
  return str:gsub("(%l)(%w*)", function(a,b) return string.upper(a)..b end)
end

function StringUtils.pad_percent(pct_in, add_space)
  local new_string = tostring(math.floor(pct_in*100))
  new_string = string.rep(" ", add_space) .. " ("..string.rep(" ", 3-string.len(new_string)) .. new_string .. "%"..")"
  return new_string
end

-- Export as globals for backward compatibility
TRIM_STRING = StringUtils.trim
STRIP_COLOR = StringUtils.strip_color
TITLE_CASE = StringUtils.title_case
PAD_PERCENT = StringUtils.pad_percent

return StringUtils

