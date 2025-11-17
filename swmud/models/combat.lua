-- Combat data models and structures

local Combat = {}

-- Damage tier lookup table
Combat.tier_lookup = {t0 = 0, t1 = 2, t27 = 130}

local function populate_tiers()
  for i=2,26,1 do
    Combat.tier_lookup["t"..tostring(i)] = 5*(i-1)+2
  end
end
populate_tiers()

-- BSENSE tiers
Combat.BSENSE_TIERS = {"in top shape", "in decent shape", "slightly injured", "hurting", "badly injured", "terribly injured", "near death"}
Combat.BSENSE_TIERS_TOP = {100, 85, 70, 55, 40, 25, 10}
Combat.BSENSE_STR = "("..table.concat(Combat.BSENSE_TIERS, "|")..")"
Combat.BSENSE_REGEX = regex.new("^" .. P_STR .. " is ".. Combat.BSENSE_STR)

-- Target management
function Combat.reset_target(target_name)
  DPR_INFO[target_name] = {total = 0,}
  DPR_INFO["status_line"] = "Target: None"
  TARGET_INFO[target_name] = SHALLOW_COPY(BASE_TARGET_INFO)
  TARGET_INFO["target_start_xp"] = PROMPT_INFO.exp
  TARGET_INFO.start_combat_ts = os.time()
end

function Combat.init_target(target_name)
  if not SET_CONTAINS(TARGET_INFO, target_name) then
    Combat.reset_target(target_name)
  end
  if not SET_CONTAINS(DPR_INFO, target_name) then
    Combat.reset_target(target_name)
  end
  if TARGET_INFO[target_name]["dead"] == 1 then
    Combat.reset_target(target_name)
  end
end

-- Export as globals
tier_lookup = Combat.tier_lookup
BSENSE_TIERS = Combat.BSENSE_TIERS
BSENSE_TIERS_TOP = Combat.BSENSE_TIERS_TOP
BSENSE_STR = Combat.BSENSE_STR
BSENSE_REGEX = Combat.BSENSE_REGEX
init_target = Combat.init_target
reset_target = Combat.reset_target

return Combat

