require ecs
require EnlistedHuman
require enlisted.events_enlisted

[es(no_order)]
def entity_aim_speed_mod_applier(info : ParallelUpdateFrameDelayed; entity_mods__aimSpeedMult : float; var human_net_phys : HumanActor)
  human_net_phys.phys.currentState.aimSpeedMult = entity_mods__aimSpeedMult
