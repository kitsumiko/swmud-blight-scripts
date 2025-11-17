-- Damage message parsing and triggers

local DamageParser = {}

local function damage_trigger(new_exp, tier, priority, skip_round)
  local new_round = 1
  if skip_round ~= nil then
    new_round = 0
  end
  local new_info = {r = regex.new(new_exp),
              t = "t"..tostring(tier),
              n = new_round,}
  table.insert(DPR_TRIGGER_TABLE["t"..tostring(priority)], new_info)
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

-- Death trigger
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

-- hscan catch
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

-- Damage triggers
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

-- Export as global
DamageParser = DamageParser

return DamageParser

