require ecs
require HumanPhys
require EnlistedHuman

[es(before=before_net_phys_sync)]
def human_phys_set_gun_offset_es(info : UpdateStageInfoAct;
                                 human_weap__currentGunEid : EntityId;
                                 var human_net_phys : HumanActor)
  human_net_phys.phys.gunOffset = get_Point3(human_weap__currentGunEid, "gun__animOffset") ?? float3(0.f)