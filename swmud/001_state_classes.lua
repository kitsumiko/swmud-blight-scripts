STATUS_SEP = C_GREEN.." | "..C_RESET

P_STR = "([^ ]* ?[^ ]*? ?[^ ]*?)"

CHAR_DATA = {
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

SETUP_STATE = {
  prompt_set = 0,
  uptime_set = 0,
  reboot_set = 0,
  uptime_str = "Unknown: "..C_BYELLOW.."<uptime>"..C_RESET,
}

PROMPT_INFO = {
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

DPR_INFO = {status_line = "DPR: N/A",}

TARGET_INFO = {status_line = "T: None" .. STATUS_SEP .. "H: N/A",
              last_target = "None",
              hold_target = "None",
              target_start_xp = 0,
              start_combat_ts = os.time(),
              target_health = 0,
              total_health = 0,
              target_pct = 0,
              unrec_damage = 0,}

BASE_TARGET_INFO = {hscan = "100%",
                    bsense = "None",
                    blook = "None",
                    h_hscan = {},
                    h_bsense = {},
                    h_blook = {},
                    dead = 0,}

NICKNAME_TABLE = {}

LEVEL_TABLE = {}

ROOM_TABLE = {beings = {},
              exits = {},
              my_droids = {}}

DELAYS_HOOKS = {regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) seconds$"),
                regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) minutes$"),
                regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) minutes and ([0-9]*) seconds$"),
                regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) minutes and ([0-9]*) second$"),
                regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) minute and ([0-9]*) seconds$"),
                regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) hour and ([0-9]*) seconds$"),
                regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) hours and ([0-9]*) seconds$"),
                regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) hours and ([0-9]*) minutes$"),
                regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) hour, ([0-9]*) minutes, and ([0-9]*) seconds$"),
                regex.new("^([a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]* ?[a-zA-Z/]*): ([ 0-9]*) hours, ([0-9]*) minutes, and ([0-9]*) seconds$"),}
SKILL_DELAYS_WIN = {}

SESSION_INFO = {session_start = os.time(),}

EXP_TABLE = {x_snapshot = 0,}

DPR_TRIGGER_TABLE = {t0 = {},
                    t1 = {},}

SKILL_TABLE_WIN = {}
SKILL_TABLE_FAIL = {}
SKILL_DELAY_TABLE_WIN = {}
SKILL_DELAY_TABLE_SHIM = {}
SKILL_DELAY_TABLE_FAIL = {}

SKILL_STATUS_TABLE = {}
SKILL_STATUS_EST = {}
SKILL_STATUS_START = {}
SKILL_STATUS_END = {}
SKILL_STATUS_LEN = {}

EXP_TABLE = {}

--
-- store.session_write("char_data", json.encode(char_data))
-- store.session_write("setup_state", json.encode(setup_state))
-- store.session_write("prompt_info", json.encode(prompt_info))
-- store.session_write("dpr_info", json.encode(dpr_info))
