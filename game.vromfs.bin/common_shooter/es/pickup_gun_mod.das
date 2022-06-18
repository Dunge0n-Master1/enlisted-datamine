require ecs
require ecs.common
require game.es.events
require inventory
require common_shooter.events_common_shooter


def get_gunMod_eid_by_slot(slot : int; slotName : string; gunMods : Array)
  var resultEid = INVALID_ENTITY_ID
  let modList = get_ecs_EidList(gunMods[slot])
  if modList == null
    return INVALID_ENTITY_ID
  for modEid in *modList
    query(modEid) <| $ [es] (gunAttachable__slotName : string)
      if gunAttachable__slotName == slotName
        resultEid = modEid
    if resultEid != INVALID_ENTITY_ID
      break
  return resultEid


def switch_weap_mod(eid : EntityId; itemEid : EntityId; curGunEid : EntityId; curSlot : int; slotName : string; gunMods : Array)
  if is_item_useful(eid, itemEid)
    return false
  if !is_gunmod_allowed(curGunEid, itemEid)
    return false
  if get_gunMod_eid_by_slot(curSlot, slotName, gunMods) == INVALID_ENTITY_ID
    return false
  return true


[es(tag=server)]
def pickup_gun_mod_es(evt : CmdInventoryPickupGunMod;
                      eid : EntityId;
                      human_weap__currentGunSlot : int;
                      human_weap__gunMods : Array;
                      human_weap__currentGunEid : EntityId;
                      human_weap__gunEids : EidList;
                      human_weap__autoequipMods : bool)
  let itemEid = evt.item
  if human_weap__currentGunSlot < 0
    pickup_item(eid, itemEid)
    return
  let curSlot = human_weap__currentGunSlot
  let curGunEid = human_weap__currentGunEid
  query(itemEid) <| $ [es] (gunAttachable__slotName : string)
    if switch_weap_mod(eid, itemEid, curGunEid, curSlot, gunAttachable__slotName, human_weap__gunMods)
      let toGround = !can_pickup_item_by_volume(itemEid, eid)
      remove_item_from_weap_impl(eid, curSlot, gunAttachable__slotName, toGround)
      pickup_and_install_item_on_weap_impl(eid, itemEid, curSlot, gunAttachable__slotName)
      return
    if human_weap__autoequipMods
      if is_gunmod_allowed(curGunEid, itemEid) // if can attach to current gun
        if get_gunMod_eid_by_slot(curSlot, gunAttachable__slotName, human_weap__gunMods) == INVALID_ENTITY_ID
          pickup_and_install_item_on_weap_impl(eid, itemEid, curSlot, gunAttachable__slotName)
          return
      for slot in iter_range(human_weap__gunEids) // find first gun to can attach gunMod
        if slot == curSlot || human_weap__gunEids[slot] == INVALID_ENTITY_ID // skip the current slot because the check has already been
          continue
        let modEid = get_gunMod_eid_by_slot(slot, gunAttachable__slotName, human_weap__gunMods)
        if modEid == INVALID_ENTITY_ID && is_gunmod_allowed(human_weap__gunEids[slot], itemEid)
          pickup_and_install_item_on_weap_impl(eid, itemEid, slot, gunAttachable__slotName)
          return
    pickup_item(eid, itemEid)