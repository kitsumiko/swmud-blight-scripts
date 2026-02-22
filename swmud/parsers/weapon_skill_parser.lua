-- Weapon skill progress parser
-- Tracks "You feel better at using X. (Y%)" messages

local WeaponSkillParser = {}

if not WEAPON_SKILL_INFO then
  return WeaponSkillParser
end

-- Pattern: "You feel better at using san ni staff. (14%)" (skill name can be multi-word)
trigger.add("^You feel better at using (.+)%. %((%d+)%%)", {}, function(m)
  if m and m[2] and m[3] then
    local weapon = m[2]:gsub("^%s*(.-)%s*$", "%1")
    local pct = tonumber(m[3]) or 0
    WEAPON_SKILL_INFO.last_weapon = weapon
    WEAPON_SKILL_INFO.last_pct = pct
    if not WEAPON_SKILL_INFO.session_gains[weapon] then
      WEAPON_SKILL_INFO.session_gains[weapon] = {}
    end
    table.insert(WEAPON_SKILL_INFO.session_gains[weapon], pct)
  end
end)

return WeaponSkillParser
