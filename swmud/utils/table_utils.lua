-- Table utility functions

local TableUtils = {}

function TableUtils.length(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function TableUtils.values(t, start_index)
  local i = start_index or 1
  return function() i = i + 1; return t[i] end
end

function TableUtils.shallow_copy(original)
  local copy = {}
  for key, value in pairs(original) do
    copy[key] = value
  end
  return copy
end

function TableUtils.remove_duplicates(set)
  local hash = {}
  local res = {}
  for _,v in ipairs(set) do
    if (not hash[v]) then
      res[#res+1] = v
      hash[v] = true
    end
  end
  return res
end

function TableUtils.index_of(array, value)
  for i, v in ipairs(array) do
    if v == value then
      return i
    end
  end
  return nil
end

-- Set operations
function TableUtils.add_to_set(set, key)
  set[key] = true
end

function TableUtils.remove_from_set(set, key)
  set[key] = nil
end

function TableUtils.set_contains(set, key)
  return set[key] ~= nil
end

function TableUtils.set_value_contains(set, value)
  for k,v in pairs(set) do
    if v == value then
      return true
    end
  end
  return false
end

function TableUtils.set_reverse_lookup(set, value)
  for k,v in pairs(set) do
    if v == value then
      return tostring(k)
    end
  end
  return nil
end

function TableUtils.set(list)
  local set = {}
  for _, l in ipairs(list) do set[l] = true end
  return set
end

-- Export as globals for backward compatibility
TABLE_LENGTH = TableUtils.length
VALUES = TableUtils.values
SHALLOW_COPY = TableUtils.shallow_copy
REMOVE_DUPLICATES = TableUtils.remove_duplicates
ADD_TO_SET = TableUtils.add_to_set
REMOVE_FROM_SET = TableUtils.remove_from_set
SET_CONTAINS = TableUtils.set_contains
SET_VALUE_CONTAINS = TableUtils.set_value_contains
SET_REVERSE_LOOKUP = TableUtils.set_reverse_lookup
SET = TableUtils.set
INDEX_OF = TableUtils.index_of

return TableUtils

