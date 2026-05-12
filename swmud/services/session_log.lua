-- Session log: in-memory rolling log of recent kills + cross-mob aggregates.
--
-- Drives two pieces of the combat summary:
--   1. Multi-column "previous N kills" table — SessionLog.recent(N) returns
--      the most recent N snapshots regardless of mob type.
--   2. The "Session (K kills, T elapsed)" footer block at the bottom of the
--      summary — SessionLog.session_stats() returns running totals.
--
-- Lives only in memory. Resets on script load (this file's top-level execution
-- creates a fresh SessionLog table). No disk persistence — that's
-- CombatHistory's job, which is per-mob and lifetime-scoped.

local SessionLog = {}

SessionLog.MAX_HISTORY = 16  -- a bit more than MAX_PREV columns, for headroom

local function fresh()
  return {
    start_ts          = os.time(),
    kills             = 0,
    total_damage      = 0,
    total_exp_diff    = 0,
    total_combat_time = 0,
    total_dpr_sum     = 0,
    mobs              = {},   -- { mob_name = kill_count }
    history           = {},   -- rolling list of snapshots, newest first
  }
end

SessionLog.state = fresh()

local function n(v) return tonumber(v) or 0 end

-- Append the snapshot into the rolling history (newest first) and update the
-- session aggregates. Called once per kill from calc_battle_stats AFTER the
-- summary has been rendered (so prev_kills for that kill came from the prior
-- state of the log — recording happens last).
function SessionLog.record(snap)
  if snap == nil then return end
  local s = SessionLog.state
  s.kills             = s.kills + 1
  s.total_damage      = s.total_damage + n(snap.damage)
  s.total_exp_diff    = s.total_exp_diff + n(snap.exp_diff)
  s.total_combat_time = s.total_combat_time + n(snap.combat_time_sec)
  s.total_dpr_sum     = s.total_dpr_sum + n(snap.dpr)

  local mob = snap.mob
  if type(mob) == "string" and mob ~= "" then
    s.mobs[mob] = (s.mobs[mob] or 0) + 1
  end

  table.insert(s.history, 1, snap)
  while #s.history > SessionLog.MAX_HISTORY do
    table.remove(s.history)
  end
end

-- Return up to `count` most recent snapshots, newest first. Empty list when
-- this is the first kill of the session.
function SessionLog.recent(count)
  local c = tonumber(count) or 0
  if c <= 0 then return {} end
  local out = {}
  local h = SessionLog.state.history
  for i = 1, math.min(c, #h) do
    out[i] = h[i]
  end
  return out
end

-- Render-ready aggregate. `mobs_summary_str` is sorted by descending count.
function SessionLog.session_stats()
  local s = SessionLog.state
  local elapsed = os.difftime(os.time(), s.start_ts or os.time())
  if elapsed < 0 then elapsed = 0 end

  local avg_dpr, avg_time = 0, 0
  if s.kills > 0 then
    avg_dpr  = s.total_dpr_sum / s.kills
    avg_time = s.total_combat_time / s.kills
  end

  -- Sorted "orc x5, scout x4, droid x3" line
  local pairs_list = {}
  for name, cnt in pairs(s.mobs) do
    pairs_list[#pairs_list + 1] = { name = name, count = cnt }
  end
  table.sort(pairs_list, function(a, b)
    if a.count == b.count then return a.name < b.name end
    return a.count > b.count
  end)
  local parts = {}
  for _, p in ipairs(pairs_list) do
    parts[#parts + 1] = p.name .. " x" .. tostring(p.count)
  end
  local mobs_summary_str = table.concat(parts, ", ")

  return {
    kills             = s.kills,
    total_damage      = s.total_damage,
    total_exp_diff    = s.total_exp_diff,
    total_combat_time = s.total_combat_time,
    elapsed_sec       = elapsed,
    avg_dpr           = avg_dpr,
    avg_time          = avg_time,
    mobs_summary_str  = mobs_summary_str,
  }
end

function SessionLog.reset()
  SessionLog.state = fresh()
end

-- Export
_G.SessionLog = SessionLog

return SessionLog
