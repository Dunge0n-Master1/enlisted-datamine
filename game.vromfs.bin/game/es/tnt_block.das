require ecs
require ecs.common
require math.base
require DagorMath
require AnimV20
require Dacoll
require GridCollision
require HumanPhys
require common_shooter.events_common_shooter
require common_shooter.es.human_weap_common
require enlisted.events_enlisted
require EnlistedNet
require EnlistedHuman
require enlisted.game.es.placeable_item_common
require PhysVars
require Gun


enum ExploderState
  Idle = 0
  PreExplode
  PostExplode
  Reloading


def detonate_tnt_block(eid : EntityId)
  query(eid) <| $ [es] (transform : float3x4;
                        tnt_block__activatorTemplate : string;
                        placeable_item__ownerEid : EntityId)
    createEntity(tnt_block__activatorTemplate) <| $(var init : ComponentsInitializer)
      set(init, "ownerEid", placeable_item__ownerEid)
      set(init, "transform", transform)
    destroyEntity(eid)

[es(tag=server, on_event=EventEntityDied, tag=server, REQUIRE=tntBlock)]
def tnt_block_explode_on_die_es(evt : Event; eid : EntityId)
  detonate_tnt_block(eid)

[es]
def tnt_block_choose_next_when_finish_place_es(evt : CmdFinishPlacePlaceableItem;
                                               human_weap__currentGunEid : EntityId;
                                               inventoryGunsItemsEids : EidList;
                                               var forcedNextInventoryGunEid : EntityId&)
  if human_weap__currentGunEid != INVALID_ENTITY_ID && has(human_weap__currentGunEid, "tntBlock")
    for gunEid in inventoryGunsItemsEids
      if gunEid != human_weap__currentGunEid && has(gunEid, "tntBlock")
        forcedNextInventoryGunEid = gunEid
        break

[es(tag=server, on_event=EventEntityDied, REQUIRE=vehicle)]
def tnt_block_attached_to_vehicle_on_vehicle_die(evt : Event; eid aka vehicle_eid : EntityId)
  query() <| $ [es(REQUIRE=tntBlock)] (eid : EntityId; node_attached__entity : EntityId)
    if node_attached__entity == vehicle_eid
      detonate_tnt_block(eid)

[es]
def tnt_block_exploder_reset_on_detach(evt : CmdWeapAttach;
                                       var tnt_block_exploder__state : int&)
  tnt_block_exploder__state = int(ExploderState Idle)


[es(tag=server, track=human_weap__currentGunEid)]
def tnt_block_exploder_remove_exploder(evt : Event;
                                       eid : EntityId;
                                       human_weap__currentGunEid : EntityId;
                                       var itemContainer : EidList;
                                       var human_weap__gunEids : EidList)
  if has(human_weap__currentGunEid, "tntBlockExploder")
    return

  let tntBlockExploderIdx = find_index_if(each(itemContainer)) <| $(itemEid : EntityId)
    return has(itemEid, "tntBlockExploder")
  if tntBlockExploderIdx < 0
    return

  let tntBlockIdx = find_index_if(each(itemContainer)) <| $(itemEid : EntityId)
    return has(itemEid, "tntBlock")
  if tntBlockIdx > -1
    return

  let hasInstalledTnt = find_query() <| $ [es(REQUIRE=tntBlock)] (placeable_item__ownerEid : EntityId)
    return placeable_item__ownerEid == eid
  if hasInstalledTnt
    return

  human_weap__gunEids[int(HUWeaponSlots EWS_SPECIAL)] = INVALID_ENTITY_ID
  destroyEntity(itemContainer[tntBlockExploderIdx])
  erase(itemContainer, tntBlockExploderIdx)


[es(tag=gameClient, REQUIRE=tntBlockExploder, after=tnt_block_exploder_update_anim)]
def tnt_block_exploder_update_anim_vars(info : ParallelUpdateFrameDelayed;
                                        gun_anim__boltActionVarId : int;
                                        gun_anim__reloadVarId : int;
                                        slot_attach__attachedTo : EntityId;
                                        tnt_block_exploder__boltActionProgress : float;
                                        tnt_block_exploder__reloadProgress : float;
                                        var phys_vars : PhysVars&)
  if !slot_attach__attachedTo
    return

  setVar(phys_vars, gun_anim__boltActionVarId, tnt_block_exploder__boltActionProgress)
  setVar(phys_vars, gun_anim__reloadVarId, tnt_block_exploder__reloadProgress)


[es(REQUIRE=tntBlockExploder, after=gun_anim_updater_es)]
def tnt_block_exploder_update_anim(info : ParallelUpdateFrameDelayed;
                                   slot_attach__attachedTo : EntityId;
                                   tnt_block_exploder__state : int;
                                   tnt_block_exploder__reloadAnimTime : float;
                                   tnt_block_exploder__explodeAnimStartTime : float;
                                   tnt_block_exploder__explodeAnimEndTime : float;
                                   var tnt_block_exploder__boltActionProgress : float&;
                                   var tnt_block_exploder__reloadProgress : float&)
  if !slot_attach__attachedTo
    return

  tnt_block_exploder__boltActionProgress = 0.0
  tnt_block_exploder__reloadProgress = 0.0

  if tnt_block_exploder__state == int(ExploderState PreExplode) || tnt_block_exploder__state == int(ExploderState PostExplode)
    tnt_block_exploder__boltActionProgress = cvt(info.curTime, tnt_block_exploder__explodeAnimStartTime, tnt_block_exploder__explodeAnimEndTime, 0.0, 1.0)
  elif tnt_block_exploder__state == int(ExploderState Reloading)
    let reloadAnimStartTime = tnt_block_exploder__explodeAnimEndTime
    let reloadAnimEndTime = tnt_block_exploder__explodeAnimEndTime + tnt_block_exploder__reloadAnimTime
    tnt_block_exploder__reloadProgress = cvt(info.curTime, reloadAnimStartTime, reloadAnimEndTime, 0.0, 1.0)


[es(REQUIRE=tntBlockExploder)]
def tnt_block_exploder_update_state_es(evt : CmdWeapPhysUpdate;
                                       gun : Gun;
                                       slot_attach__attachedTo : EntityId;
                                       tnt_block_exploder__explodeAtBoltActionProgress : float;
                                       tnt_block_exploder__boltActionProgress : float;
                                       tnt_block_exploder__reloadProgress : float;
                                       var tnt_block_exploder__state : int&;
                                       var tnt_block_exploder__explodeAnimStartTime : float&;
                                       var tnt_block_exploder__explodeAnimEndTime : float&)
  if !evt.isForReal
    return

  query(slot_attach__attachedTo) <| $ [es] (human_net_phys : HumanActor)
    let isEquippingComplete = human_net_phys.phys.currentState.weapEquipState.progress == 0.0

    if evt.gctrl.shoot && tnt_block_exploder__state == int(ExploderState Idle) && isEquippingComplete
      tnt_block_exploder__state = int(ExploderState PreExplode)
      tnt_block_exploder__explodeAnimStartTime = evt.atTime
      tnt_block_exploder__explodeAnimEndTime = evt.atTime + gun.gunProps.boltActionTime
    elif tnt_block_exploder__state == int(ExploderState PreExplode) && tnt_block_exploder__boltActionProgress >= tnt_block_exploder__explodeAtBoltActionProgress
      tnt_block_exploder__state = int(ExploderState PostExplode)
      sendEvent(slot_attach__attachedTo, [[CmdExplodeTntBlocks]])
    elif tnt_block_exploder__state == int(ExploderState PostExplode) && tnt_block_exploder__boltActionProgress >= 1.0
      tnt_block_exploder__state = int(ExploderState Reloading)
    elif tnt_block_exploder__state == int(ExploderState Reloading) && tnt_block_exploder__reloadProgress >= 1.0
      tnt_block_exploder__state = int(ExploderState Idle)


[es(tag=server, track=tnt_block_exploder__state)]
def tnt_block_exploder_switch_off_after_explode(evt : Event;
                                                slot_attach__attachedTo : EntityId;
                                                tnt_block_exploder__state : int)
  if !!slot_attach__attachedTo && tnt_block_exploder__state == int(ExploderState Idle)
    send_net_event(slot_attach__attachedTo, [[CmdSwitchToFirstWeapWithAmmo]])


[es(tag=server)]
def tnt_block_exploder_explode_all_tnt_es(evt : CmdExplodeTntBlocks;
                                          eid aka human_owner_eid : EntityId)
  query() <| $ [es(REQUIRE=tntBlock)] (eid : EntityId; placeable_item__ownerEid : EntityId)
    if placeable_item__ownerEid == human_owner_eid
      detonate_tnt_block(eid)

[es(tag=server, before=next_weapon_item_request_es)]
def tnt_block_switch_to_exploder(evt : CmdNextSpecialGun;
                                 inventoryGunsItemsEids : EidList;
                                 var forcedNextInventoryGunEid : EntityId&;
                                 currentInventoryGunIdx : int&)
  if currentInventoryGunIdx > -1 && currentInventoryGunIdx < length(inventoryGunsItemsEids)
    let curGunEid = inventoryGunsItemsEids[currentInventoryGunIdx]
    if has(curGunEid, "tntBlock")
      for gunEid in inventoryGunsItemsEids
        if gunEid != curGunEid && has(gunEid, "tntBlockExploder")
          forcedNextInventoryGunEid = gunEid
          break
    elif has(curGunEid, "tntBlockExploder")
      for gunEid in inventoryGunsItemsEids
        if gunEid != curGunEid && !has(gunEid, "tntBlock") && !has(gunEid, "tntBlockExploder")
          forcedNextInventoryGunEid = gunEid
          break


[es(tag=server)]
def tnt_block_choose_on_loot(evt : EventInventorySpecialItemAdded;
                             human_weap__currentGunEid : EntityId;
                             inventoryGunsItemsEids : EidList;
                             var currentInventoryGunIdx : int&)
  if has(human_weap__currentGunEid, "tntBlockExploder") && has(evt.itemEid, "tntBlock")
    currentInventoryGunIdx = find_index(inventoryGunsItemsEids, evt.itemEid)
