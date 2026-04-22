-- Droid construction / modification cooldown tracking.
-- Captures the droid type on `droid_construct <type>` and, on the success
-- line, writes the correct per-type cooldown (15/30/60 min) directly into
-- SKILL_TABLE_WIN / SKILL_DELAY_TABLE_WIN so the `De:` prompt indicator
-- shows the countdown without waiting for the next `delays` poll.
-- dmodify success seeds a 180s estimate that `delays` overwrites with
-- server-authoritative remaining time. Keys match DELAYS_REMAP in
-- skill_tracker.lua so the two sources stay in sync.

local DroidCooldownTracker = {}

local DROID_CONSTRUCT_COOLDOWNS = {
  -- 15 min
  slr = 900, mlr = 900, spydroid = 900, xlr = 900,
  -- 30 min
  c3 = 1800, t5 = 1800, gnk = 1800, b1 = 1800, rx = 1800, g2 = 1800,
  r4p = 1800, nr = 1800, fx = 1800, ["if"] = 1800, ig = 1800,
  alr = 1800, mse = 1800,
  -- 60 min
  ra = 3600, blx = 3600, t7 = 3600, c5 = 3600, s9e = 3600, b2 = 3600,
  dd = 3600, oom = 3600, r8 = 3600, ["2-1c"] = 3600, hk = 3600, ["fa-5"] = 3600,
}

local DMODIFY_COOLDOWN = 180

local pending_droid_type = nil

local function register_cooldown(key, seconds)
  if SKILL_TABLE_WIN == nil or SKILL_DELAY_TABLE_WIN == nil then return end
  SKILL_TABLE_WIN[key] = os.time() + seconds
  SKILL_DELAY_TABLE_WIN[key] = seconds
end

alias.add("^droid_construct (.+)$", function (m)
  if m and m[2] and m[2] ~= "" then
    local first = m[2]:match("^(%S+)")
    if first then pending_droid_type = first:lower() end
    mud.send("droid_construct " .. m[2])
  end
end)

trigger.add("^You slowly construct the shell of the droid from the scrap", {}, function (m, line)
  if pending_droid_type then
    local secs = DROID_CONSTRUCT_COOLDOWNS[pending_droid_type]
    if secs then
      register_cooldown("droid_construct", secs)
    else
      blight.output(C_BYELLOW .. "[droid_construct] unknown type '" .. pending_droid_type .. "', cooldown not tracked" .. C_RESET)
    end
    pending_droid_type = nil
  end
end)

trigger.add("^That is not a valid recipe", {}, function () pending_droid_type = nil end)
trigger.add("^You do not have the required", {}, function () pending_droid_type = nil end)
trigger.add("^You are too busy to do that yet", {}, function () pending_droid_type = nil end)

trigger.add("^You have successfully installed", {}, function (m, line)
  register_cooldown("dmodify", DMODIFY_COOLDOWN)
end)

-- Export as global for script.load() compatibility
DroidCooldownTracker = DroidCooldownTracker
_G.DroidCooldownTracker = DroidCooldownTracker

return DroidCooldownTracker
