require ecs

[es(tag=server, after=dmgzone_es)]
def decay_zone_fire_damage_resistance(info : UpdateStageInfoAct;
                                      dmgzone_fire_resistance__decayInterval : float;
                                      var dmgzone_fire_resistance__currentTicks : int&;
                                      var dmgzone_fire_resistance__lastTickAt : float&)
  if dmgzone_fire_resistance__currentTicks <= 0 || dmgzone_fire_resistance__lastTickAt + dmgzone_fire_resistance__decayInterval > info.curTime
    return

  dmgzone_fire_resistance__lastTickAt = info.curTime
  dmgzone_fire_resistance__currentTicks -= 1

[es(tag=server, after=dmgzone_es, before=decay_zone_fire_damage_resistance)]
def fire_damge_human_on_water_es(info : UpdateStageInfoAct;
                                 dmgzone_fire_resistance__underwaterTicks : int;
                                 human_breath__isUnderWater : bool;
                                 human_net_phys__isSwimming : bool;
                                 dmgzone_fire_resistance__wetDelaySec : float;
                                 var dmgzone_fire_resistance__wetTimerSec : float&;
                                 var dmgzone_fire_resistance__currentTicks : int&)
  if human_breath__isUnderWater || human_net_phys__isSwimming
    dmgzone_fire_resistance__currentTicks = dmgzone_fire_resistance__underwaterTicks
    dmgzone_fire_resistance__wetTimerSec = dmgzone_fire_resistance__wetDelaySec
    return

  if dmgzone_fire_resistance__currentTicks >= 0
    return

  dmgzone_fire_resistance__wetTimerSec -= info.dt
  if dmgzone_fire_resistance__wetTimerSec >= 0.f
    return

  dmgzone_fire_resistance__currentTicks += 1
  dmgzone_fire_resistance__wetTimerSec = dmgzone_fire_resistance__wetDelaySec
