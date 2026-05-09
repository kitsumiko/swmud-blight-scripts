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

-- Format a signed delta with directional arrow + green/red/dim color.
-- `value` is the difference (current - previous); `lower_is_better` flips the
-- "improvement" direction for metrics like Combat Time / Damage taken / Rounds.
-- `baseline` (optional) lets us treat tiny deltas as "≈ same" using a 1% threshold.
-- `unit` (optional) is appended to the numeric arrow form only — for "≈ same"
-- we omit the unit so callers don't need to special-case the sentinel.
function Colors.delta_color(value, lower_is_better, baseline, unit)
  unit = unit or ""
  local n = tonumber(value) or 0
  if baseline and baseline ~= 0 and math.abs(n) / math.abs(baseline) < 0.01 then
    return (C_WHITE or "") .. "(\xe2\x89\x88 same)" .. C_RESET
  end
  if n == 0 then
    return (C_WHITE or "") .. "(\xe2\x89\x88 same)" .. C_RESET
  end
  local improving = (n > 0) ~= lower_is_better
  local arrow
  if n > 0 then arrow = "\xe2\x96\xb2 +" else arrow = "\xe2\x96\xbc " end
  local color = improving and (C_BGREEN or C_GREEN or "") or (C_BRED or C_RED or "")
  local num_str
  if math.floor(n) == n then
    num_str = tostring(math.floor(n))
  else
    num_str = string.format("%.2f", n)
  end
  return color .. arrow .. num_str .. unit .. C_RESET
end

-- Color the team alignment value by proximity to a team-switch threshold.
-- Ranges per in-game `panic alignment`: Imperial -75..-26, Neutral -25..25, Rebel 26..75.
function Colors.alignment_color(align_in)
  local n = tonumber(STRIP_COLOR(tostring(align_in)))
  if n == nil then return tostring(align_in) end
  local ratio
  if n <= -26 then
    ratio = (n + 75) / 49
  elseif n >= 26 then
    ratio = (75 - n) / 49
  else
    ratio = math.abs(n) / 25
  end
  if ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
  return Colors.get_color(ratio) .. tostring(align_in) .. C_RESET
end

-- Export as globals for backward compatibility
COLOR_MAP = Colors.COLOR_MAP
GET_COLOR = Colors.get_color
DPR_COLOR = Colors.dpr_color
ALIGNMENT_COLOR = Colors.alignment_color
DELTA_COLOR = Colors.delta_color

return Colors

