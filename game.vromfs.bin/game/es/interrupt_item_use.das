require ecs
require app
require HumanPhys
require EnlistedHuman
require game.es.events

def can_use_while_moving(eid : EntityId)
  return get_bool(eid, "item__canUseWhileMoving") ?? true

def human_inventory_interrupt_item_use_base(cur_time : float;
                                            eid : EntityId;
                                            human_inventory__entityToUse : EntityId;
                                            human_net_phys : HumanActor;
                                            ct : HumanControlState;
                                            human_weap__reloadFinishTime : float;
                                            human_weap__weapModActivateStartTime : float;
                                            isInVehicle : bool;
                                            human_freefall__isFreefall : bool;
                                            burning__isBurning : bool;
                                            parachuteDeployed : Tag?)
  assume currentState = human_net_phys.phys.currentState
  let standing = currentState.moveState == HUMoveState EMS_STAND
  var interruptsReloading = false
  var canUseWhileSwimming = false
  var canUseUnderWater = false
  var shouldIgnoreAim = false
  var shouldIgnoreLmb = false
  var stopUseWhileBurning = false
  query(human_inventory__entityToUse) <| $ [es] (item__interruptsReloading : Tag?;
                                                 item__canUseWhileSwimmingStill : Tag?;
                                                 item__canUseWhileSwimming : Tag?;
                                                 item__canUseUnderWater : Tag?;
                                                 item__ignoreAimInterrupt : Tag?;
                                                 item__ignoreLmbInterrupt : Tag?;
                                                 item__stopUseWhileBurning : Tag?)
    interruptsReloading = item__interruptsReloading != null
    canUseWhileSwimming = (standing ? item__canUseWhileSwimmingStill : item__canUseWhileSwimming) != null
    canUseUnderWater = item__canUseUnderWater != null
    shouldIgnoreAim = item__ignoreAimInterrupt != null
    shouldIgnoreLmb = item__ignoreLmbInterrupt != null
    stopUseWhileBurning = item__stopUseWhileBurning != null

  if ((human_weap__reloadFinishTime > cur_time && !interruptsReloading)
      || currentState |> human_phys_state_get_isClimbing()
      || (currentState |> human_phys_state_get_is_swimming() && !canUseWhileSwimming)
      || (currentState |> human_phys_state_get_is_underwater() && !canUseUnderWater)
      || (ct |> is_control_bit_set(HumanPhysControlType HCT_ZOOM_VIEW) && !shouldIgnoreAim)
      || (ct |> is_control_bit_set(HumanPhysControlType HCT_SHOOT) && !shouldIgnoreLmb)
      || ct |> is_control_bit_set(HumanPhysControlType HCT_MELEE)
      || ct |> is_control_bit_set(HumanPhysControlType HCT_THROW)
      || human_weap__weapModActivateStartTime > 0.
      || (isInVehicle && currentState.isAiming)
      || human_freefall__isFreefall
      || parachuteDeployed != null
      || (stopUseWhileBurning && burning__isBurning))
    sendEventImmediate(eid, [[EventInterruptItemUse]])

def is_interrupted_by_moving(human_net_phys : HumanActor; human_inventory__entityToUse : EntityId)
  assume currentState = human_net_phys.phys.currentState
  assume appliedCT = human_net_phys.phys.appliedCT
  if currentState.moveState == HUMoveState EMS_SPRINT && !currentState |> human_phys_state_stoppedSprint()
    return true

  let moving = appliedCT.walkSpeed > 0.
  if moving && currentState.isCrawl
    return true

  if (moving || appliedCT |> is_control_bit_set(HumanPhysControlType HCT_JUMP)) && !can_use_while_moving(human_inventory__entityToUse)
    return true

  return false

// item use can stop player on the server. Thus we dont want to interrupt item use on client due to movement
// because movement state sync can happen after the client system will interrupt item use
// we cant ran all checks on server only because it feels terrible on high ping
def human_inventory_interrupt_item_use_server(cur_time : float;
                                              eid : EntityId;
                                              human_inventory__entityToUse : EntityId;
                                              human_net_phys : HumanActor;
                                              ct : HumanControlState;
                                              human_weap__reloadFinishTime : float;
                                              human_weap__weapModActivateStartTime : float;
                                              isInVehicle : bool;
                                              human_freefall__isFreefall : bool;
                                              burning__isBurning : bool;
                                              parachuteDeployed : Tag?)
  if is_interrupted_by_moving(human_net_phys, human_inventory__entityToUse)
    sendEventImmediate(eid, [[EventInterruptItemUse]])
    return
  human_inventory_interrupt_item_use_base(cur_time, eid, human_inventory__entityToUse, human_net_phys, ct,
                                          human_weap__reloadFinishTime, human_weap__weapModActivateStartTime, isInVehicle,
                                          human_freefall__isFreefall, burning__isBurning, parachuteDeployed)



[es(tag=gameClient, after=(human_input_es, human_phys_es), before=before_human_inventory_use_update)]
def human_inventory_interrupt_item_use_es(info : UpdateStageInfoAct;
                                          eid : EntityId;
                                          human_inventory__entityToUse : EntityId;
                                          human_net_phys : HumanActor;
                                          human_weap__reloadFinishTime : float;
                                          human_weap__weapModActivateStartTime : float;
                                          isInVehicle : bool;
                                          burning__isBurning : bool;
                                          human_freefall__isFreefall : bool = false;
                                          parachuteDeployed : Tag?)
  if !!human_inventory__entityToUse
    human_inventory_interrupt_item_use_base(info.curTime, eid, human_inventory__entityToUse, human_net_phys, human_net_phys.phys.producedCT,
                                            human_weap__reloadFinishTime, human_weap__weapModActivateStartTime, isInVehicle,
                                            human_freefall__isFreefall, burning__isBurning, parachuteDeployed)

[es(tag=server, before=human_weap_es)]
def human_inventory_interrupt_item_use_on_post_phys_es(evt : CmdPostPhysUpdate;
                                                       eid : EntityId;
                                                       human_inventory__entityToUse : EntityId;
                                                       human_net_phys : HumanActor;
                                                       human_weap__reloadFinishTime : float;
                                                       human_weap__weapModActivateStartTime : float;
                                                       isInVehicle : bool;
                                                       burning__isBurning : bool;
                                                       human_freefall__isFreefall : bool = false;
                                                       parachuteDeployed : Tag?)
  if !!human_inventory__entityToUse
    human_inventory_interrupt_item_use_server(get_sync_time(), eid, human_inventory__entityToUse, human_net_phys,
                                              human_net_phys.phys.appliedCT, human_weap__reloadFinishTime,
                                              human_weap__weapModActivateStartTime, isInVehicle,
                                              human_freefall__isFreefall, burning__isBurning, parachuteDeployed)

[es(on_event=EventEntityDied, track=fortification_repair__active, on_event=(EventEnterVehicle, EventEntityDowned, EventInterruptItemUse, EventEntityRevived))]
def interrupt_item_use_es(evt : Event;
                          fortification_repair__active : bool;
                          var human_inventory__entityUseEnd : float&;
                          var human_inventory__entityUseStart : float&;
                          var human_inventory__entityToUse : ecs::EntityId&;
                          var human_inventory__targetToUse : ecs::EntityId&;
                          var human_inventory__savedUseProgress : float&;
                          var human_inventory__usePausedUntilTime : float&)
  if has(human_inventory__entityToUse, "item__useInterruptDisabled") && !fortification_repair__active
    return
  ecs::query(human_inventory__entityToUse) <| $ [es] (var item__ownerOnUseEffectEid : EntityId&)
    destroyEntity(item__ownerOnUseEffectEid)
    item__ownerOnUseEffectEid = INVALID_ENTITY_ID
  if human_inventory__targetToUse != INVALID_ENTITY_ID
    query(human_inventory__targetToUse) <| $ [es] (var hitpoints__revivingCount : int&)
      if hitpoints__revivingCount > 0
        hitpoints__revivingCount--
  human_inventory__entityUseEnd = -1.0
  human_inventory__entityUseStart = -1.0
  human_inventory__entityToUse = INVALID_ENTITY_ID
  human_inventory__targetToUse = INVALID_ENTITY_ID
  human_inventory__savedUseProgress = -1.0
  human_inventory__usePausedUntilTime = -1.0
