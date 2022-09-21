require ecs
require common_shooter.es.entity_mods_common
require DagorMath
require EnlistedHuman
require HumanPhys
require ecs.safe
require game.es.events

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_speed_mod_applier_es(info : UpdateStageInfoAct;
                                entity_mods__speedMult : float;
                                human_phys__crawlThreshold : float;
                                human_phys__crawlTransitionMoveSpeedMult : float;
                                var human_net_phys : HumanActor&)
  assume currentState = human_net_phys.phys.currentState
  if currentState.height < human_phys__crawlThreshold && currentState.height > -1.
    currentState.moveSpeedMult = human_phys__crawlTransitionMoveSpeedMult
  else
    currentState.moveSpeedMult = entity_mods__speedMult

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_stamina_mod_applier_es(info : UpdateStageInfoAct;
                                  entity_mods__staminaDrain : float;
                                  var human_net_phys : HumanActor&)
  human_net_phys.phys.currentState.staminaDrainMult = entity_mods__staminaDrain

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_jump_mod_applier_es(info : UpdateStageInfoAct;
                               entity_mods__jumpMult : float;
                               var human_net_phys : HumanActor&)
  human_net_phys.phys.currentState.jumpSpeedMult = entity_mods__jumpMult

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_climb_speed_mult_applier_es(info : UpdateStageInfoAct;
                                       entity_mods__climbingSpeedMult : float;
                                       var human_net_phys : HumanActor&)
  human_net_phys.phys.currentState.climbingSpeedMult = entity_mods__climbingSpeedMult

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_restore_stamina_mult_applier_es(info : UpdateStageInfoAct;
                                           entity_mods__restoreStaminaMult : float;
                                           var human_net_phys : HumanActor&)
  human_net_phys.phys.currentState.restoreStaminaMult = entity_mods__restoreStaminaMult

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_sprint_stamina_drain_applier_es(info : UpdateStageInfoAct;
                                           entity_mods__sprintStaminaDrain : float;
                                           var human_stamina_regen_affect__mult : float&;
                                           var human_net_phys : HumanActor&)
  human_stamina_regen_affect__mult = 1.0
  human_net_phys.phys.currentState.staminaSprintDrainMult = entity_mods__sprintStaminaDrain

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_sprint_speed_mult_applier_es(info : UpdateStageInfoAct;
                                        entity_mods__sprintSpeedMult : float;
                                        var human_net_phys : HumanActor&)
  assume currentState = human_net_phys.phys.currentState
  currentState.sprintSpeedMult = currentState.height < 1.0 ? 1.0 : entity_mods__sprintSpeedMult

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_acceleration_mult_applier_es(info : UpdateStageInfoAct;
                                        entity_mods__accelerationMult : float;
                                        var human_net_phys : HumanActor&)
  human_net_phys.phys.currentState.accelerationMult = entity_mods__accelerationMult

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_breath_perks_mult_applier_es(info : UpdateStageInfoAct;
                                        entity_mods__breathAimMult : float;
                                        entity_mods__longerHoldBreathMult : float;
                                        entity_mods__oftenHoldBreathMult : float;
                                        var human_net_phys : HumanActor&)
  human_net_phys.phys.currentState.longerHoldBreathMultInv = safeinv(entity_mods__longerHoldBreathMult)
  human_net_phys.phys.currentState.breathAimMult = entity_mods__breathAimMult
  human_net_phys.phys.currentState.oftenHoldBreathMult = entity_mods__oftenHoldBreathMult

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_faster_change_weapon_applier_es(info : UpdateStageInfoAct;
                                           entity_mods__fasterChangeWeaponMult : float;
                                           var human_net_phys : HumanActor&)
  human_net_phys.phys.currentState.fasterChangeWeaponMult = entity_mods__fasterChangeWeaponMult

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_faster_change_pose_applier_es(info : UpdateStageInfoAct;
                                         human_phys__changePoseSpeed : float;
                                         human_phys__changePoseSpeedCrawl : float;
                                         human_phys__afterJumpDampingChangePoseSpeedDown : float;
                                         human_phys__afterJumpDampingChangePoseSpeedUp : float;
                                         entity_mods__fasterChangePoseMult : float;
                                         human_phys__afterJumpDampingTime : float;
                                         var human_net_phys : HumanActor&)
  assume currentState = human_net_phys.phys.currentState
  if info.curTime < currentState.afterJumpDampingEndTime
    currentState.fasterChangePoseMult = human_phys__afterJumpDampingChangePoseSpeedDown
  elif info.curTime < currentState.afterJumpDampingEndTime + human_phys__afterJumpDampingTime
    currentState.fasterChangePoseMult = human_phys__afterJumpDampingChangePoseSpeedUp
  else
    let isCrawl = currentState.height < 0.
    let speed = isCrawl ? human_phys__changePoseSpeedCrawl : human_phys__changePoseSpeed
    currentState.fasterChangePoseMult = speed * entity_mods__fasterChangePoseMult

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_crawl_crouch_speed_applier_es(info : UpdateStageInfoAct;
                                         entity_mods__crawlCrouchSpeedMult : float;
                                         human_phys__crawlThreshold : float;
                                         human_phys__crawlTransitionMoveSpeedMult : float;
                                         var human_net_phys : HumanActor&)
  assume currentState = human_net_phys.phys.currentState
  if currentState.height < human_phys__crawlThreshold && currentState.height > -1.
    currentState.crawlCrouchSpeedMult = human_phys__crawlTransitionMoveSpeedMult
  else
    currentState.crawlCrouchSpeedMult = entity_mods__crawlCrouchSpeedMult

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_weapon_turning_speed_applier_es(info : UpdateStageInfoAct;
                                           entity_mods__weaponTurningSpeedMult : float;
                                           var human_net_phys : HumanActor&)
  human_net_phys.phys.currentState.weaponTurningSpeedMult = entity_mods__weaponTurningSpeedMult

[es(after=before_entity_mods_apply_sync_point, before=(human_phys_es, after_entity_mods_apply_sync_point))]
def entity_faster_aiming_after_fire_applier_es(info : UpdateStageInfoAct;
                                               entity_mods__aimingAfterFireMult : float;
                                               var human_net_phys : HumanActor&)
  human_net_phys.phys.currentState.aimingAfterFireMult = entity_mods__aimingAfterFireMult
