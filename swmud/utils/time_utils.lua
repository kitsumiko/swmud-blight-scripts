-- Time and date utility functions

local TimeUtils = {}

function TimeUtils.convert_mud_date(string_in)
  -- string_in="Sat Nov  4 00:01:15 2023 EST"
  --           (Thu Dec 28 12:30:00 2023 EST)
  --           (Thu Feb 22 22:56:13 2024 EST)
  
  -- SWmud has been up for:  5d 15h 33m  3s.  Memory Usage: 516.7 MB
  -- Next scheduled reboot:  23d 12h 26m 57s. (Thu Feb 22 22:56:13 2024 EST)
  local date={}
  date['month'],date['day'],date['hour'],date['min'],date['sec'],date['year']=string_in:match("%a+ (%a+)%s+(%d+) (%d+):(%d+):(%d+) (%d+)")
  local MON={Jan=1,Feb=2,Mar=3,Apr=4,May=5,Jun=6,Jul=7,Aug=8,Sep=9,Oct=10,Nov=11,Dec=12}
  date['month']=MON[date['month']]
  date["isdst"] = false 
  local date_out = os.time(date)
  return date_out
end

-- Export as globals for backward compatibility
CONVERT_MUD_DATE = TimeUtils.convert_mud_date

return TimeUtils

