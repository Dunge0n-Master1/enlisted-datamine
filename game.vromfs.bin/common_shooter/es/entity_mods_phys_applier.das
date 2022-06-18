require ecs
require EnlistedHuman


[es(tag=server, no_order)]
def entity_swimming_speed_mod_applier_es(info : UpdateStageInfoAct; entity_mods__swimmingSpeedMult : float; var human_net_phys : HumanActor)
  human_net_phys.phys.currentState.swimmingSpeedMult = entity_mods__swimmingSpeedMult

[es(no_order)]
def entity_aim_speed_mod_applier(info : UpdateStageInfoAct; entity_mods__aimSpeedMult : float; var human_net_phys : HumanActor)
  human_net_phys.phys.currentState.aimSpeedMult = entity_mods__aimSpeedMult
