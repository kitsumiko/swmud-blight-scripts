-- hack_bank cooldown tracking.
-- Writes the 24h cooldown directly into SKILL_TABLE_WIN on success so the
-- `De:` indicator shows the countdown without waiting for `delays`. Handles
-- explicit failure (populates SKILL_TABLE_FAIL) and clears on the server's
-- ready-again announcement. Keys match DELAYS_REMAP in skill_tracker.lua so
-- `delays` overwrites our estimate with server-authoritative remaining time.

local HackBankTracker = {}
local HACK_BANK_COOLDOWN = 86400  -- 24 hours

trigger.add("^You have managed to funnel .* credits into your account\\.", {}, function ()
  if SKILL_TABLE_WIN == nil or SKILL_DELAY_TABLE_WIN == nil then return end
  SKILL_TABLE_WIN["hack_bank"] = os.time() + HACK_BANK_COOLDOWN
  SKILL_DELAY_TABLE_WIN["hack_bank"] = HACK_BANK_COOLDOWN
  if SKILL_TABLE_FAIL then SKILL_TABLE_FAIL["hack_bank"] = nil end
end)

trigger.add("^BANK> You fail to hack the bank\\.", {}, function (m, line)
  blight.output("("..C_BRED.."FAILURE"..C_RESET.."): hack_bank - "..line:raw())
  if SKILL_TABLE_FAIL then SKILL_TABLE_FAIL["hack_bank"] = os.time() end
end)

trigger.add("^You can use hack bank again\\.", {}, function ()
  if SKILL_TABLE_WIN then SKILL_TABLE_WIN["hack_bank"] = nil end
  if SKILL_TABLE_FAIL then SKILL_TABLE_FAIL["hack_bank"] = nil end
end)

HackBankTracker = HackBankTracker
_G.HackBankTracker = HackBankTracker
return HackBankTracker
