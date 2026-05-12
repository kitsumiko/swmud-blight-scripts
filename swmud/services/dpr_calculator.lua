-- DPR calculation service

local DPRCalculator = {}

function DPRCalculator.update_dpr_status()
  local base_str = ""
  if SET_CONTAINS(DPR_INFO, TARGET_INFO['last_target']) then
    local target = TARGET_INFO['last_target']
    local total_dpr = 0
    local assist_dpr = 0
    if SET_CONTAINS(DPR_INFO[target], "You") then
      if DPR_INFO[target]["You"]["dpr"]~=nil then
        base_str = base_str.."You: ".. DPR_COLOR(DPR_INFO[target]["You"]["dpr"])
        total_dpr = total_dpr + DPR_INFO[target]["You"]["dpr"]
      end
    end
    for source, s_info in pairs(DPR_INFO[target]) do
      if type(s_info) ~= "number" then
        if source ~= "You" then
          if s_info["dpr"]~=nil then
            base_str = base_str.." "..source..": ".. DPR_COLOR(s_info["dpr"])
            total_dpr = total_dpr + s_info["dpr"]
            assist_dpr = 1
          end
        end
      end
    end
    if assist_dpr == 1 then
      if total_dpr ~= nil then
        base_str = "tDPR: " .. DPR_COLOR(total_dpr) .. STATUS_SEP .. base_str        
      end
    end
    PROMPT_INFO.total_dpr = total_dpr
  end
  DPR_INFO["status_line"] = base_str
end

function DPRCalculator.update_total_damage(target)
  if SET_CONTAINS(DPR_INFO, target) then
    local total_damage = 0
    for source, s_info in pairs(DPR_INFO[target]) do
      if type(s_info) ~= "number" then
        total_damage = total_damage + s_info["damage"]
      end
    end
    DPR_INFO[target]["total"] = total_damage
  end
end

function DPRCalculator.process_health_table(clean_table)
  local avg_total_health = 0
  local health_added = 0
  if TABLE_LENGTH(clean_table)>1 then
    local health_x = {}
    local damage_x = {}
    for k,r_v in pairs(clean_table) do
      local v = {}
      for k1, v1 in string.gmatch(r_v, "(%w+)=(%w+)") do
        v[k1] = tonumber(v1)
      end
      if health_x[#health_x] ~= v["health"] then
        health_x[#health_x+1] = v["health"]
      end
      if TABLE_LENGTH(health_x) ~= TABLE_LENGTH(damage_x) then
        damage_x[#damage_x+1] = v["damage"]
      end
    end
    if TABLE_LENGTH(health_x)>1 then
      local diff_health = {}
      local diff_damage = {}
      for k,v in ipairs(health_x) do
        if k > 1 then
          if health_x[k-1] > health_x[k] and damage_x[k] > damage_x[k-1] then
            diff_health[#diff_health+1] = health_x [k-1] - health_x[k]
            diff_damage[#diff_damage+1] = damage_x[k] - damage_x[k-1]
          end
        end
      end
      avg_total_health = 0
      local last_health_pct = 1-(100 - health_x[#health_x])/100
      for k,v in ipairs(diff_health) do
        avg_total_health = avg_total_health + (diff_damage[k] / (1-(100-diff_health[k])/100))
      end
      avg_total_health = math.floor(avg_total_health / TABLE_LENGTH(diff_health))
      TARGET_INFO.target_pct = last_health_pct
      TARGET_INFO.target_health = math.floor(last_health_pct*avg_total_health)
      TARGET_INFO.total_health = tonumber(avg_total_health)
      health_added = 1
    end
  end
  return health_added
end

function DPRCalculator.get_add_space(line_flag)
  local add_space = 0
  if line_flag=="t" then
    add_space = PROMPT_INFO.thp_length - PROMPT_INFO.hp_length
  else
    add_space = PROMPT_INFO.hp_length - PROMPT_INFO.thp_length
  end
  if add_space < 0 then
    add_space = 0
  end
  return add_space
end

function DPRCalculator.update_target_status()
  if SET_CONTAINS(DPR_INFO, TARGET_INFO['last_target']) then
    DPRCalculator.update_total_damage(TARGET_INFO['last_target'])
    local target = TRIM_STRING(TARGET_INFO["last_target"])
    local short_name = TRIM_STRING(CHAR_DATA.character_name)
    local name_max = math.max(string.len(target), string.len(short_name))
    local name_pad = string.rep(" ", name_max - string.len(target))
    local base_str = "T: "..target..name_pad
    local health_str = "H: "
    local health_added = 0
    if TARGET_INFO[target]["dead"] == 1 then
      PROMPT_INFO.thp_length = string.len("0") + string.len(TARGET_INFO.total_health)
      local add_space = DPRCalculator.get_add_space('c')
      health_str = health_str .. "0/" .. tostring(TARGET_INFO.total_health) .. PAD_PERCENT(0.0, add_space)
    else
      local clean_table = REMOVE_DUPLICATES(TARGET_INFO[target]["h_hscan"])
      health_added = DPRCalculator.process_health_table(clean_table)
      local clean_table = REMOVE_DUPLICATES(TARGET_INFO[target]["h_bsense"])
      if health_added==0  and TABLE_LENGTH(clean_table)>1 then
        health_added = DPRCalculator.process_health_table(clean_table)
      end
      local clean_table = REMOVE_DUPLICATES(TARGET_INFO[target]["h_blook"])
      if health_added==0  and TABLE_LENGTH(clean_table)>1 then
        health_added = DPRCalculator.process_health_table(clean_table)
      end
      if health_added==0 then
        health_str = health_str .. "Calculating..."
      else
        local current_health_num = TARGET_INFO.target_health - TARGET_INFO.unrec_damage
        local current_health = GET_COLOR(TARGET_INFO.target_pct) .. tostring(current_health_num) .. C_RESET
        PROMPT_INFO.thp_length = string.len(tostring(current_health_num)) + string.len(tostring(TARGET_INFO.total_health))
        local add_space = DPRCalculator.get_add_space('c')
        health_str = health_str .. current_health .. "/" .. tonumber(TARGET_INFO.total_health) .. PAD_PERCENT(current_health_num/TARGET_INFO.total_health, add_space)
      end
    end
    local dpr_str = ""
    if SET_CONTAINS(DPR_INFO, "you") then
      if SET_CONTAINS(DPR_INFO["you"], target) then
        dpr_str = dpr_str .."eDPR: ".. DPR_INFO["you"][target]["dpr"]
        PROMPT_INFO.edpr = DPR_INFO["you"][target]["dpr"]
      end
    end
    TARGET_INFO["status_line"] = base_str .. STATUS_SEP .. health_str .. STATUS_SEP .. dpr_str
  end
end

-- Local helper for HP/prompt reads inside dpr_primary_loop. The file-scoped
-- `num` is declared further down (around line 216) so it isn't in scope here;
-- this duplicates that logic so the hook code below can use it without a
-- forward-reference.
local function num_safe(v) return tonumber(STRIP_COLOR(tostring(v or 0))) or 0 end

function DPRCalculator.dpr_primary_loop(source, damage_tier, target, new_round)
  if target ~= nil then
    init_target(target, source)
    if source == "You" then
      if TARGET_INFO["last_target"] ~= target then
        reset_target(target)
        TARGET_INFO["last_target"] = target
        -- Fire the "Combat started" marker exactly once per fresh engagement.
        -- Guarded on the new-target predicate above so re-entries against the
        -- same mob don't spam markers.
        if CombatTab then CombatTab.emit_start(target) end
      end
    end
    if target == "You" or target=="you" then
      TARGET_INFO["last_target"] = source
    end
    if not SET_CONTAINS(DPR_INFO[target], source) then
      DPR_INFO[target][source] = {damage = 0, rounds = 0, dpr = 0, ndpr = 0,
                                  hits = 0, misses = 0,
                                  best_round_damage = 0, current_round_damage = 0,
                                  -- Seed the HP baseline so the first emitted
                                  -- round's delta is computed against a real
                                  -- value rather than 0 (avoids spurious -hp
                                  -- spikes on round 1).
                                  last_hp_at_round_start = num_safe(PROMPT_INFO.hp),}
    end
  end
  if new_round==1 then
    -- Resolve which target's per-source struct to update
    local round_target = target
    if round_target == nil and TARGET_INFO["last_target"] ~= nil then
      round_target = TARGET_INFO["last_target"]
    end
    if round_target ~= nil and SET_CONTAINS(DPR_INFO, round_target)
        and SET_CONTAINS(DPR_INFO[round_target], source) then
      local s = DPR_INFO[round_target][source]
      -- Close out the previous round before incrementing the rounds counter:
      -- if the round we're about to leave dealt more damage than any prior, record it.
      local prev_round_damage = s.current_round_damage or 0
      if prev_round_damage > (s.best_round_damage or 0) then
        s.best_round_damage = prev_round_damage
      end
      s.current_round_damage = 0
      s.rounds = s.rounds + 1

      -- Per-round summary → combat tab (tab-only, via blight.output_to).
      -- s.rounds is post-increment, so s.rounds - 1 is the round that just
      -- ended. The s.rounds > 1 gate skips the first new_round tick (which
      -- represents "starting round 1" — no prior round to summarize).
      if CombatTab and source == "You"
          and round_target == TARGET_INFO["last_target"]
          and s.rounds > 1
          and TARGET_INFO[round_target]
          and TARGET_INFO[round_target]["dead"] ~= 1 then
        local hp_now = num_safe(PROMPT_INFO.hp)
        local hp_at_start = s.last_hp_at_round_start or hp_now
        CombatTab.emit_round_end({
          round_num         = s.rounds - 1,
          round_damage      = prev_round_damage,
          best_round        = s.best_round_damage or 0,
          cum_damage        = s.damage or 0,
          dpr               = s.dpr or 0,
          hits              = s.hits or 0,
          misses            = s.misses or 0,
          mob_name          = round_target,
          mob_pct           = TARGET_INFO.target_pct or 0,
          mob_health        = TARGET_INFO.target_health or 0,
          mob_total_health  = TARGET_INFO.total_health or 0,
          player_hp         = hp_now,
          player_max_hp     = num_safe(PROMPT_INFO.hp_max),
          player_hp_delta   = hp_now - hp_at_start,
        })
        s.last_hp_at_round_start = hp_now
      end
    end
  end
  if target == TARGET_INFO["last_target"] then
    TARGET_INFO.unrec_damage = TARGET_INFO.unrec_damage + tier_lookup[damage_tier]
  end
  if target ~= nil then
    local s = DPR_INFO[target][source]
    s.damage = s.damage + tier_lookup[damage_tier]
    s.current_round_damage = (s.current_round_damage or 0) + tier_lookup[damage_tier]
    s.dpr = ROUND_FLOAT(s.damage / s.rounds, 2)
    if SET_CONTAINS(DPR_INFO[target], "You") then
      s.ndpr = ROUND_FLOAT(s.damage / DPR_INFO[target]["You"]["rounds"], 2)
    end
    -- Hit/miss accounting: only for the player's attacks against a mob target
    if source == "You" and target ~= "you" and target ~= "You" then
      if damage_tier == "t0" then
        s.misses = (s.misses or 0) + 1
      else
        s.hits = (s.hits or 0) + 1
      end
    end
  end
  DPRCalculator.update_dpr_status()
  DPRCalculator.update_target_status()
  return tier_lookup[damage_tier]
end

-- ---------------- Combat summary helpers ----------------

local function num(v)
  return tonumber(STRIP_COLOR(tostring(v or 0))) or 0
end

local function fmt_int(n)
  return tostring(math.floor(num(n)))
end

local function fmt_time(secs)
  secs = math.max(0, math.floor(num(secs)))
  return os.date("!%H:%M:%S", secs)
end

local function fmt_short_time(secs)
  secs = math.max(0, math.floor(num(secs)))
  if secs >= 3600 then
    return os.date("!%H:%M:%S", secs)
  end
  return os.date("!%M:%S", secs)
end

local function fmt_ago(ts)
  if not ts then return "" end
  local diff = os.difftime(os.time(), ts)
  if diff < 0 then diff = 0 end
  if diff < 60 then return tostring(math.floor(diff)) .. "s ago" end
  if diff < 3600 then return tostring(math.floor(diff / 60)) .. "m ago" end
  if diff < 86400 then return tostring(math.floor(diff / 3600)) .. "h ago" end
  return tostring(math.floor(diff / 86400)) .. "d ago"
end

-- Strip color codes and return printed length.
local function visible_len(s)
  return string.len(STRIP_COLOR(tostring(s or "")))
end

-- Pad `s` (with embedded color codes) so that its visible length equals `width`.
local function pad_to(s, width)
  local extra = width - visible_len(s)
  if extra > 0 then return s .. string.rep(" ", extra) end
  return s
end

-- Left-pad `s` with spaces so its visible length equals `width` (right-align).
local function lpad(s, width)
  local extra = width - visible_len(s)
  if extra > 0 then return string.rep(" ", extra) .. s end
  return s
end

-- Build "left | right" line, with left padded to a fixed width so right column
-- is column-aligned. Right may be empty (no previous fight to compare against).
local function row(left, right, left_width)
  if right == nil or right == "" then
    return pad_to(left, left_width)
  end
  return pad_to(left, left_width) .. "  " .. right
end

-- Render a tabular row with dot-leader fill and right-aligned values:
--   <label> <dots filling the gap> <value>  <delta>
-- The total leader width is `label_col_w + 5 + value_col_w` (5 = " ... "), so
-- the value's right edge is constant across rows even when individual labels
-- and values have different lengths — values right-align automatically because
-- the dots absorb the slack.
local function leader_row(label, value, label_col_w, value_col_w, delta_text)
  local total_leader_w = label_col_w + 5 + value_col_w
  -- " " + dots + " " sit between label and value
  local dots_count = total_leader_w - visible_len(label) - visible_len(value) - 2
  if dots_count < 3 then dots_count = 3 end
  local s = label .. " " .. string.rep(".", dots_count) .. " " .. value
  if delta_text and delta_text ~= "" then
    s = s .. "  " .. delta_text
  end
  return s
end

-- ---------------- Snapshot builder ----------------

-- Captured at death-trigger time (synchronously) so the values can't be wiped by a
-- subsequent fight against another mob with the same name during the 0.5s sleep
-- before calc_battle_stats runs. The death trigger sets `dead=1`, and the very
-- next attack against the same mob name calls init_target → reset_target →
-- clears DPR_INFO[mob] and TARGET_INFO[mob]. Without this snapshot we'd lose
-- the per-strike hits/misses/best_round/mob_hp data.
function DPRCalculator.snapshot_kill_struct(raw_mob_name)
  local you_struct = nil
  if SET_CONTAINS(DPR_INFO, raw_mob_name) and SET_CONTAINS(DPR_INFO[raw_mob_name], "You") then
    you_struct = DPR_INFO[raw_mob_name]["You"]
  end
  -- Close out the final in-flight round so its damage counts toward best_round_damage.
  if you_struct and (you_struct.current_round_damage or 0) > (you_struct.best_round_damage or 0) then
    you_struct.best_round_damage = you_struct.current_round_damage
  end
  PROMPT_INFO.last_hits              = (you_struct and you_struct.hits) or 0
  PROMPT_INFO.last_misses            = (you_struct and you_struct.misses) or 0
  PROMPT_INFO.last_best_round_damage = (you_struct and you_struct.best_round_damage) or 0
  PROMPT_INFO.last_mob_hp_estimate   = num(TARGET_INFO.total_health)
  PROMPT_INFO.last_start_credits     = num(TARGET_INFO.start_credits)
  PROMPT_INFO.last_start_hp          = num(TARGET_INFO.start_hp)
  PROMPT_INFO.last_start_combat_ts   = TARGET_INFO.start_combat_ts
  PROMPT_INFO.last_target_start_xp   = num(TARGET_INFO.target_start_xp)
end

local function build_snapshot()
  -- DPR_INFO is keyed by the raw mob string (the trigger capture). For storage/display
  -- we trim, so the disk key is consistent. The fields in PROMPT_INFO.last_* were
  -- captured at kill time by snapshot_kill_struct, so they're safe to read here even
  -- if the mob struct has since been reset by a follow-up fight.
  local raw_mob = tostring(PROMPT_INFO.last_kill or "")
  local mob = TRIM_STRING(raw_mob)

  local hits = num(PROMPT_INFO.last_hits)
  local misses = num(PROMPT_INFO.last_misses)
  local accuracy = 0
  if (hits + misses) > 0 then accuracy = hits / (hits + misses) end

  local damage = num(PROMPT_INFO.last_total_damage)
  local dpr = num(PROMPT_INFO.total_dpr)
  local edamage = num(PROMPT_INFO.last_total_edamage)
  local edpr = num(PROMPT_INFO.edpr)
  local damage_taken = num(PROMPT_INFO.last_damage_taken)
  local force_deflections = num(PROMPT_INFO.last_force_deflections)
  local rounds = num(PROMPT_INFO.last_total_rounds)
  local exp_diff = num(PROMPT_INFO.exp) - num(PROMPT_INFO.last_target_start_xp)
  local start_combat_ts = PROMPT_INFO.last_start_combat_ts or TARGET_INFO.start_combat_ts
  local combat_time_sec = os.difftime(PROMPT_INFO.last_kill_ts, start_combat_ts) + 4
  local exp_per_sec = 0
  if combat_time_sec > 0 then exp_per_sec = math.floor(exp_diff / combat_time_sec) end

  local credits_gained = num(PROMPT_INFO.credits) - num(PROMPT_INFO.last_start_credits)
  local hp_cost = num(PROMPT_INFO.hp) - num(PROMPT_INFO.last_start_hp)  -- negative means HP lost
  local mob_hp_estimate = num(PROMPT_INFO.last_mob_hp_estimate)
  local best_round_damage = num(PROMPT_INFO.last_best_round_damage)

  local weapon = ""
  local weapon_pct = 0
  if WEAPON_SKILL_INFO then
    weapon = WEAPON_SKILL_INFO.last_weapon or ""
    weapon_pct = num(WEAPON_SKILL_INFO.last_pct)
  end

  return {
    mob = mob,
    kill_ts = PROMPT_INFO.last_kill_ts or os.time(),
    damage = damage,
    dpr = dpr,
    edamage = edamage,
    edpr = edpr,
    damage_taken = damage_taken,
    force_deflections = force_deflections,
    rounds = rounds,
    exp_diff = exp_diff,
    combat_time_sec = combat_time_sec,
    exp_per_sec = exp_per_sec,
    hits = hits,
    misses = misses,
    accuracy = accuracy,
    best_round_damage = best_round_damage,
    mob_hp_estimate = mob_hp_estimate,
    credits_gained = credits_gained,
    hp_cost = hp_cost,
    weapon_skill = weapon,
    weapon_skill_pct = weapon_pct,
  }
end

-- ---------------- Comparison row builders ----------------

local function delta(curr_val, prev_val, lower_is_better, unit)
  if prev_val == nil then return "" end
  return DELTA_COLOR(num(curr_val) - num(prev_val), lower_is_better, num(prev_val), unit)
end

-- Rank estimate using best/worst bounds. Returns 0-100 where 100 = best-ever
-- on this metric, 0 = worst-ever. `lower_is_better` flips the semantics for
-- metrics like combat time. Returns nil if there's no usable bracket.
local function rank_pct(curr, best, worst, lower_is_better)
  if best == nil or worst == nil then return nil end
  if best == worst then return nil end
  local r
  if lower_is_better then
    r = (worst - num(curr)) / (worst - best)
  else
    r = (num(curr) - worst) / (best - worst)
  end
  if r < 0 then r = 0 end
  if r > 1 then r = 1 end
  return math.floor(r * 100 + 0.5)
end

local function rank_phrase(curr, best, worst, lower_is_better, label)
  local p = rank_pct(curr, best, worst, lower_is_better)
  if p == nil then return nil end
  local color
  if p >= 67 then color = C_BGREEN or C_GREEN or ""
  elseif p <= 33 then color = C_BRED or C_RED or ""
  else color = C_WHITE or "" end
  return label .. " " .. color .. tostring(p) .. "%" .. C_RESET
end

-- ---------------- Main entry ----------------

function DPRCalculator.calc_battle_stats()
  tasks.sleep(0.5)

  local snap = build_snapshot()
  local mob = snap.mob
  local char = "unknown"
  if CHAR_DATA and CHAR_DATA.character_name then
    char = TRIM_STRING(STRIP_COLOR(tostring(CHAR_DATA.character_name)))
    -- Score parser may not have populated yet; fall back to a placeholder so we
    -- still record something rather than dropping the snapshot.
    if char == "" or char:find("Unknown") then char = "unknown" end
  end

  -- Per-mob lifetime aggregates (existing, unchanged). The per-mob "previous
  -- kill" comparison is superseded by the SessionLog-driven multi-column
  -- layout below, but the lifetime block still pulls from CombatHistory.
  local agg = nil
  if CombatHistory and mob ~= "" then
    agg = CombatHistory.get_aggregates(char, mob)
  end
  local is_first_mob_kill = (agg == nil) or ((agg.count or 0) == 0)

  -- Cross-mob rolling history: up to MAX_PREV previous kills, newest first.
  -- Each entry has the same shape as build_snapshot()'s return value.
  local MAX_PREV = 3
  local prev_kills = (SessionLog and SessionLog.recent(MAX_PREV)) or {}

  -- Combat-ended marker → both tab and main (filter-routed in 021_tabs.lua).
  if CombatTab then CombatTab.emit_end(mob, snap.rounds, snap.damage) end

  -- Layout sizing
  local term_w = 80
  if blight.terminal_dimensions then
    local w, _ = blight.terminal_dimensions()
    if w and w > 0 then term_w = w end
  end

  -- ---------------- Cell + row builders ----------------
  --
  -- A row's `cells` array has one entry per column: cells[1] is the current
  -- kill (no delta — it's the baseline); cells[2..N] are previous kills, each
  -- rendering "<value> (<delta vs current>)" when both values are present.
  -- The delta is `prev - current` so an absolute "vs current" framing applies:
  --   * higher-is-better metric, prev > current → prev was better (green)
  --   * lower-is-better metric, prev < current → prev was better (green)
  -- The existing `delta()` helper computes `a - b` and DELTA_COLOR carries the
  -- correct sign/color semantics.

  local function with_yellow(s)
    return C_BYELLOW .. tostring(s or "") .. C_RESET
  end

  local function f_int(v)
    if v == nil then return "-" end
    return tostring(math.floor(num(v)))
  end
  local function f_dpr(v)
    if v == nil then return "-" end
    return string.format("%.2f", num(v))
  end
  local function f_pct01(v)  -- accuracy is stored as 0..1
    if v == nil then return "-" end
    return tostring(math.floor(num(v) * 100 + 0.5)) .. "%"
  end
  local function f_signed_int(v)
    if v == nil then return "-" end
    local nn = math.floor(num(v))
    return (nn >= 0 and "+" or "") .. tostring(nn)
  end
  local function f_mob_hp(v)
    if v == nil or num(v) <= 0 then return "-" end
    return "~" .. tostring(math.floor(num(v)))
  end
  local function f_time(v)
    if v == nil then return "-" end
    return fmt_time(v)
  end

  -- Build the column cell for a previous kill: "<value>" or "<value> (<delta>)".
  local function prev_cell(prev_val, current_val, formatter, lower_better, unit)
    local cell = with_yellow(formatter(prev_val))
    if prev_val ~= nil and current_val ~= nil then
      local d = delta(prev_val, current_val, lower_better, unit)
      if d and d ~= "" then
        cell = cell .. " (" .. d .. ")"
      end
    end
    return cell
  end

  -- Build a row for a snapshot field, applying the same formatter to current
  -- and each prev cell, with a delta on each prev cell.
  local function row_for_field(label, field, formatter, lower_better, unit)
    local cur = snap[field]
    local cells = { with_yellow(formatter(cur)) }
    for _, p in ipairs(prev_kills) do
      cells[#cells+1] = prev_cell(p[field], cur, formatter, lower_better, unit)
    end
    return { label = with_yellow(label), cells = cells }
  end

  local rows = {}

  table.insert(rows, row_for_field("Damage",      "damage",  f_int, false, ""))
  table.insert(rows, row_for_field("DPR",         "dpr",     f_dpr, false, ""))
  table.insert(rows, row_for_field("eDamage",     "edamage", f_int, true,  ""))
  table.insert(rows, row_for_field("eDPR",        "edpr",    f_dpr, true,  ""))

  if (num(snap.hits) + num(snap.misses)) > 0 then
    -- Hit / Miss: no delta (a hits-only delta is misleading; Accuracy below
    -- carries the meaningful change). Just print "H / M" per column.
    local function f_hm(s)
      if s == nil then return "-" end
      return tostring(math.floor(num(s.hits))) .. " / " .. tostring(math.floor(num(s.misses)))
    end
    local cells = { with_yellow(f_hm(snap)) }
    for _, p in ipairs(prev_kills) do
      cells[#cells+1] = with_yellow(f_hm(p))
    end
    table.insert(rows, { label = with_yellow("Hit / Miss"), cells = cells })

    table.insert(rows, row_for_field("Accuracy", "accuracy", f_pct01, false, "%"))
  end

  if num(snap.best_round_damage) > 0 then
    table.insert(rows, row_for_field("Best round", "best_round_damage", f_int, false, ""))
  end

  if num(snap.mob_hp_estimate) > 0 then
    table.insert(rows, row_for_field("Mob HP est", "mob_hp_estimate", f_mob_hp, false, ""))
  end

  if num(snap.damage_taken) > 0 then
    table.insert(rows, row_for_field("Damage taken", "damage_taken", f_int, true, ""))
  end

  if num(snap.hp_cost) ~= 0 then
    -- hp_cost is signed (typically negative). "Less negative" = lost less HP
    -- = better → treat as higher-is-better, matching the prior behavior.
    table.insert(rows, row_for_field("HP cost", "hp_cost", function(v)
      if v == nil then return "-" end
      return tostring(math.floor(num(v)))
    end, false, ""))
  end

  if num(snap.credits_gained) ~= 0 then
    table.insert(rows, row_for_field("Credits", "credits_gained", f_signed_int, false, ""))
  end

  if num(snap.force_deflections) > 0 then
    table.insert(rows, row_for_field("Force deflections", "force_deflections", f_int, false, ""))
  end

  if snap.weapon_skill and snap.weapon_skill ~= "" and num(snap.weapon_skill_pct) > 0 then
    -- Show "weapon (NN%)"; only render a delta when the prev kill used the
    -- SAME weapon (cross-weapon % comparison is misleading).
    local function f_weapon(s)
      if s == nil then return "-" end
      local w = s.weapon_skill or ""
      local p = num(s.weapon_skill_pct)
      if w == "" then return "-" end
      return w .. " (" .. tostring(math.floor(p)) .. "%)"
    end
    local cells = { with_yellow(f_weapon(snap)) }
    for _, p in ipairs(prev_kills) do
      local cell = with_yellow(f_weapon(p))
      if p.weapon_skill == snap.weapon_skill and p.weapon_skill_pct ~= nil then
        local d = delta(num(p.weapon_skill_pct), num(snap.weapon_skill_pct), false, "%")
        if d and d ~= "" then cell = cell .. " (" .. d .. ")" end
      end
      cells[#cells+1] = cell
    end
    table.insert(rows, { label = with_yellow("Weapon skill"), cells = cells })
  end

  if num(snap.exp_diff) ~= 0 then
    table.insert(rows, row_for_field("Experience", "exp_diff", f_int, false, ""))
    table.insert(rows, row_for_field("Exp/s",       "exp_per_sec", f_int, false, ""))
  end

  table.insert(rows, row_for_field("Combat Time", "combat_time_sec", f_time, true, "s"))
  table.insert(rows, row_for_field("Rounds",      "rounds",          f_int, true, ""))

  -- ---------------- Column-header row ("Target: <mob>" per column) ----------------

  local function fmt_target_header(name)
    return "Target: " .. (name ~= nil and name ~= "" and tostring(name) or "?")
  end

  local headers = { with_yellow(fmt_target_header(mob)) }
  for _, p in ipairs(prev_kills) do
    headers[#headers+1] = with_yellow(fmt_target_header(p.mob))
  end

  -- ---------------- Column widths + narrow-terminal truncation ----------------

  local label_col_w = 0
  for _, r in ipairs(rows) do
    local w = visible_len(r.label)
    if w > label_col_w then label_col_w = w end
  end

  local N = #headers  -- 1 (current) + #prev_kills
  local col_widths = {}
  for j = 1, N do
    col_widths[j] = visible_len(headers[j])
    for _, r in ipairs(rows) do
      local cw = visible_len(r.cells[j] or "")
      if cw > col_widths[j] then col_widths[j] = cw end
    end
  end

  local function total_table_w(nc)
    local t = label_col_w + 5  -- " ... "
    for j = 1, nc do t = t + col_widths[j] end
    if nc > 1 then t = t + 2 * (nc - 1) end
    return t
  end

  -- Drop the rightmost (oldest) prev columns until the table fits the terminal.
  while N > 1 and total_table_w(N) > term_w do
    N = N - 1
  end

  local render_w = math.min(term_w, total_table_w(N))

  -- ---------------- Rendering ----------------

  -- Top header (no right-side timestamp annotation anymore — column headers
  -- replace it).
  blight.output(C_BYELLOW .. "####### Combat Summary #######" .. C_RESET)

  -- Column-header row: align "Target: <mob>" with the start of each data
  -- column. Leading-spaces equal to label_col_w + 5 (the " ... " gutter),
  -- then each header padded to its column width and joined by "  ".
  do
    local lead = string.rep(" ", label_col_w + 5)
    local parts = {}
    for j = 1, N do
      parts[#parts+1] = pad_to(headers[j], col_widths[j])
    end
    blight.output(lead .. table.concat(parts, "  "))
  end

  -- Data rows: "<label> .... <cell1>  <cell2>  ..."
  local function leader_text(label)
    local target_w = label_col_w + 5
    local lw = visible_len(label)
    local fill = target_w - lw - 2  -- 2 = leading " " + trailing " "
    if fill < 3 then fill = 3 end
    return label .. " " .. string.rep(".", fill) .. " "
  end

  for _, r in ipairs(rows) do
    local lead = leader_text(r.label)
    local cell_strs = {}
    for j = 1, N do
      cell_strs[#cell_strs+1] = pad_to(r.cells[j] or with_yellow("-"), col_widths[j])
    end
    blight.output(lead .. table.concat(cell_strs, "  "))
  end

  -- ---------------- Separator + Lifetime footer (per-mob) ----------------

  local function sep_line(label)
    local prefix = "\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80 "
    local suffix_min = " "
    local label_visible = visible_len(label)
    local pad = render_w - visible_len(prefix) - label_visible - visible_len(suffix_min)
    if pad < 3 then pad = 3 end
    return (C_GREEN or "") .. prefix .. C_RESET .. label
           .. " " .. (C_GREEN or "") .. string.rep("\xe2\x94\x80", pad) .. C_RESET
  end

  local agg_count = (agg and agg.count) or 0
  local will_be_count = agg_count + 1  -- includes this fight

  if not is_first_mob_kill then
    -- Lifetime header — no "since DATE" suffix (dropped per design).
    blight.output(sep_line(C_BYELLOW .. "Lifetime ("
                  .. tostring(will_be_count) .. " fights)" .. C_RESET))

    -- Fold this snapshot in so the printed numbers reflect "including this fight".
    local sim_agg = {}
    for k, v in pairs(agg or {}) do sim_agg[k] = v end
    CombatHistory.update_agg(sim_agg, snap)

    local avg_dpr = CombatHistory.avg(sim_agg, "sum_dpr")
    local avg_time = CombatHistory.avg(sim_agg, "sum_combat_time")
    local avg_hits = CombatHistory.avg(sim_agg, "sum_hits")
    local avg_misses = CombatHistory.avg(sim_agg, "sum_misses")
    local avg_acc = 0
    if (avg_hits + avg_misses) > 0 then
      avg_acc = math.floor(avg_hits / (avg_hits + avg_misses) * 100 + 0.5)
    end
    local avg_eps = CombatHistory.avg(sim_agg, "sum_exp_per_sec")
    local avg_dmg_taken = CombatHistory.avg(sim_agg, "sum_damage_taken")

    blight.output(C_BYELLOW .. "  avg DPR " .. string.format("%.1f", avg_dpr)
                  .. STATUS_SEP .. "avg time " .. fmt_short_time(avg_time)
                  .. STATUS_SEP .. "avg acc " .. tostring(avg_acc) .. "%"
                  .. STATUS_SEP .. "avg exp/s " .. tostring(math.floor(avg_eps))
                  .. STATUS_SEP .. "avg dmg taken " .. tostring(math.floor(avg_dmg_taken))
                  .. C_RESET)

    local best_dpr = sim_agg.best_dpr
    local best_time = sim_agg.best_combat_time
    local best_acc = sim_agg.best_accuracy
    local best_eps = sim_agg.best_exp_per_sec
    local best_round = sim_agg.best_round_damage
    blight.output(C_BYELLOW .. "  best DPR " .. (best_dpr and string.format("%.2f", best_dpr) or "-")
                  .. STATUS_SEP .. "best time " .. (best_time and fmt_short_time(best_time) or "-")
                  .. STATUS_SEP .. "best acc " .. (best_acc and tostring(math.floor(best_acc * 100 + 0.5)) .. "%" or "-")
                  .. STATUS_SEP .. "best exp/s " .. (best_eps and tostring(math.floor(best_eps)) or "-")
                  .. STATUS_SEP .. "best round " .. (best_round and tostring(math.floor(best_round)) or "-")
                  .. C_RESET)

    -- Rank line (only when we have at least 3 fights so the bracket is meaningful)
    if will_be_count >= 3 then
      local parts = {}
      local p
      p = rank_phrase(snap.dpr, sim_agg.best_dpr, sim_agg.worst_dpr, false, "DPR")
      if p then table.insert(parts, p) end
      p = rank_phrase(snap.combat_time_sec, sim_agg.best_combat_time, sim_agg.worst_combat_time, true, "time")
      if p then table.insert(parts, p) end
      p = rank_phrase(snap.accuracy, sim_agg.best_accuracy, sim_agg.worst_accuracy, false, "acc")
      if p then table.insert(parts, p) end
      p = rank_phrase(snap.exp_per_sec, sim_agg.best_exp_per_sec, sim_agg.worst_exp_per_sec, false, "exp/s")
      if p then table.insert(parts, p) end
      if #parts > 0 then
        blight.output(C_BYELLOW .. "  rank vs lifetime: " .. C_RESET .. table.concat(parts, STATUS_SEP))
      end
    end
  end

  -- ---------------- Session footer (cross-mob, in-memory) ----------------
  --
  -- Record THIS kill into the session log first so session_stats() reflects
  -- "including this fight" (mirrors how Lifetime sim-folds the snapshot in
  -- above). prev_kills was captured BEFORE this record() so the multi-column
  -- table's "previous N" doesn't include the current kill.

  if SessionLog then
    SessionLog.record(snap)
    local sess = SessionLog.session_stats()
    if sess.kills > 0 then
      local kills_label = (sess.kills == 1) and "kill" or "kills"
      blight.output(sep_line(C_BYELLOW .. "Session (" .. tostring(sess.kills) .. " " .. kills_label
                    .. ", " .. fmt_short_time(sess.elapsed_sec) .. ")" .. C_RESET))
      local exp_sign = (sess.total_exp_diff >= 0) and "+" or ""
      blight.output(C_BYELLOW .. "  " .. tostring(sess.kills) .. " " .. kills_label .. "  "
                    .. tostring(math.floor(sess.total_damage)) .. " dmg  "
                    .. exp_sign .. tostring(math.floor(sess.total_exp_diff)) .. " xp  "
                    .. "avg time " .. fmt_short_time(sess.avg_time) .. "  "
                    .. "avg DPR " .. string.format("%.1f", sess.avg_dpr) .. C_RESET)
      if sess.mobs_summary_str and sess.mobs_summary_str ~= "" then
        blight.output(C_BYELLOW .. "  mobs: " .. sess.mobs_summary_str .. C_RESET)
      end
    end
  end

  -- Trailing blank for spacing
  blight.output("")

  -- Persist the snapshot for next time
  if CombatHistory and mob ~= "" then
    local ok, err = pcall(CombatHistory.record, char, mob, snap)
    if not ok and LOG_ERROR then
      LOG_ERROR("CombatHistory.record failed: " .. tostring(err))
    end
  end

  -- Reset the per-fight scratch fields the next fight inspects (preserve prior behavior)
  PROMPT_INFO.last_total_edamage = ""
  PROMPT_INFO.last_total_damage = ""
  PROMPT_INFO.last_total_rounds = ""
end

-- Export as globals
update_dpr_status = DPRCalculator.update_dpr_status
update_total_damage = DPRCalculator.update_total_damage
update_target_status = DPRCalculator.update_target_status
get_add_space = DPRCalculator.get_add_space
dpr_primary_loop = DPRCalculator.dpr_primary_loop
calc_battle_stats = DPRCalculator.calc_battle_stats
snapshot_kill_struct = DPRCalculator.snapshot_kill_struct

DPRCalculator = DPRCalculator

return DPRCalculator

