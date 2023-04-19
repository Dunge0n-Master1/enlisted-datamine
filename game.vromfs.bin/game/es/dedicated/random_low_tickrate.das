require DagorConsole
require DagorRandom
require DagorSystem
require ecs
require DngPhys

[es(tag=server, no_order)]
def try_lower_tickrate_randomly(info : UpdateStageInfoAct;
                                random_low_tickrate__loweredTickrate : int;
                                random_low_tickrate__actionPeriod : float;
                                random_low_tickrate__chanceToLower : float;
                                random_low_tickrate__chanceToReset : float;
                                var random_low_tickrate__currentDeadline : float&;
                                var random_low_tickrate__currentlyLow : bool&)
  random_low_tickrate__currentDeadline -= info.dt
  if random_low_tickrate__currentDeadline > 0.f
    return

  random_low_tickrate__currentDeadline = random_low_tickrate__actionPeriod

  if random_low_tickrate__currentlyLow
    if gfrnd() < random_low_tickrate__chanceToReset
      console_command("net.force_server_tick_rate {PHYS_DEFAULT_TICKRATE}")
      random_low_tickrate__currentlyLow = false
  else
    if gfrnd() < random_low_tickrate__chanceToLower
      console_command("net.force_server_tick_rate {random_low_tickrate__loweredTickrate}")
      random_low_tickrate__currentlyLow = true
