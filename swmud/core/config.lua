-- Configuration constants and paths

local Config = {}

-- MUD connection settings
Config.MUD_HOST = "swmud.org"
Config.MUD_PORT = 7777
Config.MUD_PORT_RECONNECT = 6666
Config.MUD_SSL = true
Config.MUD_RECONNECT = false

-- Paths
Config.BASE_PATH = "~/.config/blightmud/"
Config.SCRIPT_DIR = "~/.config/blightmud/swmud/"
Config.PRIVATE_DIR = "~/.config/blightmud/private/"
Config.DATA_DIR = "~/.config/blightmud/swmud/data/"

-- File names
Config.VERSION_FILE = "100_version.txt"
Config.EXP_DATA_FILE = "100_data_exp.txt"

-- Status separator (will be set after colors are loaded)
Config.STATUS_SEP = nil

-- Pattern for matching names
Config.P_STR = "([^ ]* ?[^ ]*? ?[^ ]*?)"

-- Guilds list
Config.GUILDS = {
  "Jedi", "Mercenary", "Pilot", "Scientist", "Smuggler", 
  "Diplomat", "Bounty Hunter", "Slicer", "Assassin", 
  "Merchant", "Scout"
}

-- Move commands
Config.MOVE_COMMANDS = {
  "n", "north", "e", "east", "w", "west", "s", "south",
  "ne", "northeast", "nw", "northwest", "se", "southeast",
  "sw", "southwest", "d", "down", "u", "up", "exit"
}

-- Export as global for backward compatibility
CONFIG = Config

return Config

