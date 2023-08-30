module inventory_common shared
require app
require ecs
require ecs.common
require inventory
require math.base
require DagorMath
require DagorRandom
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
require game.es.inventory_drop_common
require common_shooter.es.human_weap_common
require common_shooter.events_common_shooter
require enlisted.events_enlisted
require game.es.events
require strings
require DaWeaponProps
require WeapHelpers


enum Usefulness
  NO = 0
  YES = 1
  UNKNOWN = 2


def is_useful_equip(item_eid : EntityId;
                    to_whom : EntityId)
  var res = Usefulness UNKNOWN
  query(to_whom) <| $ [es] (human_equipment__slots : Object const?)
    query(item_eid) <| $ [es] (item__equipToSlots : Array;
                               item__uniqueName aka new_item__uniqueName : string;
                               item__pickupScore aka new_item__pickupScore : float = -1.0)
      if length(item__equipToSlots) > 0
        res = Usefulness NO
        if item__pickupScore == 0.0
          return
        if human_equipment__slots == null
          return
        if !can_pickup_item(item_eid, to_whom)
          return
        for slot in item__equipToSlots
          let slotId = slot as string
          if slotId == null
            return
          let itf = (*human_equipment__slots)[*slotId |> string()]
          if itf == null
            continue
          let item = *itf as Object
          let equippedItem = (*item)["item"] ?? INVALID_ENTITY_ID
          if equippedItem == INVALID_ENTITY_ID
            res = Usefulness YES // Empty slot!
            return
          query(equippedItem) <| $ [es] (item__uniqueName aka equipped_item__uniqueName : string;
                                         item__pickupScore aka equipped_item__pickupScore : float = -1.0)
            if new_item__uniqueName == equipped_item__uniqueName
              return
            if new_item__pickupScore > equipped_item__pickupScore
              res = Usefulness YES
          if res == Usefulness YES
            return
  return res


def is_weapon_useful(item_eid : EntityId;
                     to_whom : EntityId;
                     weap_templ_name : string;
                     weap_slots : Array const?;
                     gun_eids : EidList const?;
                     gun_mods : Array const?)
  if weap_templ_name != ""
    // Check if we have empty slot for it
    if find_gunslot_to_change_weapon(to_whom, item_eid) >= 0
      return Usefulness YES

    if gun_eids != null && weap_slots != null
      var useful = false
      query(item_eid) <| $ [es] (item__weapType aka new_item__weapType : string;
                                 item__pickupScore aka new_item__pickupScore : float)
        for slot in *weap_slots
          let slotId = slot as string
          if slotId == null
            return
          let slotIdx = HUWeaponSlots(*slotId |> string())
          if int(slotIdx) < 0
            logerr("Incorrect slotId = {slotId}!")
            return

          query((*gun_eids)[int(slotIdx)]) <| $ [es] (item__weapType aka equipped_item__weapType : string;
                                                      item__pickupScore aka equipped_item__pickupScore : float)
            useful = (new_item__weapType == equipped_item__weapType &&
                     new_item__pickupScore > equipped_item__pickupScore)
          if useful
            return
      if useful
        return Usefulness YES
  if has(item_eid, "gunAttachable")
    if gun_eids == null || gun_mods == null
      return Usefulness NO

    let itemGunSlotName = get_ecs_string(item_eid, "gunAttachable__gunSlotName")
    if itemGunSlotName != null
      let usefulScopesLimit = get_int(to_whom, "human_inventory__usefulScopesLimit") ?? 2 // for primary and secondary weapon
      let usefulScopesOverflow = get_int(to_whom, "human_inventory__usefulScopesOverflow") ?? 0
      let itemCont = get_ecs_EidList(to_whom, "itemContainer")
      var inventoryScopes = 0
      var wishScopes = 0
      var weaponScopes = 0
      if itemCont != null
        for item in *itemCont
          let gunSlotName = get_ecs_string(item, "gunAttachable__gunSlotName")
          if gunSlotName != null && (*gunSlotName == *itemGunSlotName)
            inventoryScopes++
      for i in range(int(HUWeaponSlots EWS_NUM))
        let gunModsList = get_ecs_EidList((*gun_mods)[i])
        if gunModsList == null
          continue
        var haveMod = false
        for gunModEid in *gunModsList
          let gunSlotName = get_ecs_string(gunModEid, "gunAttachable__gunSlotName")
          if gunSlotName != null && (*gunSlotName == *itemGunSlotName)
            haveMod = true
            ++weaponScopes
            break
        if !haveMod && is_gunmod_allowed2((*gun_eids)[i], item_eid)
          wishScopes++
      if inventoryScopes < usefulScopesOverflow + wishScopes && inventoryScopes + weaponScopes < usefulScopesLimit
        return Usefulness YES

    return Usefulness NO
  return Usefulness UNKNOWN


def is_ammo_useful(item_eid : EntityId;
                   gun_eids : EidList const?)
  var res = Usefulness UNKNOWN
  query(item_eid) <| $ [es] (shell_props : ShellPropIds const?;
                             ammo_holder__id : int const const?)
    if ammo_holder__id == null && shell_props == null
      return
    if gun_eids == null
      res = Usefulness NO
      return

    // Try to find appropriate gun for it
    for i in range(int(HUWeaponSlots EWS_NUM))
      let ammoPropIds = get_ecs_IntList((*gun_eids)[i], "gun__ammoHolderIds")
      if ammoPropIds == null
        continue
      if ammo_holder__id != null && is_ammo_for_gun(*ammo_holder__id, *ammoPropIds)
        res = Usefulness YES
        break

      if shell_props != null
        query((*gun_eids)[i]) <| $ [es] (gun__shell_prop_ids : GunShellPropIds)
          if is_shell_for_gun(*shell_props, gun__shell_prop_ids)
            res = Usefulness YES
      if res == Usefulness YES
        break
  return res


def has_same_weapon(to_whom : EntityId;
                    weap_id : int;
                    weap_slots : Array const?)
  if weap_id == INVALID_ITEM_ID || weap_slots == null || empty(*weap_slots)
    return false
  var res = false
  query(to_whom) <| $ [es] (human_weap__gunEids : EidList)
    for slot in *weap_slots
      let slotId = slot as string
      if slotId == null
        return
      let slotIdx = int(HUWeaponSlots(*slotId |> string()))
      if slotIdx >= 0 && weap_id == get_int(human_weap__gunEids[slotIdx], "item__id") ?? INVALID_ITEM_ID
        res = true
        return

  return res


def is_item_useful2(to_whom : EntityId;
                    item_eid : EntityId)
  if !doesEntityExist(to_whom)
    return false

  var itemId = INVALID_ITEM_ID
  var weapTemplName = ""
  var weapSlots : Array const? = null
  var isContainer = false
  var alwaysUseful = false
  var disabledPickup = false
  var hasUseTime = false
  var jetpackFuel = 0.0
  var isEquippable = false
  query(item_eid) <| $ [es] (item__weapTemplate : das_string const?;
                             item__weapSlots : Array const?;
                             container_contents_chances : Object const?;
                             containerContents : StringList const?;
                             containerContentsPreset : Array const?;
                             containerContentsWeightedPreset : Object const?;
                             container__restrictLootingToEids : EidList const?;
                             item__useTime : float const?;
                             item__useTimeToTarget : float const?;
                             item__alwaysUseful : Tag const?;
                             item__equipToSlots : Array const?;
                             item__disablePickup : bool = false;
                             item__id : int = INVALID_ITEM_ID;
                             jetpack_fuel__amount : float = 0.0)
    itemId = item__id
    if item__weapTemplate != null
      weapTemplName := *item__weapTemplate |> string()
    weapSlots = item__weapSlots
    isContainer = (container_contents_chances != null || containerContentsPreset != null ||
                  containerContentsWeightedPreset != null || containerContents != null)
    isContainer = isContainer && can_loot_container(to_whom, container__restrictLootingToEids)
    alwaysUseful = item__alwaysUseful != null
    hasUseTime = item__useTime != null || item__useTimeToTarget != null
    jetpackFuel = jetpack_fuel__amount
    isEquippable = item__equipToSlots != null
    disabledPickup = item__disablePickup

  if disabledPickup
    return false

  if itemId == INVALID_ITEM_ID && !isEquippable
    return false

  if has_same_weapon(to_whom, itemId, weapSlots)
    return false

  if alwaysUseful
    return true

  var gunEids : EidList const? = null
  var gunMods : Array const? = null
  var jetpackEid = INVALID_ENTITY_ID
  query(to_whom) <| $ [es] (human_weap__gunEids : EidList const?;
                            human_weap__gunMods : Array const?;
                            human_jetpack__eid : EntityId const?)
    gunEids = human_weap__gunEids
    gunMods = human_weap__gunMods
    if human_jetpack__eid != null
      jetpackEid = *human_jetpack__eid

  if jetpackFuel > 0.0
    return jetpackEid != INVALID_ENTITY_ID && !has(jetpackEid, "ghostJetpack")

  if isContainer
    return true

  let isUsefulEquip = is_useful_equip(item_eid, to_whom)
  if isUsefulEquip != Usefulness UNKNOWN
    return isUsefulEquip == Usefulness YES

  if hasUseTime
    return true

  let isWeaponUseful = is_weapon_useful(item_eid, to_whom, weapTemplName, weapSlots, gunEids, gunMods)
  if isWeaponUseful != Usefulness UNKNOWN
    return isWeaponUseful == Usefulness YES

  let isAmmoUseful = is_ammo_useful(item_eid, gunEids)
  if isAmmoUseful != Usefulness UNKNOWN
    return isAmmoUseful == Usefulness YES

  return false


def is_fast_pickup_item2(to_whom, item_eid : EntityId)
  return is_item_useful2(to_whom, item_eid) || has(item_eid, "fastPickup")


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

    ret.useful = is_item_useful2(eid, item_eid)
    if ret.useful
      ret.score += item_pickup_priority__usefulWeight

    let selectedItemBias = 0.05
    if was_selected
      ret.score += selectedItemBias

  return ret


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
                        human_inventory__lootCleanupTime : float = -1.f)
    if HUWeaponSlots(slot_id) != HUWeaponSlots EWS_PRIMARY && HUWeaponSlots(slot_id) != HUWeaponSlots EWS_SECONDARY
      return

    if human_inventory__dropsLoot
      drop_gun2(eid, slot_id, transform) <| $(loot_desc)
        drop_item2(loot_desc, human_inventory__lootCleanupTime, true, INVALID_ENTITY_ID)

    if reset_weap
      var nullCustomProps : Object? = null
      human_weap_set_item_to_slot(eid, "", "", slot_id, nullCustomProps) // set nothing in there

    sendEvent(eid, [[EventOnLootDrop itemEid=INVALID_ENTITY_ID]])


def drop_weap_from_slot2(eid : EntityId; slot_name : string) : void
  if eid == INVALID_ENTITY_ID
    return

  let slotId = int(HUWeaponSlots(slot_name))

  if is_server()
    drop_weap_from_slot_impl2(eid, slotId, true, false)
  else
    send_net_event(eid, [[HumanDropWeapRequest slotId=slotId]])

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
    send_net_event(eid, [[HumanInstallItemOnWeapRequest itemEid=item_eid, slotId=slotId, slotName=weap_slot]])


def on_weap_slot_item_looted(eid, item_eid : EntityId; slot_id : int)
  query() <| $ [es] (eid, slot_attach__attachedTo : EntityId)
    // remove whatever is attached to this gun (if it's a gun), those are just decorations at this point,
    // actual mods that are picked up with the gun are part of item.template.
    if slot_attach__attachedTo == item_eid
      destroyEntity(eid)
  query(item_eid) <| $ [es] (var item__id : int&)
    item__id = INVALID_ITEM_ID
  notify_player_looted(eid, item_eid)
  sendEventImmediate(eid, [[EventOnWeapSlotItemPickup itemEid=item_eid, slotId=slot_id]])


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
            on_weap_slot_item_looted(eid, item_eid, slotId)
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

        on_weap_slot_item_looted(eid, item_eid, slotId)
        destroyEntity(item_eid)


def pickup_gun(eid : EntityId;
               item_eid : EntityId)
  return query(item_eid) <| $ [es] (item__weapTemplate : string;
                                    gun__customSkin : das_string const?)
    if gun__customSkin != null
      pickup_gun2(item__weapTemplate, *gun__customSkin |> string(), eid, item_eid, -1)
    else
      pickup_gun2(item__weapTemplate, "", eid, item_eid, -1)


def insert_item2(eid, item_eid : EntityId) : void
  if pickup_gun(eid, item_eid)
    return

  query(eid) <| $ [es] (var itemContainer : EidList;
                        var human_inventory__currentVolume : float?)
    itemContainer |> push(item_eid)
    if human_inventory__currentVolume != null
      query(item_eid) <| $ [es] (item__volume : float = 0.f)
        *human_inventory__currentVolume += item__volume // TODO: maybe remove? we should track these changes already

  on_item_entity_looted(eid, item_eid)


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
        if gun__customSkin != null && !empty(*gun__customSkin)
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
    send_net_event(eid, [[HumanPickupWeapRequest itemEid=item_eid, slotId=slotId]])

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

    on_weap_slot_item_looted(eid, item_eid, slot_id)
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
    send_net_event(eid, [[HumanPickupAndInstallItemOnWeapRequest itemEid=item_eid, slotId=slotId, slotName=weap_slot]])

    if can_pickup_item(item_eid, eid)
      sendEvent(eid, [[EventOnLootPickup itemEid=item_eid]])


def notify_player_looted(eid : EntityId;
                         item_eid : EntityId)
  query(item_eid) <| $ [es] (item__lootType : string;
                             spawnedInRegion : string = "";
                             var item__alreadyLooted : bool&)
    if item__lootType != "" && !item__alreadyLooted
      query(eid) <| $ [es] (possessedByPlr : EntityId)
        sendEvent(possessedByPlr, [[EventOnPlayerLooted itemType=item__lootType, region=spawnedInRegion]])
        item__alreadyLooted = true
  sendEventImmediate(eid, [[EventOnLootPickup itemEid=item_eid]])


def equip_item_entity_to_slot(eid : EntityId;
                              item_eid : EntityId;
                              slot : string;
                              allow_reorder_slots : bool)
  if !has(item_eid, "item__isPickable")
    // It should be equipped on our entity then
    query(eid) <| $ [es] (human_equipment__slots : Object)
      for eqSlot in human_equipment__slots
        let value = eqSlot.value as Object
        if ((*value).item ?? INVALID_ENTITY_ID) == item_eid
          sendEvent(eid, [[CmdSwapEquipSlots item=item_eid, fromSlotName=eqSlot.key, toSlotName=slot]])
          return
    return
  elif !check_pickup_item_by_uniqueness(eid, item_eid)
    return
  notify_player_looted(eid, item_eid)
  sendEventImmediate(eid, [[CmdEquipItemDirect itemEid=item_eid, slot=slot, allowReorderSlots=allow_reorder_slots, dropPrevItem=true]])


def equip_item_entity(eid : EntityId;
                      item_eid : EntityId;
                      equip_slots : Array)
  var res = false
  query(eid) <| $ [es] (human_equipment__slots : Object)
    if length(human_equipment__slots) == 0
      return

    var slotName : string
    let uniqRes = check_pickup_item_by_uniqueness(eid, item_eid, slotName)
    if has(item_eid, "item__isPickable") && !uniqRes
      return
    if slotName == ""
      // find unequiped slot or default to first slot
      slotName = equip_slots[0] ?? ""
      for slot in equip_slots
        let name = slot ?? ""
        let item = human_equipment__slots |> get_child(name)
        if item != null
          let slotItemEid = (*item as Object)?.item ?? INVALID_ENTITY_ID
          if slotItemEid != INVALID_ENTITY_ID
            continue
          slotName = name
        else
          continue
        break
    equip_item_entity_to_slot(eid, item_eid, slotName, true)
    res = true
  return res


def remove_item_from_entity_container(item_eid : EntityId)
  query(item_eid) <| $ [es] (item__parentContainerEid : EntityId)
    query(item__parentContainerEid) <| $ [es] (var entitiesContainerContent : EidList)
      let idx = entitiesContainerContent |> find_index(item_eid)
      if idx >= 0
        entitiesContainerContent |> erase(idx)
    let newTemplateName = remove_sub_template_name(item_eid, "item_in_container")
    remote_recreate_entity_from(item_eid, newTemplateName)

def on_item_entity_looted(eid : EntityId;
                          item_eid : EntityId)
  notify_player_looted(eid, item_eid)

  query(item_eid) <| $ [es] (item__recreateOnGround : das_string const?;
                             item__recreateInInventory : das_string const?;
                             item__removeTemplatesInInventory : StringList const?;
                             var item__isOnGround : bool&;
                             var item__ownerEid : EntityId&;
                             var item__lastOwner : EntityId&)
    remove_item_from_entity_container(item_eid)
    let templateToRemove = item__recreateOnGround != null ? *item__recreateOnGround |> string() : ""
    let templateToAdd = item__recreateInInventory != null ? *item__recreateInInventory |> string() : ""
    var newTemplateName = getEntityTemplateName(item_eid)
    if templateToRemove != ""
      newTemplateName = remove_sub_template_name(newTemplateName, templateToRemove)
    if templateToAdd != ""
      newTemplateName = add_sub_template_name(newTemplateName, templateToAdd)
    if item__removeTemplatesInInventory != null
      for templ in *item__removeTemplatesInInventory
        newTemplateName = remove_sub_template_name(newTemplateName, templ |> string())
    item__isOnGround = false
    item__ownerEid = eid
    item__lastOwner = eid
    remote_recreate_entity_from(item_eid, newTemplateName)
  return true

def drop_item_from_container(owner : EntityId;
                             item : string;
                             transform : float3x4;
                             collres : CollisionResource;
                             gen_item_radius : float;
                             gen_item_spot_rise : float;
                             drop_item_radius : float) : void
  using() <| $(var desc : ItemDesc)
    desc.ownerEid = owner
    desc |> setTemplOverride(item)
    desc.tm = transform
    var to = float3()
    sincos(gfrnd() * TWOPI, to.z, to.x)
    var norm = float3()
    let boxCenter = (collres.vFullBBox.bmin + collres.vFullBBox.bmax) * 0.5
    let startPos = desc.tm * boxCenter.xyz
    var from = startPos + to * drop_item_radius
    var t = gen_item_spot_rise
    traceray_normalized(from, float3(0.0, 1.0, 0.0), t, norm, ETF_ALL)
    from.y += t
    var dirToFrom = from - startPos
    var dirToFromLen = length(dirToFrom)
    var predictCollisionLen = gen_item_radius //
    dirToFrom *= safeinv(dirToFromLen)
    let hasCollision = traceray_normalized(startPos, dirToFrom, dirToFromLen, norm, ETF_ALL)
    var predictNorm = norm
    if hasCollision || traceray_normalized(from, to, predictCollisionLen, predictNorm, ETF_ALL)
      if !hasCollision
        norm = predictNorm
      let wallOffset = 0.01
      from = startPos + dirToFrom * dirToFromLen + norm * wallOffset
      var offset = norm * gen_item_radius
      offset.y = 0.0
      var offsetLen = length(offset)
      if abs(offsetLen) >= FLT_EPSILON
        offset *= safeinv(offsetLen)
        traceray_normalized(from, offset, offsetLen, norm)
        from += offset * offsetLen
    desc.tm[3] = from
    drop_item2(desc, -1.0, false, INVALID_ENTITY_ID)


def drop_item_from_list(var containerContents : StringList;
                        item_eid : EntityId;
                        transform : float3x4;
                        collres : CollisionResource;
                        genItemRadius : float;
                        genItemSpotRise : float;
                        dropItemRadius)
  let item = containerContents[0] |> string()
  drop_item_from_container(item_eid, item, transform, collres, genItemRadius, genItemSpotRise, dropItemRadius)
  containerContents |> erase(0)

// This function is suffixed because we still have
// a binding duplicate of a similar function from C++ (see humaninv::can_pickup_item_by_volume)
def can_pickup_item_by_volume2(item_eid : EntityId;
                               eid : EntityId;
                               volume : float)
  if eid == INVALID_ENTITY_ID
    return false

  let isOnGround = get_bool(item_eid, "item__isOnGround") ?? true
  if !isOnGround
    return false

  if volume == 0.0
    return true

  let totalVolume = get_float(eid, "human_inventory__currentVolume") ?? 0.0
  return totalVolume + volume <= get_float(eid, "human_inventory__capacity") ?? 0.0


// This function is suffixed because we still have
// a binding duplicate of a similar function from C++ (see humaninv::can_pickup_item_by_volume)
def can_pickup_item_by_volume2(item_eid : EntityId;
                               eid : EntityId)
  let volume = get_float(item_eid, "item__volume") ?? 0.0
  return can_pickup_item_by_volume2(item_eid, eid, volume)


def pickup_one_item_impl(eid, item_eid : EntityId) : void
  var isPickedUp = false
  let lastOwner = get_Eid(item_eid, "item__lastOwner") ?? INVALID_ENTITY_ID
  query(lastOwner) <| $ [es(REQUIRE=lootable)] (isAlive : bool = true;
                                                var itemContainer : EidList)
    if isAlive
      return
    if remove_entity_from_container(itemContainer, item_eid)
      isPickedUp = true
      insert_item2(eid, item_eid)

  if isPickedUp
    return

  if (!has(lastOwner, "lootable") &&
      (!has(item_eid, "item__isPickable") || !(get_bool(item_eid, "item__isOnGround") ?? false)))
    return
  if !can_pickup_item_by_volume2(item_eid, eid)
    return

  insert_item2(eid, item_eid)

def pickup_item_impl2(eid, item_eid : EntityId; useful_only : bool) : void
  if item_eid == INVALID_ENTITY_ID || dead_or_downed(eid) || !can_pickup_items2(eid)
    return
  if useful_only && !is_item_useful2(eid, item_eid)
    return
  if !try_pickup_item(eid, item_eid)
    return
  if has(item_eid, "item__specialPickup")
    sendEvent(item_eid, [[CmdPickupSpecialItem pickuperEid=eid, usefulOnly=useful_only]])
    return

  var equipToSlots = false
  query(item_eid) <| $ [es] (item__equipToSlots : Array)
    if length(item__equipToSlots) != 0
      equipToSlots = true
      if equip_item_entity(eid, item_eid, item__equipToSlots)
        remove_item_from_entity_container(item_eid)
  if equipToSlots
    return

  let res = query(item_eid) <| $ [es] (item__id : int)
    if item__id != INVALID_ITEM_ID
      pickup_one_item_impl(eid, item_eid)
  if !res
    logwarn("Unable to pickup item {item_eid}, exist={doesEntityExist(item_eid)}")


def pickup_item_ex2(eid, item_eid : EntityId; useful_only : bool) : void
  if eid == INVALID_ENTITY_ID
    return
  if !try_pickup_item(eid, item_eid)
    return
  if is_server()
    pickup_item_impl2(eid, item_eid, useful_only)
  else
    send_net_event(eid, [[HumanPickupItemRequest itemEid=item_eid, usefulOnly=useful_only]])

    if can_pickup_item(item_eid, eid)
      sendEvent(eid, [[EventOnLootPickup itemEid=item_eid]])


def pickup_item2(eid, item_eid : EntityId) : void
  pickup_item_ex2(eid, item_eid, false)


def drop_item2(item : SimpleItemDesc;
               loot_cleanup_time : float = -1.0f)
  using() <| $(var comps : ComponentsInitializer)
    if item.gunSlot < 0
      drop_item_without_props(item, comps, loot_cleanup_time)
    else
      drop_gun2(item.ownerEid, item.gunSlot, item.tm) <| $(itemDesc)
        drop_item_with_props(itemDesc, comps, loot_cleanup_time)
      var nullCustomProps : Object? = null
      human_weap_set_item_to_slot(item.ownerEid, "", "", item.gunSlot, nullCustomProps) // set nothing in there


def is_in_group(idx, begin_idx : int; loot : array<SimpleItemDesc>; group : bool)
  return group && idx - begin_idx > 0 && (loot[idx - 1].id == loot[idx].id)


def arrange_loot(ground : float3;
                 up : float3;
                 base_radius : float;
                 min_max_radius : float2;
                 rate : float;
                 group : bool;
                 begin_idx, end_idx : int;
                 var loot : array<SimpleItemDesc>) : void
  var from = ground
  let dir = float3(0.f, 1.f, 0.f)
  var t = 1.5
  var norm = float3(0.f)
  if traceray_normalized(from, dir, t, norm)
    t -= 0.01
  from += dir * t

  var numPoints = 0
  for i in range(0, end_idx - begin_idx)
    if !is_in_group(i, begin_idx, loot, group)
      ++numPoints

  var numCircles = 0
  var capacity = 0.f
  var pointId = numPoints
  while pointId > 0
    let len = TWOPI * (base_radius + float(numCircles) * rate)
    capacity += len
    pointId -= max(1, int(len / rate))
    ++numCircles

  let maxRadius = base_radius + float(numCircles) * rate
  var scale = 1.f
  if maxRadius < min_max_radius.x
    scale = min_max_radius.x / maxRadius
  elif maxRadius > min_max_radius.y
    scale = min_max_radius.y / maxRadius

  var goodTm = IDENT_TM
  goodTm[1] = up
  goodTm[3] = ground

  pointId = 0
  var lootId = begin_idx
  for circleId in range(0, numCircles)
    let radius = base_radius + float(circleId) * rate
    let length = TWOPI * radius
    var count = max(1, int(cvt(length, 0.f, capacity, 0.f, float(numPoints))))
    if circleId + 1 >= numCircles
      count = numPoints - pointId

    for i in range(pointId, pointId + count)
      var pos = float3(0.f)
      sincos((float(i) + gfrnd()) * TWOPI / float(count), pos.z, pos.x)
      pos = ground + pos * (radius + gfrnd() * rate) * scale

      if try_put_item2(from, pos, loot[lootId].tm)
        goodTm = loot[lootId].tm
      else
        loot[lootId].tm = goodTm

      ++lootId
      let secondInGroup = lootId
      while lootId < end_idx
        if !is_in_group(lootId, begin_idx, loot, group)
          break
        ++lootId

      if lootId - secondInGroup > 0
        let minMaxRadius = float2(rate * scale * 0.75, rate * scale * 0.75)
        arrange_loot(goodTm[3], goodTm[1], rate, minMaxRadius, rate, false,
                     secondInGroup, lootId, loot) // use indexes instead of calling subarray of loot to avoid copying
    pointId += count

  if pointId != numPoints
    logerr("[Arrange Loot] pointId != numPoints : pointId=<{pointId}>, numPoints=<{numPoints}>")
  if lootId != end_idx
    logerr("[Arrange Loot] lootId != end_idx : lootId=<{lootId}>, end_idx=<{end_idx}>")


def arrange_loot(tm : float3x4;
                 radius : float;
                 group_circle_radius : float;
                 var loot : array<SimpleItemDesc>) : void
  if empty(loot)
    return
  print("arrange_loot: loot.size {length(loot)}")
  sort(loot) <| $(lhs, rhs : SimpleItemDesc)
    return lhs.id > rhs.id

  let from = tm[3] + float3(0.f, 1.f, 0.f)
  let dir = float3(0.f, -1.f, 0.f)
  var norm = float3(0.f)
  var t = 100.0f
  if !traceray_normalized(from, dir, t, norm)
    return

  let minMaxRadius = float2(0.25, 1.25)
  let ground = from + dir * (t - 0.01)
  arrange_loot(ground, norm, radius, minMaxRadius, group_circle_radius, true, 0, length(loot), loot)


def try_drop_guns(eid : EntityId;
                  transform : float3x4;
                  on_death : bool;
                  var lootDesc : array<SimpleItemDesc>) : int
  var dropCnt = 0
  query(eid) <| $ [es] (human_weap__gunEids : EidList;
                        human_weap__gunMods : Array const?)
    for i in range(0, int(HUWeaponSlots EWS_NUM))
      if !on_death && i == int(HUWeaponSlots EWS_MELEE)
        continue
      query(human_weap__gunEids[i]) <| $ [es] (item__template : string;
                                               item__id : int)
        if !empty(item__template)
          lootDesc |> push([[ SimpleItemDesc
                              id=item__id,
                              eid=human_weap__gunEids[i],
                              ownerEid = eid,
                              gunSlot = i
          ]])
          ++dropCnt
      if human_weap__gunMods != null
        let gunModsCopy := (*human_weap__gunMods)[i] |> get_ecs_EidList() // we'll mutate gun mods, need a copy.
        if gunModsCopy != null
          for gunModEid in *gunModsCopy
            query(gunModEid) <| $ [es] (item__template : string;
                                        gunAttachable__gunSlotName : string = "")
              if gunAttachable__gunSlotName == ""
                return
              ++dropCnt
              lootDesc |> push([[ SimpleItemDesc
                                  templOverride=item__template,
                                  ownerEid=eid,
                                  addTemplate="item_in_world",
                                  tm=transform,
                                  gunSlot=-1
              ]])
              var nullCustomProps : Object? = null
              human_weap_attach_item_to_gun2(eid, i, "", gunAttachable__gunSlotName, false, nullCustomProps)
  return dropCnt


def drop_loot2(eid : EntityId; on_death : bool) : void
  query(eid) <| $ [es] (transform : float3x4;
                        lootable : Tag const?;
                        human_inventory__lootCleanupTime : float = -1.f;
                        human_inventory__dropsLoot : bool = true;
                        human_inventory__dropsLootRad : float = 0.6f;
                        human_inventory__dropsLootGroupRad : float = 0.4f)
    if !human_inventory__dropsLoot

      if lootable != null
        return

      query(eid) <| $ [es] (var itemContainer : EidList&)
        for itemEid in itemContainer
          destroyEntity(itemEid)
        clear(itemContainer)
      return

    let lootCleanupTime = human_inventory__lootCleanupTime
    var dropCnt = 0
    var lootDesc : array<SimpleItemDesc>
    dropCnt += try_drop_guns(eid, transform, on_death, lootDesc)

    query(eid) <| $ [es] (var itemContainer : EidList;
                          var human_inventory__currentVolume : float&;
                          var human_inventory__currentWeight : float&)
      let contLen = length(itemContainer)
      for i in range(0, contLen)
        let idx = contLen - i - 1
        assume itemEid = itemContainer[idx]
        if !on_death && has(itemEid, "item__dropOnlyOnDeath")
          continue
        ++dropCnt
        var itemId = int(uint(itemEid))
        query(itemEid) <| $ [es] (item__id : int)
          itemId = item__id
        lootDesc |> push([[ SimpleItemDesc
                            eid=itemEid,
                            ownerEid=eid,
                            id=itemId,
                            tm=transform,
                            gunSlot=-1
        ]])
        itemContainer |> erase(idx)

      // force recalc
      human_inventory__currentVolume = 0.f
      human_inventory__currentWeight = 0.f

    query(eid) <| $ [es] (var human_equipment__slots : Object)
      for slotItem in human_equipment__slots
        let slot = slotItem.value as Object
        if slot != null
          let itemEid = (*slot).item ?? INVALID_ENTITY_ID
          if itemEid == INVALID_ENTITY_ID
            continue
          if !on_death && has(itemEid, "item__unequipOnlyOnDeath")
            continue
          var unequippable = true
          query(itemEid) <| $ [es] (item__unequippable : bool)
            unequippable = item__unequippable
          if !unequippable
            continue
          if !has(itemEid, "item__nonDroppable")
            ++dropCnt
            var itemId = int(uint(itemEid))
            query(itemEid) <| $ [es] (item__id : int)
              itemId = item__id
            lootDesc |> push([[ SimpleItemDesc
                                eid=itemEid,
                                ownerEid=eid,
                                id=itemId,
                                tm=transform,
                                gunSlot=-1
            ]])
            sendEventImmediate(eid, [[CmdEquipItemDirect itemEid=INVALID_ENTITY_ID, slot=slotItem.key, allowReorderSlots=false, dropPrevItem=false]])

    if on_death
      query(eid) <| $ [es] (deathDrop : Array)
        for loot in deathDrop
          let item = loot |> get_ecs_object()
          if item != null
            if ((*item).chance ?? 1.f) <= gfrnd()
              continue
            ++dropCnt
            lootDesc |> push([[ SimpleItemDesc
                                ownerEid=eid,
                                addTemplate="item_in_world",
                                templOverride=(*item).proto ?? "",
                                tm=transform,
                                skipArrange=(*item).skipArrange ?? false,
                                gunSlot=-1
            ]])

    print("drop_loot2: count {dropCnt}")
    let str = build_string() <| $(var s)
      for desc in lootDesc
        let text = desc.eid != eid ? getEntityTemplateName(desc.eid) : desc.templOverride
        s |> write("drop_loot2 item: {desc.id} {text}\n")
    print(str)

    var arrangeItems : array<SimpleItemDesc>
    for item in lootDesc
      if item.skipArrange
        drop_item2(item, lootCleanupTime)
      else
        arrangeItems |> push(item)
    arrange_loot(transform, human_inventory__dropsLootRad, human_inventory__dropsLootGroupRad, arrangeItems)
    for item in arrangeItems
      drop_item2(item, lootCleanupTime)


def stop_use_item_impl(eid : EntityId)
  sendEventImmediate(eid, [[EventInterruptItemUse]])


def stop_use_item2(eid : EntityId)
  if is_server()
    stop_use_item_impl(eid)
  else
    send_net_event(eid, [[HumanStopUseItemRequest]])


def drop_gear_from_slot_impl(eid : EntityId; slot_name : string)
  query(eid) <| $ [es(REQUIRE=human_equipment__slots)] ()
    if dead_or_downed(eid)
      return
    sendEvent(eid, [[CmdEquipItem itemEid=INVALID_ENTITY_ID, slotName=slot_name]])


def drop_gear_from_slot2(eid : EntityId; slot_name : string)
  if eid == INVALID_ENTITY_ID
    return
  if is_server()
    drop_gear_from_slot_impl(eid, slot_name)
  else
    send_net_event(eid, [[HumanDropGearRequest slotName=slot_name]])

    query(eid) <| $ [es] (human_equipment__slots : Object)
      let itf = human_equipment__slots |> get_child(slot_name)
      if itf != null
        let itemObj = get_ecs_object(*itf)
        if itemObj != null
          let itemEid = get_Eid(*itemObj, "item") ?? INVALID_ENTITY_ID
          if itemEid != INVALID_ENTITY_ID
            sendEvent(eid, [[EventOnLootDrop itemEid=itemEid]])


def pickup_item_to_gear_slot_impl(eid, item_eid : EntityId; slot_name : string)
  if dead_or_downed(eid)
    return
  if !try_pickup_item(eid, item_eid)
    return
  equip_item_entity_to_slot(eid, item_eid, slot_name, false)


def pickup_item_to_gear_slot2(eid, item_eid : EntityId; slot_name : string)
  if eid == INVALID_ENTITY_ID
    return
  if is_server()
    pickup_item_to_gear_slot_impl(eid, item_eid, slot_name)
  else
    send_net_event(eid, [[HumanPickupGearRequest itemEid=item_eid, slotName=slot_name]])

    if can_pickup_item(item_eid, eid)
      sendEvent(eid, [[EventOnLootPickup itemEid=item_eid]])
