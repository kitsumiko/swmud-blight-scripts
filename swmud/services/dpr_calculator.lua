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

function DPRCalculator.dpr_primary_loop(source, damage_tier, target, new_round)
  if target ~= nil then
    init_target(target, source)
    if source == "You" then
      if TARGET_INFO["last_target"] ~= target then
        reset_target(target)
      end
      TARGET_INFO["last_target"] = target
    end
    if target == "You" or target=="you" then
      TARGET_INFO["last_target"] = source
    end
    if not SET_CONTAINS(DPR_INFO[target], source) then
      DPR_INFO[target][source] = {damage = 0, rounds = 0, dpr = 0, ndpr = 0,
                                  hits = 0, misses = 0,
                                  best_round_damage = 0, current_round_damage = 0,}
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
      if (s.current_round_damage or 0) > (s.best_round_damage or 0) then
        s.best_round_damage = s.current_round_damage
      end
      s.current_round_damage = 0
      s.rounds = s.rounds + 1
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

local function delta(curr_val, prev_val, lower_is_better)
  if prev_val == nil then return "" end
  return DELTA_COLOR(num(curr_val) - num(prev_val), lower_is_better, num(prev_val))
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

  local prev = nil
  local agg = nil
  if CombatHistory and mob ~= "" then
    prev = CombatHistory.get_previous(char, mob)
    agg = CombatHistory.get_aggregates(char, mob)
  end

  -- Layout sizing
  local term_w = 80
  if blight.terminal_dimensions then
    local w, _ = blight.terminal_dimensions()
    if w and w > 0 then term_w = w end
  end
  -- total_width sized in the rendering section below, after we know delta_col

  -- Build the row list first so we can size the delta column to the longest
  -- "label ... value" combo, keeping the dot leader minimal (always 3 dots).
  local rows = {}
  local function add_row(label, value, delta_text)
    rows[#rows+1] = {
      label = C_BYELLOW .. label .. C_RESET,
      value = C_BYELLOW .. value .. C_RESET,
      delta = delta_text or "",
    }
  end

  -- Target row (mob name on left, prev-kill timestamp as the "delta")
  do
    local right = ""
    if prev then
      right = C_BYELLOW .. "prev kill: " .. os.date("%Y-%m-%d %H:%M:%S", prev.kill_ts) .. C_RESET
    end
    add_row("Target", mob, right)
  end

  add_row("Damage", fmt_int(snap.damage),
          prev and delta(snap.damage, prev.damage, false) or "")
  add_row("DPR", tostring(snap.dpr),
          prev and delta(snap.dpr, prev.dpr, false) or "")
  add_row("eDamage", fmt_int(snap.edamage),
          prev and delta(snap.edamage, prev.edamage, true) or "")
  add_row("eDPR", tostring(snap.edpr),
          prev and delta(snap.edpr, prev.edpr, true) or "")

  if (snap.hits + snap.misses) > 0 then
    add_row("Hit / Miss",
            tostring(snap.hits) .. " / " .. tostring(snap.misses),
            (prev and prev.hits ~= nil) and delta(snap.hits, prev.hits, false) or "")
    local acc_pct = math.floor(snap.accuracy * 100 + 0.5)
    local acc_delta = ""
    if prev and prev.accuracy ~= nil then
      local prev_acc = math.floor(prev.accuracy * 100 + 0.5)
      acc_delta = delta(acc_pct, prev_acc, false) .. "%"
    end
    add_row("Accuracy", tostring(acc_pct) .. "%", acc_delta)
  end

  if snap.best_round_damage > 0 then
    add_row("Best round", fmt_int(snap.best_round_damage),
            (prev and prev.best_round_damage ~= nil) and
              delta(snap.best_round_damage, prev.best_round_damage, false) or "")
  end

  if snap.mob_hp_estimate > 0 then
    local d = ""
    if prev and prev.mob_hp_estimate and prev.mob_hp_estimate > 0 then
      d = delta(snap.mob_hp_estimate, prev.mob_hp_estimate, false)
    end
    add_row("Mob HP est", "~" .. fmt_int(snap.mob_hp_estimate), d)
  end

  if snap.damage_taken > 0 then
    add_row("Damage taken", fmt_int(snap.damage_taken),
            (prev and prev.damage_taken ~= nil) and
              delta(snap.damage_taken, prev.damage_taken, true) or "")
  end

  if snap.hp_cost ~= 0 then
    -- HP cost is signed (typically negative). "Less negative" = lost less HP =
    -- better, so treat as higher-is-better.
    add_row("HP cost", tostring(math.floor(snap.hp_cost)),
            (prev and prev.hp_cost ~= nil) and
              delta(snap.hp_cost, prev.hp_cost, false) or "")
  end

  if snap.credits_gained ~= 0 then
    local val = (snap.credits_gained >= 0 and "+" or "") .. tostring(math.floor(snap.credits_gained))
    add_row("Credits", val,
            (prev and prev.credits_gained ~= nil) and
              delta(snap.credits_gained, prev.credits_gained, false) or "")
  end

  if snap.force_deflections > 0 then
    add_row("Force deflections", fmt_int(snap.force_deflections),
            (prev and prev.force_deflections ~= nil) and
              delta(snap.force_deflections, prev.force_deflections, false) or "")
  end

  if snap.weapon_skill ~= "" and snap.weapon_skill_pct > 0 then
    local d = ""
    if prev and prev.weapon_skill == snap.weapon_skill and prev.weapon_skill_pct then
      d = delta(snap.weapon_skill_pct, prev.weapon_skill_pct, false) .. "%"
    end
    add_row("Weapon skill",
            snap.weapon_skill .. " (" .. tostring(snap.weapon_skill_pct) .. "%)", d)
  end

  if snap.exp_diff ~= 0 then
    add_row("Experience", tostring(math.floor(snap.exp_diff)),
            prev and delta(snap.exp_diff, prev.exp_diff, false) or "")
    add_row("Exp/s", tostring(snap.exp_per_sec),
            prev and delta(snap.exp_per_sec, prev.exp_per_sec, false) or "")
  end

  add_row("Combat Time", fmt_time(snap.combat_time_sec),
          prev and delta(snap.combat_time_sec, prev.combat_time_sec, true) or "")
  add_row("Rounds", tostring(snap.rounds),
          prev and delta(snap.rounds, prev.rounds, true) or "")

  -- Compute column widths from row content so labels left-align and values
  -- right-align in clean, equal-width columns regardless of which conditional
  -- rows fired.
  local SEP_LEN = 5  -- " ... "
  local label_col_w = 0
  local value_col_w = 0
  local max_delta = 0
  for _, r in ipairs(rows) do
    local lw = visible_len(r.label)
    local vw = visible_len(r.value)
    if lw > label_col_w then label_col_w = lw end
    if vw > value_col_w then value_col_w = vw end
    local dw = visible_len(r.delta)
    if dw > max_delta then max_delta = dw end
  end
  local delta_col = label_col_w + SEP_LEN + value_col_w + 2  -- 2-space gutter
  local total_width = math.min(term_w, delta_col + math.max(max_delta, 30))

  -- Header. When this is the first kill of the mob, drop the right-side marker
  -- and the lifetime footer below — there's no comparison to make, so those
  -- lines just take up space without adding info.
  local is_first_kill = (prev == nil)
  do
    local left_header = C_BYELLOW .. "####### Combat Summary #######" .. C_RESET
    if is_first_kill then
      blight.output(left_header)
    else
      local right_header = C_BYELLOW .. "##### vs Last Fight (" .. fmt_ago(prev.kill_ts) .. ") #####" .. C_RESET
      local pad = math.max(2, delta_col - visible_len(left_header))
      blight.output(left_header .. string.rep(" ", pad) .. right_header)
    end
  end

  for _, r in ipairs(rows) do
    blight.output(leader_row(r.label, r.value, label_col_w, value_col_w, r.delta))
  end

  -- ---------------- Lifetime footer ----------------
  local agg_count = (agg and agg.count) or 0
  local will_be_count = agg_count + 1  -- this fight will increment count when we record it below

  -- Build separator that fits the total render width
  local function sep_line(label)
    local prefix = "\xe2\x94\x80\xe2\x94\x80\xe2\x94\x80 "
    local suffix_min = " "
    local label_visible = visible_len(label)
    local pad = total_width - visible_len(prefix) - label_visible - visible_len(suffix_min)
    if pad < 3 then pad = 3 end
    return (C_GREEN or "") .. prefix .. C_RESET .. label
           .. " " .. (C_GREEN or "") .. string.rep("\xe2\x94\x80", pad) .. C_RESET
  end

  if not is_first_kill then
    -- Lifetime header reflects the count after this fight is recorded.
    local first_ts = (agg and agg.first_kill_ts) or snap.kill_ts
    local since_str = os.date("%Y-%m-%d", first_ts)
    blight.output(sep_line(C_BYELLOW .. "Lifetime ("
                  .. tostring(will_be_count) .. " fights, since " .. since_str .. ")" .. C_RESET))

    -- We compute lifetime stats *after* folding this snapshot in, so the printed
    -- numbers reflect "including this fight".
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
    -- 100% = matches best-ever on that metric, 0% = matches worst-ever.
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

  -- Trailing blank for spacing — but only when there's actually a footer to
  -- separate from. First-kill summaries are tight and don't need the gap.
  if not is_first_kill then
    blight.output("")
  end

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

