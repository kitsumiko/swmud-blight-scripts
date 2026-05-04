-- Annotates `panic droid_construct` short-list output with each droid's
-- recipe-specific extras. The base set ("2 scrap, 20 toolbox parts, droid CPU,
-- droid servo, restraining bolt, slave module") is the same for every recipe
-- and is already stated in the panic body, so we only append what's unique to
-- each row.

local DroidConstructHelper = {}

-- Maps the droid name as it appears in the short list (column 2) to the
-- recipe-specific extras beyond the base set. Empty string means no extras.
-- "(no restraining/slave)" notes recipes that drop the restraining-bolt +
-- slave-module pair (PK remotes).
local DROID_EXTRAS = {
  ["C3 Model"]         = "",
  ["T5 Model"]         = "",
  ["SLR Remote"]       = "(no restraining/slave)",
  ["GNK Model"]        = "power converter",
  ["B1 Model"]         = "blaster rifle",
  ["RX Model"]         = "",
  ["G2 Model"]         = "",
  ["MLR Remote"]       = "(no restraining/slave)",
  ["R4P Model"]        = "",
  ["NR Model"]         = "security slicer",
  ["Spydroid Remote"]  = "security camera (no restraining/slave)",
  ["FX Model"]         = "laser scalpel, syringe",
  ["IF Model"]         = "blaster rifle, ion knife",
  ["IG Model"]         = "armor plating, ion knife",
  ["RA Model"]         = "security camera",
  ["XLR Remote"]       = "(no restraining/slave)",
  ["BLX Model"]        = "",
  ["T7 Model"]         = "",
  ["C5 Model"]         = "",
  ["S9E Model"]        = "power converter",
  ["B2 Model"]         = "blaster rifle, armor plating",
  ["DD Model"]         = "laser scalpel, syringe",
  ["ALR Remote"]       = "(no restraining/slave)",
  ["MSE Courier"]      = "",
  ["OOM Model"]        = "blaster rifle, ion knife",
  ["R8 Model"]         = "security slicer",
  ["2-1C Model"]       = "laser scalpel, syringe, armor plating",
  ["HK Model"]         = "two blaster rifles",
  ["FA-5 Model"]       = "",
}

-- Gate trigger firing to lines inside the short-list table so we don't rewrite
-- unrelated game output that happens to share the layout.
local in_table = false

trigger.add("^Lvl\\s+Item Name\\s+Description$", {}, function(m, line)
  in_table = true
end)

-- The blurb that closes out the short-list view.
trigger.add("^You may use the first few characters of any recipe", {}, function(m, line)
  in_table = false
end)

-- Each droid row: level, name (may contain a single space), then >=2 spaces
-- separating the description column. Annotate via line:replace so the
-- rewritten text shows up in the original line's slot.
trigger.add("^(\\d+)\\s+(\\S.*?)\\s\\s+(.+?)\\s*$", {}, function(m, line)
  if not in_table then return end
  local name = m[3]
  local extras = DROID_EXTRAS[name]
  if extras == nil then return end
  if extras == "" then return end
  local original = line:line()
  line:replace(original .. "  " .. C_BYELLOW .. "[+ " .. extras .. "]" .. C_RESET)
end)

DroidConstructHelper = DroidConstructHelper
_G.DroidConstructHelper = DroidConstructHelper
return DroidConstructHelper
