-- damage table --
-- /lua mud.output("You tickle Factory Worker lightly with your fist.")
-- DAMAGE   SHARP                  BLUNT                  RANGED
-- 0  -  4: tap                    tap innocently         scratch
-- 5  -  9: tickle                 tickle lightly         nick lightly
-- 10 - 14: sting sharply          sting                  nick
-- 15 - 19: graze                  hurt mildly            injure
-- 20 - 24: cut                    squish                 injure severely
-- 25 - 29: hack                   strike                 wound
-- 30 - 34: slice                  strike brutally        wound badly
-- 35 - 39: slice horribly         send a bone crushing blow    nail
-- 40 - 44: shear                  knock                  damage
-- 45 - 49: shear to pieces        slam mercilessly       damage terribly
-- 50 - 54: strike letting blood   blast powerfully       lambaste
-- 55 - 59: carve                  beat down              pierce
-- 60 - 64: hew                    clobber                pierce thoroughly
-- 65 - 69: rend                   pound                  perforate
-- 70 - 74: gash                   shatter                wreck
-- 75 - 79: bisect                 demolish               pummel
-- 80 - 84: cleave                 batter                 punish
-- 85 - 89: mutilate               wallop                 raze
-- 90 - 94: dismember              pulverize              ruin
-- 95 - 99: maim                   maim                   decimate
-- 100-104: ravage                 ravage                 obliterate
-- 105-109: destroy                destroy                annihilate
-- 110-114: destroy utterly        destroy utterly        annihilate completely
-- 115-119: devastate              devastate              devastate
-- 120-124: massacre               massacre               massacre
--    125+: lay waste to           lay waste to           lay waste to

-- {"Factory Worker": {"You": {"damage":,"rounds": etc...}, "total": x}}

-- damage tiers
tier_lookup = {t0 = 0,
                t1 = 2,
                t27 = 130,}

local function populate_tiers()
  for i=2,26,1 do
    tier_lookup["t"..tostring(i)] = 5*(i-1)+2
  end
end
populate_tiers()

-- bsense tiers
BSENSE_TIERS = {"in top shape", "in decent shape", "slightly injured", "hurting", "badly injured", "terribly injured", "near death"}
BSENSE_TIERS_TOP = {100, 85, 70, 55, 40, 25, 10}
BSENSE_STR = "("..table.concat(BSENSE_TIERS, "|")..")"
BSENSE_REGEX = regex.new("^" .. P_STR .. " is ".. BSENSE_STR)

-- dpr primary functions --
local function reset_target(target_name)
  DPR_INFO[target_name] = {total = 0,}
  DPR_INFO["status_line"] = "Target: None"
  TARGET_INFO[target_name] = SHALLOW_COPY(BASE_TARGET_INFO)
  TARGET_INFO["target_start_xp"] = PROMPT_INFO.exp
  TARGET_INFO.start_combat_ts = os.time()
end

local function init_target(target_name)
  --- init the target structure  ---
  if not SET_CONTAINS(TARGET_INFO, target_name) then
    reset_target(target_name)
  end
  --- init the damage structure ---
  if not SET_CONTAINS(DPR_INFO, target_name) then
    -- new target
    reset_target(target_name)
  end
  if TARGET_INFO[target_name]["dead"] == 1 then
    reset_target(target_name)
  end
end

local function update_dpr_status()
  -- this function will calculate the dpr and update the status variables
  -- this is only for dpr out, the calc target one will update based on who is selected
  -- two types of dpr
    -- dpr based on the sources rounds
    -- dpr based on "You" rounds - which is the pc rounds
      -- for example, bouncing causes assists to not attack the first round
  local base_str = ""
  if SET_CONTAINS(DPR_INFO, TARGET_INFO['last_target']) then
    -- players dpr first
    local target = TARGET_INFO['last_target']
    local total_dpr = 0
    local assist_dpr = 0
    if SET_CONTAINS(DPR_INFO[target], "You") then
      if DPR_INFO[target]["You"]["dpr"]~=nil then
        base_str = base_str.."You: ".. DPR_COLOR(DPR_INFO[target]["You"]["dpr"])
        total_dpr = total_dpr + DPR_INFO[target]["You"]["dpr"]
      end
    end
    -- other dpr sources
    for source, s_info in pairs(DPR_INFO[target]) do
      if type(s_info) ~= "number" then
        if source ~= "You" then
          if s_info["dpr"]~=nil then
            base_str = base_str.." "..source..": ".. DPR_COLOR(s_info["dpr"]) -- DPR_COLOR(s_info["ndpr"]).."/"..DPR_COLOR(s_info["dpr"])
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

function update_total_damage(target)
  if SET_CONTAINS(DPR_INFO, target) then
    -- target name and damage sets
    local total_damage = 0
    for source, s_info in pairs(DPR_INFO[target]) do
      if type(s_info) ~= "number" then
        total_damage = total_damage + s_info["damage"]
      end
    end
    DPR_INFO[target]["total"] = total_damage
  end
end

local function process_health_table(clean_table)
  local avg_total_health = 0
  local last_health_pct = 0
  local health_added = 0
  local health_str = ""
  if TABLE_LENGTH(clean_table)>1 then
    -- table has format {{"100%", <damage done to target>},}
    -- formnat table, calc totals
    local health_x = {}
    local damage_x = {}
    for k,r_v in pairs(clean_table) do
      local v = {}
      for k1, v1 in string.gmatch(r_v, "(%w+)=(%w+)") do
        v[k1] = tonumber(v1)
      end
      -- ensure the maximum damage value is associated with the last health reading
      if health_x[#health_x] ~= v["health"] then
        health_x[#health_x+1] = v["health"]
      end
      if TABLE_LENGTH(health_x) ~= TABLE_LENGTH(damage_x) then
        damage_x[#damage_x+1] = v["damage"]
      end
    end
    if TABLE_LENGTH(health_x)>1 then
      -- logic to compute the newest total and health estimates and form the string
      local diff_health = {}
      local diff_damage = {}
      for k,v in ipairs(health_x) do
        if k > 1 then
          -- this comparison prevents bad data when a target heals
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

function get_add_space(line_flag)
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

function update_target_status()
  -- this function will calc any target info for the status line
  -- this includes dpr
  if SET_CONTAINS(DPR_INFO, TARGET_INFO['last_target']) then
    update_total_damage(TARGET_INFO['last_target'])
    -- target name and damage sets
    local target = TRIM_STRING(TARGET_INFO["last_target"])
    local short_name = TRIM_STRING(CHAR_DATA.character_name)
    local name_max = math.max(string.len(target), string.len(short_name))
    local name_pad = string.rep(" ", name_max - string.len(target))
    local base_str = "T: "..target..name_pad
    -- target health information
    local health_str = "H: "
    local health_added = 0
    if TARGET_INFO[target]["dead"] == 1 then
      PROMPT_INFO.thp_length = string.len("0") + string.len(TARGET_INFO.total_health)
      local add_space = get_add_space('c')
      health_str = health_str .. "0/" .. tostring(TARGET_INFO.total_health) .. PAD_PERCENT(0.0, add_space)
    else
      local clean_table = REMOVE_DUPLICATES(TARGET_INFO[target]["h_hscan"])
      health_added = process_health_table(clean_table)
      local clean_table = REMOVE_DUPLICATES(TARGET_INFO[target]["h_bsense"])
      if health_added==0  and TABLE_LENGTH(clean_table)>1 then
        health_added = process_health_table(clean_table)
      end
      local clean_table = REMOVE_DUPLICATES(TARGET_INFO[target]["h_blook"])
      if health_added==0  and TABLE_LENGTH(clean_table)>1 then
        health_added = process_health_table(clean_table)
      end
      if health_added==0 then
        health_str = health_str .. "Calculating..."
      else
        local current_health_num = TARGET_INFO.target_health - TARGET_INFO.unrec_damage
        local current_health = GET_COLOR(TARGET_INFO.target_pct) .. tostring(current_health_num) .. C_RESET
        PROMPT_INFO.thp_length = string.len(tostring(current_health_num)) + string.len(tostring(TARGET_INFO.total_health))
        local add_space = get_add_space('c')
        health_str = health_str .. current_health .. "/" .. tonumber(TARGET_INFO.total_health) .. PAD_PERCENT(current_health_num/TARGET_INFO.total_health, add_space)
      end
      
    end
    -- target dpr to you
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

local function calc_battle_stats()
  tasks.sleep(0.5)
  blight.output(C_BYELLOW .. "####### Combat Summary #######")
  blight.output(C_BYELLOW .. "Target: " .. PROMPT_INFO.last_kill .. C_RESET)
  blight.output(C_BYELLOW .. "Damage: " .. tostring(PROMPT_INFO.last_total_damage) .. C_RESET .. STATUS_SEP ..C_BYELLOW .. "DPR: ".. PROMPT_INFO.total_dpr .. C_RESET)
  blight.output(C_BYELLOW .. "eDamage: " .. tostring(PROMPT_INFO.last_total_edamage) .. C_RESET .. STATUS_SEP ..C_BYELLOW .. "eDPR: " .. PROMPT_INFO.edpr .. C_RESET)
  local exp_diff = tostring(tonumber(PROMPT_INFO.exp) - tonumber(TARGET_INFO.target_start_xp))
  local combat_diff = os.difftime(PROMPT_INFO.last_kill_ts, TARGET_INFO.start_combat_ts) + 4 -- add 4 because of target resets
  local exp_per_sec = math.floor(exp_diff / combat_diff)
  blight.output(C_BYELLOW .. "Experience: " .. exp_diff .. STATUS_SEP .. C_BYELLOW .. "Exp per Second: " .. tostring(exp_per_sec) .. C_RESET)
  blight.output(C_BYELLOW .. "Combat Time: ".. os.date("!%H:%M:%S", combat_diff) .. C_RESET .. STATUS_SEP .. C_BYELLOW .. "Rounds: " .. tostring(PROMPT_INFO.last_total_rounds) .. C_RESET)
  blight.output("")
  PROMPT_INFO.last_total_edamage = ""
  PROMPT_INFO.last_total_damage = ""
  PROMPT_INFO.last_total_rounds = ""
end

trigger.add("^"..P_STR.." staggers and falls to the ground\\.\\.\\. dead\\.", {}, function(m, line)
  PROMPT_INFO.last_kill = m[2]
  PROMPT_INFO.last_kill_ts = os.time()
  TARGET_INFO[m[2]]["dead"] = 1
  update_target_status()
  update_total_damage("you")
  if SET_CONTAINS(DPR_INFO, "you") then
    PROMPT_INFO.total_edamage = DPR_INFO["you"]["total"]
    PROMPT_INFO.last_total_edamage = PROMPT_INFO.total_edamage
  end
  update_total_damage(m[2])
  if SET_CONTAINS(DPR_INFO, m[2]) then
    PROMPT_INFO.total_damage = DPR_INFO[m[2]]["total"]
    PROMPT_INFO.last_total_damage = PROMPT_INFO.total_damage
  end
  if SET_CONTAINS(DPR_INFO, "you") then
    if SET_CONTAINS(DPR_INFO["you"], m[2]) then
      PROMPT_INFO.total_rounds = DPR_INFO["you"][m[2]]["rounds"]
      PROMPT_INFO.last_total_rounds = PROMPT_INFO.total_rounds
    end
  end
  mud.send("", {gag=1,})
  tasks.spawn(calc_battle_stats)
end)

function dpr_primary_loop(source, damage_tier, target, new_round)
  -- blight.output("Source: "..tostring(source))
  -- blight.output("Damage: "..tostring(damage_tier))
  -- blight.output("Target: "..tostring(target))
  -- target can be nil
  if target ~= nil then
    init_target(target, source)
    if source == "You" then
      -- we have a new last_target that player is attacking
      if TARGET_INFO["last_target"] ~= target then
        reset_target(target)
      end
      TARGET_INFO["last_target"] = target
    end
    if target == "You" or target=="you" then
      TARGET_INFO["last_target"] = source
    end
    --- now the internal target updates ---
    if not SET_CONTAINS(DPR_INFO[target], source) then
      -- new source damager
      DPR_INFO[target][source] = {damage = 0,
                                  rounds = 0,
                                  dpr = 0,
                                  ndpr = 0,}
    end
  end
  --- advance the damage structure ---
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
      -- we are in combat with the mob, so calc the normalized dpr per my rounds
      DPR_INFO[target][source]["ndpr"] = ROUND_FLOAT(DPR_INFO[target][source]["damage"] / DPR_INFO[target]["You"]["rounds"], 2)
    end
  end
  update_dpr_status()
  update_target_status()
  return tier_lookup[damage_tier]
end

-- damage tier functions --
local function damage_trigger(new_exp, tier, priority, skip_round)
  -- blight.output(tostring(priority).. " "..tostring(tier).." "..new_exp)
  local new_round = 1
  if skip_round ~= nil then
    new_round = 0
  end
  new_info = {r = regex.new(new_exp),
              t = "t"..tostring(tier),
              n = new_round,}
  table.insert(DPR_TRIGGER_TABLE["t"..tostring(priority)], new_info)
  -- DPR_TRIGGER_TABLE["t"..tostring(priority)]
  -- trigger.add(reg_exp, {}, function (m)
  --   dpr_primary_loop(m[2], tostring(tier), m[4])
  -- end)
end

local function blank_trigger(full_exp, tier, skip_round)
  local new_exp = "^"..full_exp..".*"
  damage_trigger(new_exp, tier, 1, skip_round)
end 

local function exact_trigger(full_exp, tier, skip_round)
  local new_exp = "^"..P_STR..full_exp..".*"
  damage_trigger(new_exp, tier, 1, skip_round)
end

local function std_trigger(mid_exp, tier, skip_round)
  local new_exp = "^"..P_STR.." "..mid_exp.." "..P_STR.." with"
  damage_trigger(new_exp, tier, 1, skip_round)
end

local function split_trigger(mid_exp, end_exp, tier, skip_round)
  local new_exp = "^"..P_STR.." "..mid_exp.." "..P_STR.." "..end_exp
  damage_trigger(new_exp, tier, 0, skip_round)
end

-- hscan catch
-- The scanner beeps : Smuggler is at 25% health.
trigger.add("^The scanner beeps : "..P_STR.." is at ([^ ]*) health", {}, function (m)
  TARGET_INFO.unrec_damage = 0
  init_target(m[2])
  update_total_damage(m[2])
  if SET_CONTAINS(DPR_INFO, TARGET_INFO['last_target']) then
    if DPR_INFO[TARGET_INFO['last_target']]["total"] ~= nil then
      table.insert(TARGET_INFO[m[2]]["h_hscan"], "health=" .. m[3] .. ", damage=" .. tostring(DPR_INFO[TARGET_INFO['last_target']]["total"]))
    end
  end
end)

blank_trigger(".* sidesteps your poorly planned attack", 0)
blank_trigger("You miss", 0)
blank_trigger("You deal a deadly blow.*to empty space", 0)
blank_trigger("You decide to daydream a moment instead of attack", 0)
blank_trigger(".* never knew what missed it", 0)
blank_trigger(".* dodges your inept attack", 0)
blank_trigger("A swing and a miss.*Strike 1 for you", 0)
std_trigger("(missed)", 0)
split_trigger("(misses)", "with a blaster bolt\\.", 0)
split_trigger("(misses) its attack on ", "\\.", 0)
split_trigger("(tried to punch)", "but missed completely", 0, 1)
std_trigger("(taps|scratches|tap|scratch)", 1)
split_trigger("(tap|taps)", "(innocently|innocently)", 1)
std_trigger("(tickle|tickles)", 2)
split_trigger("(tickle|nick|tickles|nicks)", "(lightly|lightly|lightly|lightly)", 2)
split_trigger("(sting|stings)", "(sharply|sharply)", 3)
std_trigger("(sting|nick|stings|nicks)", 3)
std_trigger("(graze|injure|grazes|injures)", 4)
split_trigger("(hurt|hurts)", "(mildly|mildly)", 4)
std_trigger("(cut|squish|cuts|squishes)", 5)
split_trigger("(injure|injures)", "(severely|severely)", 5)
std_trigger("(hack|strike|wound|hacks|strikes|wounds)", 6)
std_trigger("(slice|slices)", 7)
split_trigger("(strike|wound|strikes|wounds)", "(brutally|badly|brutally|badly)", 7)
split_trigger("(send|slice|sends|slices)", "(a bone crushing blow|horribly|a bone crushing blow|horribly)", 8)
std_trigger("(nail|nails)", 8)
std_trigger("(shear|knock|damage|shears|knocks|damages)", 9)
split_trigger("(shear|knock|damage|shears|knocks|damages)", "(to pieces|mercilessly|terribly|to pieces|mercilessly|terribly)", 10)
split_trigger("(strike|blast|strikes|blasts)", "(letting blood|powerfully|letting blood|powerfully)", 11)
std_trigger("(lambaste|lambastes)", 11)
std_trigger("(carve|pierce|carves|pierces)", 12)
split_trigger("(beat|beats)", "(down|down)", 12)
std_trigger("(hew|clobber|hews|clobbers)", 13)
split_trigger("(pierce|pierces)", "(thoroughly|thoroughly)", 13)
std_trigger("(rend|pound|perforate|rends|pounds|perforates)", 14)
std_trigger("(gash|shatter|wreck|gashs|shatters|wrecks)", 15)
std_trigger("(bisect|demolish|pummel|bisects|demolishes|pummels)", 16)
std_trigger("(cleave|batter|punish|cleaves|batters|punishes)", 17)
std_trigger("(mutilate|wallop|raze|mutilates|wallops|razes)", 18)
std_trigger("(dismember|pulverize|ruin|dismembers|pulverizes|ruins)", 19)
std_trigger("(maim|decimate|maims|decimates)", 20)
std_trigger("(ravage|obliterate|ravages|obliterates)", 21)
std_trigger("(destroy|annihilate|destroys|annihilates)", 22)
split_trigger("(destroy|annihilate|destroys|annihilates)", "(utterly|completely|utterly|completely)", 23)
std_trigger("(devastate|devastates)", 24)
std_trigger("(massacre|massacres)", 25)
std_trigger("(lay waste to|lays waste to)", 25)
