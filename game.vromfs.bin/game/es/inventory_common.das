module inventory_common shared
require ecs
require ecs.common
require inventory
require DagorMath
require DagorMathUtils
require DngHuman
require HumanPhys
require AnimV20
require CollRes
require Dacoll
require DagorSystem
require DngNet
require ecs.safe
require DngWeapon
require common_shooter.es.human_weap_common
require common_shooter.events_common_shooter
require game.es.events


def get_item_use_time(item : EntityId; is_downed : bool; is_self_targeting : bool)
  var useTime = -1f
  var hasUseTime = false
  if is_self_targeting
    query(item) <| $ [es] (item__useTime : float; item__downedTimeMultiplier : float = 1f)
      useTime = item__useTime  * (is_downed ? item__downedTimeMultiplier : 1f)
      hasUseTime = true
  else
    query(item) <| $ [es] (item__useTimeToTarget : float; item__downedTimeMultiplier : float = 1f)
      useTime = item__useTimeToTarget * (is_downed ? item__downedTimeMultiplier : 1.f)
      hasUseTime = true
  if hasUseTime && useTime < 0f
    let compName = is_self_targeting ? "useTime" : "useTimeToTarget"
    logerr("item.{compName} < 0 {getEntityTemplateName(item)}")
  return useTime


def push_item_in_cont(owner_eid : EntityId; name : string |#)
  return createEntity(name) <| $(var init : ComponentsInitializer)
    set(init, "item__ownerEid", owner_eid)

def remove_item_from_cont(eid : EntityId; var itemContainer : EidList&) : bool
  let idx = find_index(itemContainer, eid)
  if idx == -1
    return false
  itemContainer |> erase(idx)
  return true

struct ItemPickupScore
  score : float
  useful : bool


def get_item_pickup_score(eid, item_eid : EntityId; view_convex : Point4List; view_itm : float3x4; aimDir, aimFrom, aimTo, minPickupBox : float3; was_selected : bool) : ItemPickupScore
  var ret = [[ItemPickupScore score=-1.0, useful=false]]
  ecs::query(item_eid) <| $ [es] (animchar_render__enabled : bool = true;
                                  item__lastOwner : EntityId;
                                  item__equipToSlots : ecs::Array const?;
                                  var transform : float3x4 const?;
                                  collres : CollisionResource const?;
                                  animchar : AnimcharBaseComponent;
                                  animchar_render : AnimcharRendComponent;
                                  item__id : int = INVALID_ITEM_ID;
                                  item_pickup_priority__lookAtWeight : float = 4.f;
                                  item_pickup_priority__usefulWeight : float = 2.f;
                                  item_pickup_priority__angleWeight : float = 1.f;
                                  item_pickup_priority__useCollresMinWidth : float = 1.5f;
                                  item__visible : bool = true;
                                  container__destroyEmpty = true)
    if !animchar_render__enabled || !item__visible
      return
    if item__id == INVALID_ITEM_ID && item__equipToSlots == null
      if !container__destroyEmpty
        ret.score = 0.01 // very small score for not destroyed loot container
      return

    if transform == null
      transform = get_TMatrix(item__lastOwner, "transform")
    if transform == null
      return

    var lbb = BBox3()
    scene_instance_get_local_bounding_box(animchar_render.sceneInstance, lbb)
    lbb |> bbox3_add(minPickupBox)
    lbb |> bbox3_add(-minPickupBox)
    let entPos = (*transform) * lbb.center
    let checkPos = view_itm * entPos
    for plane in view_convex
      let dist = distance_plane_point3(plane, checkPos)
      if dist > 0.0
        ret.score = -1.0
        return

    ret.score = dot(normalize(entPos - aimFrom), aimDir) * item_pickup_priority__angleWeight

    let width = lbb.width
    if collres == null || width.x + width.y + width.z < item_pickup_priority__useCollresMinWidth
      let itemItm = inverse(*transform)
      let from = itemItm * aimFrom
      let to = itemItm * aimTo
      if test_segment_box_intersection(from, to, lbb)
        ret.score += item_pickup_priority__lookAtWeight
    else
      let t = 10f
      if collres_rayhit(*collres, *transform, animchar.nodeTree, aimFrom, aimDir, t)
        ret.score += item_pickup_priority__lookAtWeight

    ret.useful = is_item_useful(eid, item_eid)
    if ret.useful
      ret.score += item_pickup_priority__usefulWeight

    let selectedItemBias = 0.05
    if was_selected
      ret.score += selectedItemBias

  return ret


def remove_entity_from_container(var container : EidList;
                                 eid : EntityId)
  let idx = container |> find_index(eid)
  if idx < 0
    return false
  container |> erase(idx)
  return true


def find_gunslot_to_change_weapon(eid : EntityId;
                                  item_eid : EntityId;
                                  var have_gun : bool&)
  var res = -1
  have_gun = false

  query(eid) <| $ [es] (human_weap__gunEids : EidList)
    query(item_eid) <| $ [es] (item__weapSlots : Array;
                               item__id : int)
      let weaponId = item__id
      for slot in item__weapSlots
        let slotName = slot ?? ""
        let slotIdx = HUWeaponSlots(slotName)
        let gunEid = human_weap__gunEids[int(slotIdx)]
        let totalAmmo = get_int(gunEid, "gun__totalAmmo") ?? 0 + get_int(gunEid, "gun__ammo") ?? 0
        if gunEid != INVALID_ENTITY_ID && has(gunEid, "disableItemDrop")
          continue
        let noAmmo = (totalAmmo <= 0 && slotIdx != HUWeaponSlots EWS_MELEE
                      && weaponId != get_int(human_weap__gunEids[int(slotIdx)], "item__id") ?? INVALID_ITEM_ID)
        if gunEid == INVALID_ENTITY_ID || noAmmo
          res = int(slotIdx)
          have_gun = (gunEid != INVALID_ENTITY_ID)
          if !have_gun
            break
  return res


def find_gunslot_to_change_weapon(eid : EntityId;
                                  item_eid : EntityId)
  var unused = false
  return find_gunslot_to_change_weapon(eid, item_eid, unused)


def install_item_on_weap_impl2(eid, item_eid : EntityId;
                               slot_id : int;
                               weap_slot : string) : bool
  var res = false
  query(item_eid) <| $ [es] (item__id : int = INVALID_ITEM_ID;
                             gunAttachable : Tag const?)
    if item__id == INVALID_ITEM_ID
      return
    if gunAttachable == null || slot_id < 0 || dead_or_downed(eid)
      return
    if !is_server()
      logerr("[Install item on weap impl2] This function mustn't be called from client.")
      return

    query(eid) <| $ [es] (human_weap__gunEids : EidList;
                          human_weap__gunMods : Array;
                          var itemContainer : EidList?)
      if !is_gunmod_allowed2(human_weap__gunEids[slot_id], item_eid)
        return

      if itemContainer != null
        if remove_entity_from_container(*itemContainer, item_eid)
          let gunMods = human_weap__gunMods[slot_id] |> get_ecs_EidList()
          var found = false
          for gunModEid in *gunMods
            query(gunModEid) <| $ [es] (gunAttachable__gunSlotName, item__template : string)
              if gunAttachable__gunSlotName == weap_slot
                *itemContainer |> push(createEntity(item__template))
                found = true
            if found
              break

          var nullCustomProps : Object? = null
          human_weap_attach_item_to_gun2(eid, slot_id, item_eid, weap_slot, true, nullCustomProps)
          destroyEntity(item_eid)
      res = true

  return res


def drop_weap_from_slot_impl2(eid : EntityId; slot_id : int; reset_weap, can_drop_from_dead : bool) : void
  if slot_id < 0 || (!can_drop_from_dead && dead_or_downed(eid))
    return

  query(eid) <| $ [es] (transform : float3x4;
                        human_inventory__dropsLoot : bool = true;
                        human_inventory__lootCleanupTime : float = -1.f;
                        allowOnlyPrimaryWeaponDrop, human_inventory__keepModsInInventory : Tag const?)
    if allowOnlyPrimaryWeaponDrop != null && HUWeaponSlots(slot_id) != HUWeaponSlots EWS_PRIMARY
      return
    let keepModsInInventory = (human_inventory__keepModsInInventory != null)
    if human_inventory__dropsLoot
      drop_gun2(eid, slot_id, transform) <| $(loot_desc)
        if keepModsInInventory && loot_desc.keepInInventory && can_pickup_item_by_volume(loot_desc.eid, eid)
          remove_item_from_weap_impl2(eid, slot_id, string(loot_desc.slotName), false)
        else
          drop_item(loot_desc, human_inventory__lootCleanupTime, true, INVALID_ENTITY_ID)

    if reset_weap
      human_weap_set_item_to_slot(eid, "", "", slot_id, null); // set nothing in there

    sendEvent(eid, [[EventOnLootDrop itemEid=INVALID_ENTITY_ID]])


def drop_weap_from_slot2(eid : EntityId; slot_name : string) : void
  if eid == INVALID_ENTITY_ID
    return

  let slotId = int(HUWeaponSlots(slot_name))

  if is_server()
    drop_weap_from_slot_impl2(eid, slotId, true, false)
  else
    sendEvent(eid, [[HumanDropWeapRequest slotId=slotId]])

    if slotId >= int(HUWeaponSlots EWS_NUM)
      logerr("[Drop weap from slot2] slotId <{slotId}> is out of range")
      return
    query(eid) <| $ [es] (human_weap__gunEids : EidList)
      let itemEid = human_weap__gunEids[slotId]
      if itemEid != INVALID_ENTITY_ID
        sendEvent(eid, [[EventOnLootDrop itemEid=itemEid]])


def install_item_on_weap2(eid, item_eid : EntityId; slot_name, weap_slot : string) : void
  if eid == INVALID_ENTITY_ID
    return
  let slotId = int(HUWeaponSlots(slot_name))
  if slotId < 0
    return

  if is_server()
    install_item_on_weap_impl2(eid, item_eid, slotId, weap_slot)
  else
    sendEvent(eid, [[HumanInstallItemOnWeapRequest itemEid=item_eid, slotId=slotId, slotName=weap_slot]])


def pickup_gun2(weap_templ_name, custom_skin : string;
                eid, item_eid : EntityId;
                slot_id : int) : void
  steal_gun_from_owner2(eid, item_eid)

  query(eid) <| $ [es] (human_weap__gunMods : Array;
                        human_weap__currentGunSlot : int = -1;
                        human_weap__autoequipMods : bool = false;
                        droppedGunKeepsMods : Tag const?)
    query(item_eid) <| $ [es] (var customProps : Object?)
      if customProps == null
        logerr("{item_eid}: {getEntityTemplateName(item_eid)} item without required customProps component")
      var slotId = slot_id
      if slotId < 0
        var haveGun = false
        slotId = find_gunslot_to_change_weapon(eid, item_eid, haveGun)
        if !haveGun
          if slotId >= 0
            human_weap_set_item_to_slot(eid, weap_templ_name, custom_skin, slotId, customProps)
            on_item_looted(eid, item_eid)
            destroyEntity(item_eid)
            if human_weap__autoequipMods
              sendEvent(eid, [[CmdAutoequipGunMod slotId=slotId]])
            return
          // otherwise find first best
          slotId = find_best_weap_slot_id2(eid, item_eid, slotId, human_weap__currentGunSlot)

      if slotId >= 0
        let keepScope = droppedGunKeepsMods != null

        // put scope back in inventory
        let scopeEid = !keepScope ? remove_item_from_weap_impl2(eid, slotId, "scope", /*to_ground*/ false) : INVALID_ENTITY_ID

        drop_weap_from_slot_impl2(eid, slotId, false, false)
        // create gun on ground instead of this first valid one
        human_weap_set_item_to_slot(eid, weap_templ_name, custom_skin, slotId, customProps)

        // try to install scope back on new weapon
        // NB: this works only while human_weap_set_item_to_slot create gun and remove_item_from_weap_impl2 synchronously
        if scopeEid != INVALID_ENTITY_ID
          var scopeFound = false
          let gunMods = human_weap__gunMods[slotId] |> get_ecs_EidList()
          if gunMods != null
            for gunModEid in *gunMods
              query(gunModEid) <| $ [es] (gunAttachable__gunSlotName : string)
                if gunAttachable__gunSlotName == "scope"
                  scopeFound = true
              if scopeFound
                break
            if !scopeFound
              install_item_on_weap_impl2(eid, scopeEid, slotId, "scope")
        elif human_weap__autoequipMods
          sendEvent(eid, [[CmdAutoequipGunMod slotId=slotId]])

        on_item_looted(eid, item_eid)
        destroyEntity(item_eid)


def drop_gun2(eid : EntityId;
              slot_id : int;
              tm : float3x4;
              var out_descs_ctr : int&;
              cb : block<(out_desc : ItemDesc) : void>) : bool
  var isOk = false
  query(eid) <| $ [es] (human_weap__gunEids : EidList;
                        human_weap__gunMods : Array;
                        human_inventory__dropLootOffset : float3)
    if !is_server()
      logerr("[Drop gun2] Attempted to call drop_gun2 from client.")
      return
    if slot_id >= int(HUWeaponSlots EWS_NUM)
      logerr("[Drop gun2] slot_id = <{slot_id}> is out of range.")
      return

    query(human_weap__gunEids[slot_id]) <| $ [es] (item__template : string;
                                                   item__id : int const?;
                                                   gun__customSkin : das_string const?)
      out_descs_ctr++
      using() <| $(var desc : ItemDesc)
        var templOverride = item__template
        if gun__customSkin != null
          templOverride += "+{*gun__customSkin}"
          desc |> setCustomSkin(string(*gun__customSkin))
        desc |> setTemplOverride(templOverride)
        desc |> setAddTemplate("item_in_world")
        desc.ownerEid = eid
        desc.id = item__id != null ? *item__id : int(uint(human_weap__gunEids[slot_id]))
        desc.tm = tm
        desc.tm[3] = tm * human_inventory__dropLootOffset

        human_gun_to_custom_props2(human_weap__gunEids[slot_id], desc.customProps)

        let gunMods = human_weap__gunMods[slot_id] |> get_ecs_EidList()
        for gunModEid in *gunMods
          query(gunModEid) <| $ [es] (gunAttachable__gunSlotName : string;
                                      item__template : das_string const?)
            if item__template != null && !empty(*item__template)
              desc |> pushModTemplate(getEntityTemplateName(gunModEid))
              human_gun_mod_to_custom_props2(eid, slot_id, gunAttachable__gunSlotName, desc.customProps)

        invoke(cb, desc)
      isOk = true
  return isOk


def drop_gun2(eid : EntityId;
              slot_id : int;
              tm : float3x4;
              cb : block<(out_desc : ItemDesc) : void>) : bool
  var ctr = 0
  let isOk = drop_gun2(eid, slot_id, tm, ctr) <| $(out_desc)
    invoke(cb, out_desc)
  return isOk


def is_unique_item_better(item_what : EntityId;
                          item_than : EntityId)
  return get_float(item_what, "item__pickupScore") ?? -1.0 > get_float(item_than, "item__pickupScore") ?? -1.0


def check_pickup_item_by_uniqueness(eid : EntityId;
                                    item_eid : EntityId;
                                    var out_worst_slot_name : string)
  if item_eid == INVALID_ENTITY_ID
    out_worst_slot_name = ""
    return true

  var worstSlotName = ""
  var res = true

  query(item_eid) <| $ [es] (item__equipToSlots : Array;
                             item__uniqueName aka pickup_item__uniqueName : das_string const?)
    if item__uniqueName == null
      res = false
      return

    let isSlots = query(eid) <| $ [es] (human_equipment__slots : Object)
      for eqToSlot in item__equipToSlots
        let eqToSlotName = eqToSlot ?? ""
        let slot = human_equipment__slots |> get_child(eqToSlotName)
        if slot != null
          let slotObject = get_ecs_object(*slot)
          if slotObject != null
            let equippedItem = get_Eid(*slotObject, "item") ?? INVALID_ENTITY_ID
            let equippedItemUniqueName = get_ecs_string(equippedItem, "item__uniqueName")
            if equippedItemUniqueName != null && (*equippedItemUniqueName) |> string() == eqToSlotName
              res = is_unique_item_better(item_eid, equippedItem)
              if res
                worstSlotName = eqToSlotName
              break
    if !isSlots
      res = false
      return

  out_worst_slot_name = worstSlotName
  return res


def check_pickup_item_by_uniqueness(eid : EntityId;
                                    item_eid : EntityId)
  var worstSlotName : string
  return check_pickup_item_by_uniqueness(eid, item_eid, worstSlotName)


def can_loot_container(eid : EntityId;
                       restriction_list : EidList const?)
  return restriction_list == null || *restriction_list |> find_index(eid) < 0


// This function is suffixed because we still have
// a binding duplicate of a similar function from C++ (see humaninv::can_pickup_items)
def can_pickup_items2(eid : EntityId)
  var canPickupItems = false
  query(eid) <| $ [es] (human__canPickupItems : bool = true)
    canPickupItems = human__canPickupItems
  return canPickupItems


// This function is suffixed because we still have
// a binding duplicate of a similar function from C++ (see humaninv::can_pickup_item)
def can_pickup_item2(item_eid : EntityId;
                     eid : EntityId)
  if !can_pickup_items2(eid)
    return false

  var worstSlotName : string
  if !check_pickup_item_by_uniqueness(eid, item_eid, worstSlotName)
    return false

  var pickupToSlot = false

  if has(item_eid, "item__weapTemplate")
    var slotHaveGun = false
    let slotIdx = find_gunslot_to_change_weapon(eid, item_eid, slotHaveGun)
    pickupToSlot = slotIdx >= 0 && !slotHaveGun

  if !pickupToSlot && !can_pickup_item_by_volume(item_eid, eid)
    return false

  if !can_loot_container(eid, getRW_ecs_EidList(item_eid, "container__restrictLootingToEids"))
    return false

  return true


def pickup_item_to_weap_slot_impl2(eid, item_eid : EntityId; slot_id : int) : void
  if dead_or_downed(eid)
    return
  if !try_pickup_item(eid, item_eid)
    return
  if slot_id >= int(HUWeaponSlots EWS_NUM) || (slot_id < 0 && slot_id != -1)
    logerr("[Pickup item to weap slot impl] bad slot_id={slot_id} (eid={eid}<{getEntityTemplateName(eid)}>, item_eid={item_eid}<{getEntityTemplateName(item_eid)}>)");
    return

  query(item_eid) <| $ [es] (item__weapTemplate : string;
                             gun__customSkin : das_string const?)
    if gun__customSkin != null
      pickup_gun2(item__weapTemplate, string(*gun__customSkin), eid, item_eid, slot_id)
    else
      pickup_gun2(item__weapTemplate, "", eid, item_eid, slot_id)


def pickup_item_to_weap_slot2(eid, item_eid : EntityId; slot_name : string) : void
  if eid == INVALID_ENTITY_ID || !can_pickup_items2(eid)
    return
  let slotId = int(HUWeaponSlots(slot_name))
  if slotId < 0
    return

  if is_server()
    pickup_item_to_weap_slot_impl2(eid, item_eid, slotId)
  else
    sendEvent(eid, [[HumanPickupWeapRequest itemEid=item_eid, slotId=slotId]])

    if can_pickup_item2(item_eid, eid)
      sendEvent(eid, [[EventOnLootPickup itemEid=item_eid]])


def pickup_and_install_item_on_weap_impl2(eid, item_eid : EntityId; slot_id : int; weap_slot : string) : bool
  if !is_server()
    logerr("[Pickup and install item on weap impl2] Attempt to call pickup_and_install_item_on_weap_impl2 from client.")
    return false

  if !has(item_eid, "gunAttachable") || slot_id < 0 || dead_or_downed(eid)
    return false

  var res = false
  query(eid) <| $ [es] (human_weap__gunEids : EidList;
                        human_weap__gunMods : Array;
                        var itemContainer : EidList)
    if !is_gunmod_allowed2(human_weap__gunEids[slot_id], item_eid)
      return

    let gunMods = human_weap__gunMods[slot_id] |> get_ecs_EidList()
    if gunMods == null
      return

    for gunModEid in *gunMods
      var oldModRemoved = false
      query(gunModEid) <| $ [es] (gunAttachable__gunSlotName, item__template : string)
        if gunAttachable__gunSlotName == weap_slot
          // put existing modification to backpack
          createEntity(item__template) <| $(var init)
            set(init, "item__ownerEid", eid)
          oldModRemoved = true
      if oldModRemoved
        break

    var nullCustomProps : Object? = null
    human_weap_attach_item_to_gun2(eid, slot_id, item_eid, weap_slot, true, nullCustomProps)

    remove_entity_from_container(itemContainer, item_eid)

    on_item_looted(eid, item_eid)
    destroyEntity(item_eid)
    res = true

  return res


def pickup_and_install_item_on_weap2(eid, item_eid : EntityId; slot_name, weap_slot : string) : void
  if eid == INVALID_ENTITY_ID
    return
  let slotId = int(HUWeaponSlots(slot_name))
  if slotId < 0
    return

  if is_server()
    pickup_and_install_item_on_weap_impl2(eid, item_eid, slotId, weap_slot)
  else
    sendEvent(eid, [[HumanPickupAndInstallItemOnWeapRequest itemEid=item_eid, slotId=slotId, slotName=weap_slot]])

    if can_pickup_item(item_eid, eid)
      sendEvent(eid, [[EventOnLootPickup itemEid=item_eid]])
