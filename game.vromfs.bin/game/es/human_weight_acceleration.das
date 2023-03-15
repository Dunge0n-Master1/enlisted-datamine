require ecs
require EnlistedHuman
require math
require DagorMath
require enlisted.events_enlisted

[es(tag=gameClient, REQUIRE=watchedByPlr, before=human_weight_influence_es, before=before_entity_mods_apply_sync_point)]
def human_acceleration_reset_client_es(info : ParallelUpdateFrameDelayed;
                                       var human_net_phys : HumanActor)
  human_net_phys.phys.currentState.accelerationMult = 1.f
[es(tag=server, before=human_weight_influence_es, before=before_entity_mods_apply_sync_point)]
def human_acceleration_reset_server_es(info : ParallelUpdateFrameDelayed;
                                       var human_net_phys : HumanActor)
  human_net_phys.phys.currentState.accelerationMult = 1.f
[es(tag=gameClient, REQUIRE=watchedByPlr, before=human_weight_influence_es, before=before_entity_mods_apply_sync_point)]
def human_jump_speed_reset_client_es(info : ParallelUpdateFrameDelayed;
                                     var human_net_phys : HumanActor)
  human_net_phys.phys.currentState.jumpSpeedMult = 1.f
[es(tag=server, before=human_weight_influence_es, before=before_entity_mods_apply_sync_point)]
def human_jump_speed_reset_server_es(info : ParallelUpdateFrameDelayed;
                                     var human_net_phys : HumanActor)
  human_net_phys.phys.currentState.jumpSpeedMult = 1.f
[es(tag=gameClient, REQUIRE=watchedByPlr, before=human_weight_influence_es, before=before_entity_mods_apply_sync_point)]
def human_move_speed_reset_client_es(info : ParallelUpdateFrameDelayed;
                                     var human_net_phys : HumanActor)
  human_net_phys.phys.currentState.moveSpeedMult = 1.f
[es(tag=server, before=human_weight_influence_es, before=before_entity_mods_apply_sync_point)]
def human_move_speed_reset_server_es(info : ParallelUpdateFrameDelayed;
                                     var human_net_phys : HumanActor)
  human_net_phys.phys.currentState.moveSpeedMult = 1.f
def human_weight_influence_update(var human_net_phys : HumanActor;
                                  human_inventory__currentWeight;
                                  human_weight_influence__minWeight;
                                  human_weight_influence__maxWeight;
                                  human_weight_influence__maxWeightAccelerationMult;
                                  human_weight_influence__maxWeightJumpMult;
                                  human_weight_influence__maxWeightSpeedMult;
                                  human_weight_influence__staminaDrainMult;
                                  entity_mods__weightRunSpeedMult)
  let curLerpFactor = cvt(human_inventory__currentWeight * entity_mods__weightRunSpeedMult,
                              human_weight_influence__minWeight, human_weight_influence__maxWeight,
                              0.f, 1.f)
  human_net_phys.phys.currentState.accelerationMult *= lerp(1.f, human_weight_influence__maxWeightAccelerationMult, curLerpFactor)
  human_net_phys.phys.currentState.jumpSpeedMult *= lerp(1.f, human_weight_influence__maxWeightJumpMult, curLerpFactor)
  human_net_phys.phys.currentState.moveSpeedMult *= lerp(1.f, human_weight_influence__maxWeightSpeedMult, curLerpFactor)
  human_net_phys.phys.currentState.staminaDrainMult *= lerp(1.f, human_weight_influence__staminaDrainMult, curLerpFactor)
[es(tag=server, after=after_entity_mods_apply_sync_point)]
def human_weight_influence_server_es(info : ParallelUpdateFrameDelayed;
                                     var human_net_phys : HumanActor;
                                     human_inventory__currentWeight : float;
                                     human_weight_influence__minWeight : float = 4.f;
                                     human_weight_influence__maxWeight : float  = 15.f;
                                     human_weight_influence__maxWeightAccelerationMult : float = 0.5f;
                                     human_weight_influence__maxWeightJumpMult : float = 0.5f;
                                     human_weight_influence__maxWeightSpeedMult : float = 1.f;
                                     human_weight_influence__staminaDrainMult : float = 1.f;
                                     entity_mods__weightRunSpeedMult : float = 1.f)
  human_weight_influence_update(human_net_phys, human_inventory__currentWeight, human_weight_influence__minWeight,
                                  human_weight_influence__maxWeight, human_weight_influence__maxWeightAccelerationMult,
                                  human_weight_influence__maxWeightJumpMult, human_weight_influence__maxWeightSpeedMult,
                                  human_weight_influence__staminaDrainMult, entity_mods__weightRunSpeedMult)
[es(tag=gameClient, REQUIRE=watchedByPlr, after=after_entity_mods_apply_sync_point)]
def human_weight_influence_client_es(info : ParallelUpdateFrameDelayed;
                                     var human_net_phys : HumanActor;
                                     human_inventory__currentWeight : float;
                                     human_weight_influence__minWeight : float = 4.f;
                                     human_weight_influence__maxWeight : float  = 15.f;
                                     human_weight_influence__maxWeightAccelerationMult : float = 0.5f;
                                     human_weight_influence__maxWeightJumpMult : float = 0.5f;
                                     human_weight_influence__maxWeightSpeedMult : float = 1.f;
                                     human_weight_influence__staminaDrainMult : float = 1.f;
                                     entity_mods__weightRunSpeedMult : float = 1.f)
  human_weight_influence_update(human_net_phys, human_inventory__currentWeight, human_weight_influence__minWeight,
                                  human_weight_influence__maxWeight, human_weight_influence__maxWeightAccelerationMult,
                                  human_weight_influence__maxWeightJumpMult, human_weight_influence__maxWeightSpeedMult,
                                  human_weight_influence__staminaDrainMult, entity_mods__weightRunSpeedMult)
