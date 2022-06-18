require ecs

[es(tag=gameClient, no_order)]
def human_weap_block_aim_es(info : UpdateStageInfoAct; var human_weap__blockAiming : bool&; isInVehicle, isPassenger, human_net_phys__isUnderwater : bool; human_weap__currentGunEid : EntityId)
  if isInVehicle
    human_weap__blockAiming = !isPassenger || has(human_weap__currentGunEid, "gun__disableAimInVehicle") || human_net_phys__isUnderwater
  else
    human_weap__blockAiming = false
