require ecs
require app
require EnlistedHuman
require HumanPhys
require DagorMath
require game.es.events
require enlisted.events_enlisted

def is_in_air(human_phys__inAirTime : float)
  return human_phys__inAirTime != 0.

def was_in_air(human_phys__previousInAirTime : float; human_phys__inAirTimeThreshold : float)
  return human_phys__previousInAirTime > human_phys__inAirTimeThreshold

[es]
def human_phys_set_in_air_time(update : CmdPostPhysUpdate;
                               human_net_phys : HumanActor;
                               var human_phys__previousInAirTime : float&;
                               var human_phys__inAirTime : float&)
  assume currentState = human_net_phys.phys.currentState
  human_phys__previousInAirTime = human_phys__inAirTime
  let isInAir = (int(currentState.isInAirHistory) & 1) != 0 && (int(currentState.states) & int(StateFlag ST_SWIM)) == 0
  human_phys__inAirTime = isInAir ? (human_phys__inAirTime + update.dt) : 0.f

[es(after=human_phys_set_in_air_time)]
def human_phys_in_air_long(update : CmdPostPhysUpdate;
                           human_phys__afterJumpDampingTime : float;
                           human_phys__previousInAirTime : float;
                           human_phys__inAirTime : float;
                           human_phys__inAirTimeThreshold : float;
                           human_phys__inAirSpeedThreshold : float;
                           var human_phys__isInAirLong : bool&;
                           var human_net_phys : HumanActor&;
                           var human_phys__jumpEndTime : float&)
  assume currentState = human_net_phys.phys.currentState

  let wasInAir = was_in_air(human_phys__previousInAirTime, human_phys__inAirTimeThreshold)
  let isInAir = is_in_air(human_phys__inAirTime)

  if isInAir && wasInAir
    human_phys__isInAirLong = abs(currentState.velocity.y) > human_phys__inAirSpeedThreshold
  if !isInAir && human_phys__isInAirLong
    let physTime = float(update.tick) * update.dt
    human_phys__jumpEndTime = physTime
    human_phys__isInAirLong = false
    currentState.afterJumpDampingEndTime = human_phys__jumpEndTime + human_phys__afterJumpDampingTime

[es(after=human_phys_set_in_air_time)]
def human_phys_set_after_jump_damping(update : CmdPostPhysUpdate;
                                      human_phys__previousInAirTime : float;
                                      human_phys__inAirTime : float;
                                      human_phys__inAirTimeThreshold : float;
                                      human_phys__afterJumpDampingMinSpeedY : float;
                                      human_phys__afterJumpDampingMaxSpeedY : float;
                                      human_phys__afterJumpDampingMinHeight : float;
                                      human_phys__afterJumpDampingMaxHeight : float;
                                      var human_net_phys : HumanActor&)
  assume currentState = human_net_phys.phys.currentState
  let isInAir = is_in_air(human_phys__inAirTime)
  let wasInAir = was_in_air(human_phys__previousInAirTime, human_phys__inAirTimeThreshold)

  if !wasInAir && isInAir
    currentState.afterJumpDampingHeight = 1.f

  if isInAir && currentState.velocity.y < human_phys__afterJumpDampingMinSpeedY
    currentState.afterJumpDampingHeight = min(
      currentState.afterJumpDampingHeight,
      cvt(currentState.velocity.y, human_phys__afterJumpDampingMinSpeedY, human_phys__afterJumpDampingMaxSpeedY,
                                   human_phys__afterJumpDampingMinHeight, human_phys__afterJumpDampingMaxHeight))


def update_friction(var human_net_phys : HumanActor&; human_phys__crawlTransitionFrictionMult)
  assume currentState = human_net_phys.phys.currentState
  let isGointToCrawl = (int(currentState.states) & int(StateFlag ST_CRAWL)) != 0 && !currentState.isCrawl
  currentState.frictionMult = isGointToCrawl ? human_phys__crawlTransitionFrictionMult : 1.0

[es(tag=netClient, before=human_phys_es, REQUIRE=hero)]
def human_phys_set_crawl_transition_friction_local(info : ParallelUpdateFrameDelayed;
                                                   human_phys__crawlTransitionFrictionMult : float;
                                                   var human_net_phys : HumanActor&)
  update_friction(human_net_phys, human_phys__crawlTransitionFrictionMult)

[es(tag=server, before=human_phys_es)]
def human_phys_set_crawl_transition_friction(info : ParallelUpdateFrameDelayed;
                                             human_phys__crawlTransitionFrictionMult : float;
                                             var human_net_phys : HumanActor&)
  update_friction(human_net_phys, human_phys__crawlTransitionFrictionMult)

[es(after=keep_human_net_phys_cur_state_es)]
def keep_human_net_phys_zoom_render_state_es(info : UpdateStageInfoAct;
                                             human_net_phys__isZooming : bool;
                                             var human_net_phys__isZoomingRenderData : bool&)
  human_net_phys__isZoomingRenderData = human_net_phys__isZooming

[es(after=human_phys_es)]
def keep_human_net_phys_cur_state_es(info : ParallelUpdateFrameDelayed;
                                     human_net_phys : HumanActor;
                                     var human_net_phys__curMoveState : int&;
                                     var human_net_phys__isHoldBreath : bool&;
                                     var human_net_phys__isSwimming : bool&;
                                     var human_net_phys__isUnderwater : bool&;
                                     var human_net_phys__isAiming : bool&;
                                     var human_net_phys__isOnGround : bool&;
                                     var human_net_phys__isCrawl : bool&;
                                     var human_net_phys__isCrouch : bool&;
                                     var human_net_phys__deltaVelIgnoreAmount : float&;
                                     var human_net_phys__aimPosition : float&;
                                     var human_net_phys__standState : int&;
                                     var human_net_phys__isInAir : bool&;
                                     var human_net_phys__velocity : float3&;
                                     var human_net_phys__locationPos : DPoint3&;
                                     var human_net_phys__isHctAim : bool&;
                                     var human_net_phys__isHctShoot : bool&;
                                     var human_net_phys__isHoldGunModeBit : bool&;
                                     var human_net_phys__maxStamina : float&;
                                     var human_net_phys__maxStaminaMult : float&;
                                     var human_net_phys__staminaBoostMult : float&;
                                     var human_net_phys__isZooming : bool&)
  assume currentState = human_net_phys.phys.currentState

  human_net_phys__curMoveState = int(currentState.moveState)
  human_net_phys__isHoldBreath = is_hold_breath(currentState)
  human_net_phys__isSwimming = human_phys_state_get_is_swimming(currentState)
  human_net_phys__isUnderwater = human_phys_state_get_is_underwater(currentState)
  human_net_phys__isAiming = currentState.isAiming
  human_net_phys__isCrawl = currentState.isCrawl
  human_net_phys__isCrouch = currentState.isCrouch
  human_net_phys__isOnGround = (uint(currentState.states) & uint(StateFlag ST_ON_GROUND)) != 0u
  human_net_phys__deltaVelIgnoreAmount = currentState.deltaVelIgnoreAmount
  human_net_phys__velocity = currentState.velocity
  human_net_phys__aimPosition = currentState.aimPosition
  human_net_phys__standState = int(currentState.standState)
  human_net_phys__isInAir = (uint(currentState.isInAirHistory) & 1u) != 0u && (uint(currentState.states) & uint(StateFlag ST_SWIM)) == 0u
  human_net_phys__locationPos = currentState.location.P
  human_net_phys__isHctAim = is_control_bit_set(human_net_phys.phys.appliedCT, HumanPhysControlType HCT_AIM)
  human_net_phys__isHctShoot = is_control_bit_set(human_net_phys.phys.appliedCT, HumanPhysControlType HCT_SHOOT)
  human_net_phys__isHoldGunModeBit = is_control_bit_set(human_net_phys.phys.appliedCT, HumanPhysControlType HCT_HOLD_GUN_MODE)
  human_net_phys__maxStamina = human_net_phys.phys.maxStamina
  human_net_phys__maxStaminaMult = human_net_phys.phys.currentState.maxStaminaMult
  human_net_phys__staminaBoostMult = human_net_phys.phys.currentState.staminaBoostMult
  human_net_phys__isZooming = human_net_phys.phys.currentState.isZooming

[es(after=before_net_phys_sync, before=after_net_phys_sync)]
def human_phys_save_weap_state_es(info : ParallelUpdateFrameDelayed;
                                  human_net_phys : HumanActor;
                                  var human_net_phys__weapEquipCurState : int&;
                                  var human_net_phys__weapEquipNextSlot : int&)
  human_net_phys__weapEquipCurState = int(human_net_phys.phys.currentState.weapEquipState.curState)
  human_net_phys__weapEquipNextSlot = int(human_net_phys.phys.currentState.weapEquipState.nextSlot)

[es]
def reset_delayed_jump_in_transition_to_crawl(update : CmdPostPhysUpdate;
                                              human_phys__crawlThreshold : float;
                                              var human_net_phys : HumanActor)
  assume currentState = human_net_phys.phys.currentState
  if currentState.height < human_phys__crawlThreshold
    currentState.jumpStartTime = -1.
