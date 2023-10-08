-- general functions
local function create_skill(sk_name, regex_win, regex_fail, sk_delay_win, sk_delay_fail, check_last_command, regex_miss)
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
        SKILL_TABLE_WIN[sk_name] = os.time()
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

-- status skills (bmed, block retal etc...)
local function create_status_skill(sk_name, regex_win, regex_fail, regex_revert, sk_ttl)
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

-- delays reset
trigger.add("^You have no skills with pending delays\\.", {}, function (m)
  if TABLE_LENGTH(SKILL_TABLE_WIN)>0 then
    for k,v in pairs(SKILL_TABLE_WIN) do
      SKILL_TABLE_WIN[k] = nil
    end
  end
end)

create_status_skill("block", "^You take up a defensive stance and prepare to block shots\\.", nil, "^You stop blocking shots\\.", 12)
create_status_skill("retal", "^You take up a defensive stance and prepare to retaliate shots\\.", nil, "^You stop retaliating shots\\.", 12)
create_status_skill("bmed", "^You feel your control over the Force increase\\.", "^Your concentration is broken and you can no longer feel the Force\\.", "^You feel your control of the Force decrease a little\\.", 60)
create_status_skill("no_force", "^Your concentration is broken and you can no longer feel the Force\\.", nil, "^You feel the warmth of the Force surround you again\\.", 16)
create_status_skill("nanoheal", "^You run the parts through a compartment on your slicertool and it synthesizes some healing nanites. You startup the programming script and before you know it, your healing nanites are ready to go. The dust-like bots disappear through your skin and you start to feel better\\.",
                        "^You run the parts through a compartment on your slicertool and it synthesizes some healing nanites. As you start the programming script, something goes wrong and the dust-like nanites fall harmlessly to the ground\\.",
                        "^The healing nanites run out of power and you feel your body returning to normal\\.", 62)
create_status_skill("nanoheal", nil, nil, "^The nanobots run out of power and you feel your body return to normal\\.")
create_status_skill("healing_nanites", "^You thrust the nanoinjector into your thigh and release a swarm of nanites into your bloodstream\\.", nil, "^The nanites within your bloodstream give out and dissolve away\\.", 46)

create_skill("throw", "^You (throw .*) from .*", "^You (fail to throw) ")
create_skill("lift", "^You (lift .+) from ", "^You (fail to lift .+)\\.")
create_skill("lift", nil, "The little droid (anchors itself firmly) into the ground")
create_skill("slife", "^You (touch your victim) and steal some of ", "^You (fail to steal lifeforce) from")
create_skill("surprise", "^You (surprise) your attacker and gain extra attacks\\.", "^You (seem to be unable to surprise) your enemy\\.")
create_skill("change", "^You (change your appearance.) You now look like ", "^You (lose control) of the Force and fail\\.", 5, 5, 1)
create_skill("compel", "^You (use your mastery of the Force) to compel", "^You (fail to use your mastery of the Force) to compel", 30)
create_skill("repair", "^You (repair) .*\\.", "^You (fail to repair) .*\\.", 2, 2)
create_skill("anger", "^The (pain of your injuries seems to vanish) as you ", "^You (fail to focus) on your anger\\.", 2, 2)
create_skill("disable", "^You (search for your enemy.s weakest point) and take a calculated swing", "^You (take a wild swing) at .*, but miss completely")
create_skill("absorb", "^You (concentrate on absorbing) energy directed at you\\." , "^You (fail to achieve) the proper concentration required\\.", 150, 6)
-- create_skill("pres", "^You (remove the drugs|remove some of the drugs|purge your body) ", "^Nothing happens\\.", 1)
create_skill("scloak", "^You (draw the Dark Side) around you to hide your presence\\.", "^You (lose control) of the Force and fail\\.", 2, 5, 1)
create_skill("subdue", "^You (deftly beat .+ over the head). Before ", "^You (fail to subdue|try to subdue) .+, but m")
create_skill("subdue", nil, "^(.* still looks quite lively). Maybe .* needs more 'persuasion'?")
create_skill("decay", "^The (.+ decays) under your influence\\.", "^You (fail to decay) the ", 2, 5)
create_skill("improve", "^You (successfully improve) the ", "^You (fail to improve) the ", 3, 6)
create_skill("improve", nil, "^You (attempt to improve the lightsaber) handle but end up damaging it!", 3, 6)
create_skill("construct", "^You (take the holographic projector) ", "^You (fail to get the circuitry working) ", 150, 6)
create_skill("construct", "^You (change the circuitry) ", "^You fail to construct a .*\\.", 150, 6)
create_skill("construct", "^You (spend some time tinkering) ", nil, 150, 6)
create_skill("construct", "^You (take the charging mechanism) ", nil, 150, 6)
create_skill("construct", "^You (alter the .+valves) ", nil, 150, 6)
create_skill("construct", "^You (remove the spikes from the knuckles) ", nil, 150, 6)
create_skill("decoy", "^You (create and position a hologram) ", "^You (cannot seem to get) the decoy to look anything like you\\.")
create_skill("forens", "^You (collect various forensic samples) and learn:", "^You (contaminate the crime scene) as you maneuver through looking for evidence!")
create_skill("inflict", "^You (draw on your hatred) within and direct it at your victim\\.", "^You focus on your hatred within, (but become distracted)\\.")
create_skill("lightening", "^Lightning (arcs from your fingers) ", "^You call forth the lightning, but (it fails to come.)", 6, 6)
create_skill("enhatt", "^Through the power of the Force (you enhance your .+) ability\\.", "^The Force (denies you the ability to enhance) that ability\\.", 6, 6)
create_skill("mwipe", "^You (concentrate your Sith powers) on .+, causing ", "^You concentrate your Sith powers on .+ (but lose your concentration)\\.", 6, 6)
create_skill("jpack", "^You (bring the jetpack) to a stop\\.", "^You (fail to operate) the jetpack correctly\\.", 2, 2)
create_skill("picture", "^(Map of your location):", "^You (fail to picture) your surroundings\\.", 2, 2)
create_skill("bioeng", "^The medbots finish their procedure.+\\.  (The procedure was a success)!", "^The medbots finish their procedure.+\\.  (The procedure has failed)\\.", 0, 0)
create_skill("bioeng", nil, "^You are in a great deal of pain, and judging by the medbot's readouts, (the procedure was a failure)\\.", 0, 0)
create_skill("syringe", "^You (stick a needle) deep into your own flesh\\.", "^You try to inject yourself, (but wimp out) and get .+ everywhere\\.", 2, 2)
create_skill("syringe", "^The (needle buries itself) deep into the flesh of .+!", "^You try, but (fail to inject)\\.", 2, 2)
create_skill("fpush", "^You (use the Force to push) everyone", "^You (lose your concentration) and fail\\.")
create_skill("farsight", "^You (see into .+ environment) and you see:", "^You (fail to see) .+", 2, 2)
create_skill("fshield", "^You (erect a shield) of Force around yourself\\.", "^You (fail to erect) a shield of Force", 6, 6)
create_skill("bmed", "^You feel your (control over the Force increase)\\.", "^Your (concentration is broken) and you can no ", 150, 6)
create_skill("superheal", "^You heal yourself completely\\.", "Nothing happens\\.", 600, 3, 1)
create_skill("she", nil, nil, 3, 3, 1)
create_skill("cfear", "^You create the (sound of the Krayt Dragon)\\.", "^You (make a small, pathetic squeak) quite ")
create_skill("project", "^As (you project your image), you see the surroundings of your image...\\.", "^You (attempt to project) your image to .+, but you lose", 3, 6)
create_skill("disarm", "^You (succeed in disarming) your opponent!", "^You (fail to disarm) your opponent\\.", 2, 2)
create_skill("droid_construct", "^You (slowly construct) the shell of the droid from the scrap\\.", "^You (try to construct a droid), but fail\\.", 450, 8)
create_skill("droid_construct", nil, "^You fail to construct an .* Model\\.", 450, 8)
create_skill("scavenge", "^You (manage to salvage) .*\\.", "^You (fail to scavenge) any parts from .*\\.")
create_skill("scavenge", nil, "^There is (nothing to scavenge) from .*\\.")
create_skill("tamper", "(cost has been decreased.)$", "(cost has been increased.)$")
create_skill("tamper", nil, "(quantity has been decreased.)$")
create_skill("tamper", "(quantity has been increased.)$", nil)
create_skill("overhaul", "^(You spend a good hour of your day fixing every problem) you can find with .*\\. When you are done, it gleams as if new\\.", "^You spend an hour of your day fiddling with (.*) but it", 3, 6)
create_skill("dmodify", "^You have (successfully installed) .*", "^You (try to modify) the droid, but fail", 150, 9)
create_skill("dmodify", nil, "^You try to modify .*, but fail", 150, 9)
create_skill("cureall", "You (perform cureall surgery)", "^You try, but (fail to perform cureall surgery)", 150, 4)
create_skill("ionshield", "(You shield the circuitry)", "^(You fail to shield the circuitry)", 3, 6)
create_skill("trip", "^You (trip) .* and stun your victim with a clever maneuver\\.", "^You (try to trip your opponent and miss), then stagger around trying to regain your balance\\.")
create_skill("trip", "^You trip .* and stun .* with a clever maneuver\\.", "^You try to trip .*, then stagger around trying to regain your balance\\.")
create_skill("trip", "^You manage to (trip) .* causing .* to stagger around senselessly\\.", "^You (try to trip your opponent) but get your feet tangled up and end up hurting yourself. Ouch!")
create_skill("sneak", "^You (quietly sneak) into the next room\\.", "^(Everybody notices you as you attempt to sneak) out of the room\\.", 4, 4, nil, "You don\\'t feel like being sneaky and instead just walk\\.")
create_skill("sneak", "^You (quietly sneak) to the .*", nil)
create_skill("backstab", "^You (bury your .*) into .* back!", "^You (try to stab) .* but fail terribly\\.")
create_skill("backstab", "^.* flesh sizzles as (you skewer) .* with your lightsaber!")
create_skill("backstab", "^You (slash .* back) with your .*")
create_skill("tear", "^Your (claws rip) into .* causing dreadful wounds\\.", "^You (attempt to tear) .* but your claws rake across .* ineffectually\\.")
create_skill("fury", "^(You work yourself into a towering fury), intent on laying waste to all around you without concern for your own safety\\.", "^You (fail to work yourself) into a towering fury\\.")
create_skill("fade", "^You (fade) into the shadows\\.", "^You (attempt to fade into the background), but end up drawing even more attention to yourself\\.")
create_skill("program", "^You remove the .* desire to speak out\\.", "^You fail to program the droid\\.")
create_skill("linehack", "^You crack into the line\\.", "^You fail to hack the line with the grace of a rancor\\.", 20, 4)
create_skill("nanoheal", "^You run the parts through a compartment on your slicertool and it synthesizes some healing nanites. You startup the programming script and before you know it, your healing nanites are ready to go. The dust-like bots disappear through your skin and you start to feel better\\.",
                        "^You run the parts through a compartment on your slicertool and it synthesizes some healing nanites. As you start the programming script, something goes wrong and the dust-like nanites fall harmlessly to the ground\\.",
                        150, 4)
create_skill("nanoheal", nil, "^As you run the parts through a compartment on your slicertool, something goes badly wrong and it spits out metallic dust\\.",150, 4)
create_skill("nanoheal", nil, "^Your slicertool successfully synthesizes the tiny bots, but you accidentally breathe a bit too hard blowing the tiny dust-like droids into oblivion\\.",150, 4)
create_skill("nanoheal", nil, "^Your slicertool seems to have crashed when attempting to synthesize the healing nanites. Must be a glitch in the software\\.", 150, 4)
create_skill("healing_nanites", "^You thrust the nanoinjector into your thigh and release a swarm of nanites into your bloodstream\\.", nil, 120, 4)
create_skill("nanoinject", nil, "^You attempt to deliver the nanites, but fail\\.", 30, 4)
create_skill("damage_nanites", "^You (thrust the nanoinjector into) .* flesh and unload a swarm of nanites into its bloodstream\\.", nil, 4, 4)
create_skill("heal", "^You heal yourself\\.", "You fail to heal yourself\\.", 1, 1, 1)
create_skill("presist", "^You remove some of the drugs from your system\\.", "^You reach out with the Force to cleanse yourself, but your concentration is broken\\.", 2, 2, 1)
create_skill("hack_bank", "^You have managed to funnel.*", nil, 21600, 4)

-- delays catch
DELAYS_REMAP = {droid_construct = "droid construct",
                hack_bank = "hack bank",
                dmodify = "droid modification",
                cureall = "cureall surgery or nanoheal",
                healing_nanites = "healing nanites",
                absorb = "absorb/dissipate energy",
                bmed = "jedi battle meditation",}
DELAYS_REMAP2 = {healing_nanites = "healing nanite cooldown",
                nanoheal = "cureall surgery or nanoheal",
                cureall = "cureall surgery or nanoheal",}
