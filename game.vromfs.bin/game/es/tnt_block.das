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
require GunAnim
require Gun

def detonate_tnt_block(eid : EntityId)
  query(eid) <| $ [es] (transform : float3x4;
                        tnt_block__activatorTemplate : string;
                        placeable_item__ownerEid : EntityId)
    print("detonate_tnt_block: eid={eid}, activatorTemplate={tnt_block__activatorTemplate}, placeable_item__ownerEid={placeable_item__ownerEid}")
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
                                       var tnt_block_exploder__isShootPressed : bool&;
                                       var tnt_block_exploder__isLoaded : bool&)
  tnt_block_exploder__isShootPressed = false
  tnt_block_exploder__isLoaded = true

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

[es(tag=gameClient, REQUIRE=tntBlockExploder, after=gun_anim_updater_es)]
def tnt_block_exploder_update_anim(info : UpdateStageInfoAct;
                                   gun_anim : GunAnim;
                                   slot_attach__attachedTo : EntityId;
                                   tnt_block_exploder__boltActionProgress : float;
                                   tnt_block_exploder__reloadProgress : float;
                                   var phys_vars : PhysVars&)
  if !slot_attach__attachedTo
    return

  setVar(phys_vars, gun_anim.boltActionVarId, tnt_block_exploder__boltActionProgress)
  setVar(phys_vars, gun_anim.reloadVarId, tnt_block_exploder__reloadProgress)

[es(REQUIRE=tntBlockExploder)]
def tnt_block_exploder_explode_es(evt : CmdWeapPhysUpdate;
                                  gun : Gun;
                                  slot_attach__attachedTo : EntityId;
                                  tnt_block_exploder__reloadAnimTime : float;
                                  tnt_block_exploder__explodeAtBoltActionProgress : float;
                                  var tnt_block_exploder__isShootPressed : bool&;
                                  var tnt_block_exploder__isLoaded : bool&;
                                  var tnt_block_exploder__explodeAnimStartTime : float&;
                                  var tnt_block_exploder__explodeAnimEndTime : float&;
                                  var tnt_block_exploder__boltActionProgress : float&;
                                  var tnt_block_exploder__reloadProgress : float&)
  if !evt.isForReal
    return

  query(slot_attach__attachedTo) <| $ [es] (human_weap__gunEids : EidList;
                                            var human_net_phys : HumanActor)
    tnt_block_exploder__boltActionProgress = 0.0
    tnt_block_exploder__reloadProgress = 0.0

    if tnt_block_exploder__isShootPressed
      tnt_block_exploder__boltActionProgress = cvt(evt.atTime, tnt_block_exploder__explodeAnimStartTime, tnt_block_exploder__explodeAnimEndTime, 0.0f, 1.0)
    elif !tnt_block_exploder__isLoaded
      let reloadAnimStartTime = tnt_block_exploder__explodeAnimEndTime
      let reloadAnimEndTime = tnt_block_exploder__explodeAnimEndTime + tnt_block_exploder__reloadAnimTime
      tnt_block_exploder__reloadProgress = cvt(evt.atTime, reloadAnimStartTime, reloadAnimEndTime, 0.0f, 1.0)

    let isEquippingComplete = human_net_phys.phys.currentState.weapEquipState.progress == 0.0
    if evt.gctrl.shoot && !tnt_block_exploder__isShootPressed && tnt_block_exploder__isLoaded && isEquippingComplete
      tnt_block_exploder__isShootPressed = true
      tnt_block_exploder__explodeAnimStartTime = evt.atTime
      tnt_block_exploder__explodeAnimEndTime = evt.atTime + gun.gunProps.boltActionTime
      print("tnt_block_exploder_explode_es: shoot pressed: explodeAnimStartTime={tnt_block_exploder__explodeAnimStartTime}, explodeAnimEndTime={tnt_block_exploder__explodeAnimEndTime}")
    elif tnt_block_exploder__isShootPressed && tnt_block_exploder__boltActionProgress >= 1.0
      tnt_block_exploder__isShootPressed = false
      print("tnt_block_exploder_explode_es: bolt action end: boltActionProgress={tnt_block_exploder__boltActionProgress}")
    elif tnt_block_exploder__isShootPressed && tnt_block_exploder__isLoaded && tnt_block_exploder__boltActionProgress >= tnt_block_exploder__explodeAtBoltActionProgress
      tnt_block_exploder__isLoaded = false
      sendEvent(slot_attach__attachedTo, [[CmdExplodeTntBlocks]])
      print("tnt_block_exploder_explode_es: explode tnt: boltActionProgress={tnt_block_exploder__boltActionProgress}, explodeAtBoltActionProgress={tnt_block_exploder__explodeAtBoltActionProgress}")
    elif !tnt_block_exploder__isLoaded && tnt_block_exploder__reloadProgress >= 1.0
      tnt_block_exploder__isLoaded = true
      switch_to_first_weap_with_ammo(human_weap__gunEids, human_net_phys.phys)
      print("tnt_block_exploder_explode_es: switch to other weapon: reloadProgress={tnt_block_exploder__reloadProgress}")

[es(tag=server)]
def tnt_block_exploder_explode_all_tnt_es(evt : CmdExplodeTntBlocks;
                                          eid aka human_owner_eid : EntityId)
  print("tnt_block_exploder_explode_all_tnt_es: human_owner_eid={human_owner_eid}")
  query() <| $ [es(REQUIRE=tntBlock)] (eid : EntityId; placeable_item__ownerEid : EntityId)
    if placeable_item__ownerEid == human_owner_eid
      print("tnt_block_exploder_explode_all_tnt_es: detonate tnt: eid={eid}, placeable_item__ownerEid={placeable_item__ownerEid}")
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
