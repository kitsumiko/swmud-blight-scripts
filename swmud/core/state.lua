-- Centralized state management
-- Maintains global state for backward compatibility while organizing it better

local State = {}

-- Character data
State.character = {
  sense_distrubance = 0,
  zoology = 0,
  mrh_switch = 0,
  autowield_switch = 0,
  sense_farsight = 0,
  character_name = "Unknown: "..C_BYELLOW.."<score>"..C_RESET,
  race = "none",
  prime_guild = "Unknown: "..C_BYELLOW.."<score>"..C_RESET,
  second_guild = "None",
  third_guild = "None",
  racial_right_bracket = "",
  racial_left_bracket = "",
  character_levels = "Unknown: "..C_BYELLOW.."<score>"..C_RESET,
  skill_delays = "",
}

-- Setup state
State.setup = {
  prompt_set = 0,
  uptime_set = 0,
  reboot_set = 0,
  uptime_str = "Unknown: "..C_BYELLOW.."<uptime>"..C_RESET,
}

-- Prompt information
State.prompt = {
  hp = 0,
  hp_max = 1,
  exp = 0,
  credits = 0,
  align_team = -75,
  align_jedi = 50,
  wimpy = 1,
  sp = 0,
  sp_max = 1,
  drug = "undrugged",
  char_active = 0,
  prev_line = "",
  prev_line_dpr_match = 0,
  damage_regexp = regex.new("^hp: ([^ ]*)/([^ ]*) \\(([^ ]*)\\)$"),
  score_regexp = regex.new("^score$"),
  delays_regexp = regex.new("^delays$"),
  level_regexp = regex.new("([a-zA-Z]* ?[a-zA-Z]* ?[ ]*): ([0-9]*)"),
  char_regexp = regex.new("^You are: ([a-zA-Z]*)"),
  emote_regexp = regex.new("^([a-zA-Z]*)emote "),
  primary_guild_regexp = regex.new("^Levels:  (.*): ([a-zA-Z]* ?[a-zA-Z]*)\\)"),
  prompt_re = regex.new("^([^ ]*)/([^ ]*) ([^ ]*) ([^ ]*) ([^ ]*)/([^ ]*) ([^ ]*) ([^ ]*)/([^ ]*) ([^ ]* ?[^ ]*? ?[^ ]*?) >"),
  droid_match = regex.new("^(C3|T5|SLR|GNK|B1|RX|G2|MLR|R4P|NR|FX|IF|IG|RA|XLR|BLX|T7|C5|S9E|B2|DD|ALR|MSE|OOM|R8|2\\-1C|HK|FA\\-5)(.*) \\(Yours\\)$"),
  room_match = regex.new("^(There are no obvious exits|There only obvious exit is|There are .* obvious exits:)(.*)$"),
  score_catch = 0,
  delays_catch = 0,
  bsense_catch = 0,
  blook_catch = 0,
  prev_damager = "",
  last_command_time = os.time(),
  last_autosave = os.time(),
  last_command = "",
  last_repeat_command = "",
  save_raw_command = 1,
  last_kill = "",
  last_kill_ts = os.time(),
  total_dpr = "",
  edpr = "",
  total_damage = "",
  last_total_damage = "",
  total_edamage = "",
  last_total_edamage = "",
  total_rounds = "",
  last_total_rounds = "",
  hp_length = 0,
  thp_length = 0,
  guilds = {"Jedi", "Mercenary", "Pilot", "Scientist", "Smuggler", "Diplomat", "Bounty Hunter", "Slicer", "Assassin", "Merchant", "Scout",},
  move_commands = {"n", "north", "e", "east", "w", "west", "s", "south", "ne", "northeast", "nw", "northwest", "se", "southeast", "sw", "southwest", "d", "down", "u", "up", "exit",},
  move_cmd = "",
  durable_skill_status = "",
}

-- DPR information
State.dpr = {
  status_line = "DPR: N/A",
}

-- Target information
State.target = {
  status_line = "T: None" .. (C_GREEN.." | "..C_RESET) .. "H: N/A",
  last_target = "None",
  hold_target = "None",
  target_start_xp = 0,
  start_combat_ts = os.time(),
  target_health = 0,
  total_health = 0,
  target_pct = 0,
  unrec_damage = 0,
}

-- Base target info template
State.base_target_info = {
  hscan = "100%",
  bsense = "None",
  blook = "None",
  h_hscan = {},
  h_bsense = {},
  h_blook = {},
  dead = 0,
}

-- Other state tables
State.nicknames = {}
State.levels = {}
State.room = {
  beings = {},
  exits = {},
  my_droids = {}
}

-- Delays hooks
State.delays_hooks = {
  regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) seconds$"),
  regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) minutes$"),
  regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) minutes and ([0-9]*) seconds$"),
  regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) minutes and ([0-9]*) second$"),
  regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) minute and ([0-9]*) seconds$"),
  regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) hour and ([0-9]*) seconds$"),
  regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) hours and ([0-9]*) seconds$"),
  regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) hours and ([0-9]*) minutes$"),
  regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) hour, ([0-9]*) minutes, and ([0-9]*) seconds$"),
  regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) hours, ([0-9]*) minutes, and ([0-9]*) seconds$"),
}

-- Session info
State.session = {
  session_start = os.time(),
}

-- Experience table
State.exp_table = {
  x_snapshot = 0,
}

-- Experience table data (loaded from file)
State.exp_table_data = {}

-- DPR trigger table
State.dpr_triggers = {
  t0 = {},
  t1 = {},
}

-- Skill tables
State.skills = {
  win = {},
  fail = {},
  delays_win = {},
  delays_shim = {},
  delays_fail = {},
  status = {},
  status_est = {},
  status_start = {},
  status_end = {},
  status_len = {},
}

-- Export as globals for backward compatibility
CHAR_DATA = State.character
SETUP_STATE = State.setup
PROMPT_INFO = State.prompt
DPR_INFO = State.dpr
TARGET_INFO = State.target
BASE_TARGET_INFO = State.base_target_info
NICKNAME_TABLE = State.nicknames
LEVEL_TABLE = State.levels
ROOM_TABLE = State.room
DELAYS_HOOKS = State.delays_hooks
SESSION_INFO = State.session
EXP_TABLE = State.exp_table
EXP_TABLE_DATA = State.exp_table_data
DPR_TRIGGER_TABLE = State.dpr_triggers
SKILL_TABLE_WIN = State.skills.win
SKILL_TABLE_FAIL = State.skills.fail
SKILL_DELAY_TABLE_WIN = State.skills.delays_win
SKILL_DELAY_TABLE_SHIM = State.skills.delays_shim
SKILL_DELAY_TABLE_FAIL = State.skills.delays_fail
SKILL_STATUS_TABLE = State.skills.status
SKILL_STATUS_EST = State.skills.status_est
SKILL_STATUS_START = State.skills.status_start
SKILL_STATUS_END = State.skills.status_end
SKILL_STATUS_LEN = State.skills.status_len

return State

