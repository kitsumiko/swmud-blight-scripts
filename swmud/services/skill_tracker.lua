-- Skill tracking service

local SkillTracker = {}

-- Skills that share an in-game cooldown bucket. Triggering or learning the
-- remaining cooldown of any one of them propagates the same future ready-time
-- to all peers, so the De: bar shows a single accurate countdown rather than
-- losing one half of the pair. Keys are skill table names; values are arrays
-- of peer skill names that share the bucket.
SKILL_SHARED_COOLDOWNS = {
  cureall = {"nanoheal"},
  nanoheal = {"cureall"},
}

function SkillTracker.propagate_shared_cooldown(sk_name, future_time)
  local peers = SKILL_SHARED_COOLDOWNS and SKILL_SHARED_COOLDOWNS[sk_name]
  if peers == nil then return end
  for _, peer in ipairs(peers) do
    SKILL_TABLE_WIN[peer] = future_time
  end
end

function SkillTracker.create_skill(sk_name, regex_win, regex_fail, sk_delay_win, sk_delay_fail, check_last_command, regex_miss)
  SKILL_TABLE_WIN[sk_name] = nil
  SKILL_TABLE_FAIL[sk_name] = nil
  if sk_delay_win==nil then
    sk_delay_win = 4
  end
  if sk_delay_fail==nil then
    sk_delay_fail = 4
  end
  SKILL_DELAY_TABLE_WIN[sk_name] = tonumber(sk_delay_win)
  SKILL_DELAY_TABLE_FAIL[sk_name] = tonumber(sk_delay_fail)
  if regex_win ~= nil then
    trigger.add(regex_win, {gag=1}, function (m, line)
      local exec_trigger = 1
      if check_last_command ~= nil then
        if PROMPT_INFO.last_repeat_command ~= sk_name then
          exec_trigger = 0
        end
      end
      if exec_trigger==1 then
        if not SET_CONTAINS(SKILL_STATUS_TABLE, sk_name) then
          blight.output("("..C_BGREEN.."SUCCESS"..C_RESET.."): "..sk_name.." - "..line:raw())
        end
        -- Store the future ready-time so the De: bar shows the cooldown immediately,
        -- without requiring the user to run `delays`. Matches hack_bank/isard_station pattern.
        local future_time = os.time() + (SKILL_DELAY_TABLE_WIN[sk_name] or 4)
        SKILL_TABLE_WIN[sk_name] = future_time
        SkillTracker.propagate_shared_cooldown(sk_name, future_time)
      end
    end)
  end
  if regex_fail ~= nil then
    trigger.add(regex_fail, {gag=1}, function (m, line)
      local exec_trigger = 1
      if check_last_command ~= nil then
        if PROMPT_INFO.last_repeat_command ~= sk_name then
          exec_trigger = 0
        end
      end
      if exec_trigger==1 then
        blight.output("("..C_BRED.."FAILURE"..C_RESET.."): "..sk_name.." - "..line:raw())
        SKILL_TABLE_FAIL[sk_name] = os.time()
      end
    end)
  end
  if regex_miss ~= nil then
    trigger.add(regex_miss, {gag=1}, function(m, line)
      local exec_trigger = 1
      if check_last_command ~= nil then
        if PROMPT_INFO.last_repeat_command ~= sk_name then
          exec_trigger = 0
        end
      end
      if exec_trigger==1 then
        blight.output("("..C_BYELLOW.."MISS"..C_RESET.."): "..sk_name.." - "..line:raw())
      end
    end)
  end
end

function SkillTracker.create_status_skill(sk_name, regex_win, regex_fail, regex_revert, sk_ttl)
  SKILL_STATUS_TABLE[sk_name] = 0
  if sk_ttl ~= nil then
    SKILL_STATUS_LEN[sk_name] = tonumber(sk_ttl)
  end
  if regex_win ~= nil then
    trigger.add(regex_win, {gag=1}, function (m, line)
      blight.output("("..C_BGREEN.."START"..C_RESET.."): "..sk_name.." - "..line:raw())
      SKILL_STATUS_START[sk_name] = os.time()
      SKILL_STATUS_TABLE[sk_name] = 1
    end)
  end
  if regex_revert ~= nil then
    trigger.add(regex_revert, {gag=1}, function (m, line)
      blight.output("("..C_BRED.."END"..C_RESET.."): "..sk_name.." - "..line:raw())
      SKILL_STATUS_END[sk_name] = os.time()
      SKILL_STATUS_TABLE[sk_name] = 0
      if SKILL_STATUS_START[sk_name] ~= nil then
        SKILL_STATUS_EST[sk_name] = math.floor(os.difftime(SKILL_STATUS_END[sk_name], SKILL_STATUS_START[sk_name]))
      end
    end)
  end
  if regex_fail ~= nil then
    SKILL_TABLE_FAIL[sk_name] = nil
    SKILL_DELAY_TABLE_FAIL[sk_name] = 4
    trigger.add(regex_fail, {gag=1}, function (m, line)
      if not SET_CONTAINS(SKILL_DELAY_TABLE_FAIL, sk_name) then
        blight.output("("..C_BRED.."FAILURE"..C_RESET.."): "..sk_name.." - "..line:raw())
      end
      SKILL_TABLE_FAIL[sk_name] = os.time()
    end)
  end
end

-- Export as globals for backward compatibility
create_skill = SkillTracker.create_skill
create_status_skill = SkillTracker.create_status_skill
PROPAGATE_SHARED_COOLDOWN = SkillTracker.propagate_shared_cooldown

-- Delays reset trigger
trigger.add("^You have no skills with pending delays\\.", {}, function (m)
  if TABLE_LENGTH(SKILL_TABLE_WIN)>0 then
    for k,v in pairs(SKILL_TABLE_WIN) do
      SKILL_TABLE_WIN[k] = nil
    end
  end
  -- Mark that delays have been checked and there are none
  DELAYS_CHECKED = true
end)

-- Delays remap tables
DELAYS_REMAP = {droid_construct = "droid construct",
                hack_bank = "hack bank",
                dmodify = "droid modification",
                cureall = "cureall surgery or nanoheal",
                healing_nanites = "healing nanites",
                absorb = "absorb/dissipate energy",
                bmed = "jedi battle meditation",
                isard_station = "isard station",}
DELAYS_REMAP2 = {healing_nanites = "healing nanite cooldown",
                nanoheal = "cureall surgery or nanoheal",
                cureall = "cureall surgery or nanoheal",}

-- Export as global
SkillTracker = SkillTracker

return SkillTracker

