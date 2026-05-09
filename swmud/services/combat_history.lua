-- Combat history persistence service
-- Stores per-character, per-mob: the previous fight snapshot + lifetime aggregates.
-- Backed by Blightmud disk store + json.encode/decode (survives restarts).

local CombatHistory = {}

local DISK_KEY_PREFIX = "swmud_combat_history_"

-- In-process cache: <char_name> -> decoded table. Avoids disk reads on every kill.
local _cache = {}

local function disk_key(char_name)
  return DISK_KEY_PREFIX .. (char_name or "unknown")
end

function CombatHistory.load(char_name)
  if _cache[char_name] ~= nil then
    return _cache[char_name]
  end
  local raw = store.disk_read(disk_key(char_name))
  if raw == nil or raw == "" then
    _cache[char_name] = {}
    return _cache[char_name]
  end
  local ok, decoded = pcall(json.decode, raw)
  if not ok or type(decoded) ~= "table" then
    -- Corrupt blob: start fresh rather than crash. Keep the bad blob undisturbed
    -- on disk in case the user wants to recover it manually.
    _cache[char_name] = {}
    return _cache[char_name]
  end
  _cache[char_name] = decoded
  return _cache[char_name]
end

function CombatHistory.save(char_name, tbl)
  _cache[char_name] = tbl
  local ok, encoded = pcall(json.encode, tbl)
  if not ok then return false end
  store.disk_write(disk_key(char_name), encoded)
  return true
end

function CombatHistory.get_previous(char_name, mob_name)
  local data = CombatHistory.load(char_name)
  local entry = data[mob_name]
  if entry and entry.last then return entry.last end
  return nil
end

function CombatHistory.get_aggregates(char_name, mob_name)
  local data = CombatHistory.load(char_name)
  local entry = data[mob_name]
  if entry and entry.agg then return entry.agg end
  return nil
end

local function bump_max(agg, key, value)
  if value == nil then return end
  if agg[key] == nil or value > agg[key] then agg[key] = value end
end

local function bump_min(agg, key, value)
  if value == nil then return end
  if agg[key] == nil or value < agg[key] then agg[key] = value end
end

local function add_sum(agg, key, value)
  agg[key] = (agg[key] or 0) + (tonumber(value) or 0)
end

-- Fold a snapshot into the running aggregate record.
function CombatHistory.update_agg(agg, snap)
  agg.count = (agg.count or 0) + 1
  if not agg.first_kill_ts then agg.first_kill_ts = snap.kill_ts end
  agg.last_kill_ts = snap.kill_ts

  add_sum(agg, "sum_damage",         snap.damage)
  add_sum(agg, "sum_dpr",            snap.dpr)
  add_sum(agg, "sum_edamage",        snap.edamage)
  add_sum(agg, "sum_edpr",           snap.edpr)
  add_sum(agg, "sum_damage_taken",   snap.damage_taken)
  add_sum(agg, "sum_combat_time",    snap.combat_time_sec)
  add_sum(agg, "sum_rounds",         snap.rounds)
  add_sum(agg, "sum_exp_diff",       snap.exp_diff)
  add_sum(agg, "sum_exp_per_sec",    snap.exp_per_sec)
  add_sum(agg, "sum_hits",           snap.hits)
  add_sum(agg, "sum_misses",         snap.misses)
  add_sum(agg, "sum_credits_gained", snap.credits_gained)
  add_sum(agg, "sum_hp_cost",        snap.hp_cost)

  -- Bests: higher = better
  bump_max(agg, "best_dpr",               snap.dpr)
  bump_max(agg, "best_exp_per_sec",       snap.exp_per_sec)
  bump_max(agg, "best_round_damage",      snap.best_round_damage)
  bump_max(agg, "best_accuracy",          snap.accuracy)
  -- Bests: lower = better (so they're tracked as min)
  bump_min(agg, "best_combat_time",       snap.combat_time_sec)
  bump_min(agg, "best_damage_taken",      snap.damage_taken)
  bump_min(agg, "best_hp_cost",           snap.hp_cost)
  -- Worsts: opposite extremes — useful for the percentile estimate
  bump_min(agg, "worst_dpr",              snap.dpr)
  bump_max(agg, "worst_combat_time",      snap.combat_time_sec)
  bump_min(agg, "worst_exp_per_sec",      snap.exp_per_sec)
  bump_min(agg, "worst_accuracy",         snap.accuracy)
end

function CombatHistory.record(char_name, mob_name, snap)
  local data = CombatHistory.load(char_name)
  local entry = data[mob_name]
  if entry == nil then
    entry = { last = nil, agg = {} }
    data[mob_name] = entry
  end
  if entry.agg == nil then entry.agg = {} end
  CombatHistory.update_agg(entry.agg, snap)
  entry.last = snap
  CombatHistory.save(char_name, data)
end

-- Average helper for renderer code.
function CombatHistory.avg(agg, sum_key)
  if not agg or not agg.count or agg.count == 0 then return 0 end
  return (agg[sum_key] or 0) / agg.count
end

-- Export as global
_G.CombatHistory = CombatHistory

return CombatHistory
