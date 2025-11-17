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
      DPR_INFO[target][source] = {damage = 0, rounds = 0, dpr = 0, ndpr = 0,}
    end
  end
  if new_round==1 then
    if target == nil and TARGET_INFO["last_target"] ~= nil then
      if SET_CONTAINS(DPR_INFO, TARGET_INFO["last_target"]) then
        if SET_CONTAINS(DPR_INFO[TARGET_INFO["last_target"]], source) then
          DPR_INFO[TARGET_INFO["last_target"]][source]["rounds"] = DPR_INFO[TARGET_INFO["last_target"]][source]["rounds"] + 1
        end
      end
    else
      DPR_INFO[target][source]["rounds"] = DPR_INFO[target][source]["rounds"] + 1
    end
  end
  if target == TARGET_INFO["last_target"] then
    TARGET_INFO.unrec_damage = TARGET_INFO.unrec_damage + tier_lookup[damage_tier]
  end
  if target ~= nil then
    DPR_INFO[target][source]["damage"] = DPR_INFO[target][source]["damage"] + tier_lookup[damage_tier]
    DPR_INFO[target][source]["dpr"] = ROUND_FLOAT(DPR_INFO[target][source]["damage"] / DPR_INFO[target][source]["rounds"], 2)
    if SET_CONTAINS(DPR_INFO[target], "You") then
      DPR_INFO[target][source]["ndpr"] = ROUND_FLOAT(DPR_INFO[target][source]["damage"] / DPR_INFO[target]["You"]["rounds"], 2)
    end
  end
  DPRCalculator.update_dpr_status()
  DPRCalculator.update_target_status()
  return tier_lookup[damage_tier]
end

function DPRCalculator.calc_battle_stats()
  tasks.sleep(0.5)
  blight.output(C_BYELLOW .. "####### Combat Summary #######")
  blight.output(C_BYELLOW .. "Target: " .. PROMPT_INFO.last_kill .. C_RESET)
  blight.output(C_BYELLOW .. "Damage: " .. tostring(PROMPT_INFO.last_total_damage) .. C_RESET .. STATUS_SEP ..C_BYELLOW .. "DPR: ".. PROMPT_INFO.total_dpr .. C_RESET)
  blight.output(C_BYELLOW .. "eDamage: " .. tostring(PROMPT_INFO.last_total_edamage) .. C_RESET .. STATUS_SEP ..C_BYELLOW .. "eDPR: " .. PROMPT_INFO.edpr .. C_RESET)
  local exp_diff = tostring(tonumber(PROMPT_INFO.exp) - tonumber(TARGET_INFO.target_start_xp))
  local combat_diff = os.difftime(PROMPT_INFO.last_kill_ts, TARGET_INFO.start_combat_ts) + 4
  local exp_per_sec = math.floor(exp_diff / combat_diff)
  blight.output(C_BYELLOW .. "Experience: " .. exp_diff .. STATUS_SEP .. C_BYELLOW .. "Exp per Second: " .. tostring(exp_per_sec) .. C_RESET)
  blight.output(C_BYELLOW .. "Combat Time: ".. os.date("!%H:%M:%S", combat_diff) .. C_RESET .. STATUS_SEP .. C_BYELLOW .. "Rounds: " .. tostring(PROMPT_INFO.last_total_rounds) .. C_RESET)
  blight.output("")
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

DPRCalculator = DPRCalculator

return DPRCalculator

