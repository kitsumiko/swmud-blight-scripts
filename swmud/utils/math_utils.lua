-- Math utility functions

local MathUtils = {}

function MathUtils.round_float(num, num_dp)
  local mult = 10^(num_dp or 0)
  return math.floor(num * mult + 0.5) / mult
end

function MathUtils.is_int(n)
  return n == math.floor(n)
end

-- Export as globals for backward compatibility
ROUND_FLOAT = MathUtils.round_float
IS_INT = MathUtils.is_int

return MathUtils

