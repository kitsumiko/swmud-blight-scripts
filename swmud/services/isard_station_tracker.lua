-- isard_station cooldown tracking.
-- Writes the 22h cooldown directly into SKILL_TABLE_WIN on success so the
-- `De:` indicator shows the countdown without waiting for `delays`. Clears
-- on the server's ready-again announcement. No failure pattern is observed
-- in logs — the quest either completes or isn't attempted. Keys match
-- DELAYS_REMAP so `delays` overwrites our estimate with the server value.

local IsardStationTracker = {}
local ISARD_STATION_COOLDOWN = 79200  -- 22 hours

trigger.add("^The Imperial officer appears on the screen again\\. He listens to your report with worry etched across his face\\.", {}, function ()
  if SKILL_TABLE_WIN == nil or SKILL_DELAY_TABLE_WIN == nil then return end
  SKILL_TABLE_WIN["isard_station"] = os.time() + ISARD_STATION_COOLDOWN
  SKILL_DELAY_TABLE_WIN["isard_station"] = ISARD_STATION_COOLDOWN
end)

trigger.add("^You can use isard station again\\.", {}, function ()
  if SKILL_TABLE_WIN then SKILL_TABLE_WIN["isard_station"] = nil end
end)

IsardStationTracker = IsardStationTracker
_G.IsardStationTracker = IsardStationTracker
return IsardStationTracker
