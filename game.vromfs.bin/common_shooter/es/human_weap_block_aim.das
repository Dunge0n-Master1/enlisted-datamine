require ecs
require enlisted.events_enlisted

[es(before=human_weap_phys_es)]
def human_weap_block_aim_es(info : ParallelUpdateFrameDelayed;
                            isInVehicle : bool;
                            human_vehicle__canHoldWeapon : bool;
                            human_net_phys__isUnderwater : bool;
                            human_weap__currentGunEid : EntityId;
                            var human_weap__blockAiming : bool&)
  if isInVehicle
    let gunDisableAimInVehicle = has(human_weap__currentGunEid, "gun__disableAimInVehicle")
    human_weap__blockAiming = !human_vehicle__canHoldWeapon || gunDisableAimInVehicle || human_net_phys__isUnderwater
  else
    human_weap__blockAiming = false
