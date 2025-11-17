-- Color utility functions

local Colors = {}

Colors.COLOR_MAP = {C_BGREEN,
            C_GREEN,
            C_BCYAN,
            C_CYAN,
            C_BYELLOW,
            C_YELLOW,
            C_BMAGENTA,
            C_MAGENTA,
            C_BRED,
            C_RED,}

function Colors.get_color(pct_in)
  -- takes a 0.15 type percent and outputs the color code object
  local new_ind = ROUND_FLOAT(pct_in*TABLE_LENGTH(Colors.COLOR_MAP))
  if new_ind == 0 then
    new_ind = 1
  end
  return Colors.COLOR_MAP[new_ind]
end

function Colors.dpr_color(dpr_in)
  local new_ind = ROUND_FLOAT(tonumber(dpr_in) / 125 * TABLE_LENGTH(Colors.COLOR_MAP))
  if new_ind == 0 then
    new_ind = 1
  end
  if new_ind > TABLE_LENGTH(Colors.COLOR_MAP) then
    new_ind = TABLE_LENGTH(Colors.COLOR_MAP)
  end
  return Colors.COLOR_MAP[new_ind] .. tostring(dpr_in) .. C_RESET
end

-- Export as globals for backward compatibility
COLOR_MAP = Colors.COLOR_MAP
GET_COLOR = Colors.get_color
DPR_COLOR = Colors.dpr_color

return Colors

