require ecs
require ecs.common
require game.es.human_use_action_common
require game.es.action_common
require game.utils.team
require HumanPhys
require EnlistedHuman
require inventory
require enlisted.events_enlisted


def can_auto_equip_gun_mod(item_eid : EntityId; eid : EntityId) : bool
  if !has(item_eid, "gunAttachable")
    return false
  var result = false
  query(eid) <| $ [es] (human_weap__gunMods : Array; human_weap__gunEids : EidList; human_weap__autoequipMods : bool)
    if !human_weap__autoequipMods
      return
    query(item_eid) <| $ [es] (gunAttachable__gunSlotName : string)
      for i in range(0, int(HUWeaponSlots EWS_NUM))
        let gunModsList = get_ecs_EidList(human_weap__gunMods[i])
        if gunModsList == null
          continue
        var haveMod = false
        for gunModEid in *gunModsList
          let gunSlotName = get_string(gunModEid, "gunAttachable__gunSlotName", "")
          if gunSlotName == gunAttachable__gunSlotName
            haveMod = true
            break
        if !haveMod && is_gunmod_allowed(human_weap__gunEids[i], item_eid)
          result = true
          return
  return result


[es(tag=(ui, render, gameClient), after=hero_human_use_human_object_es, REQUIRE=watchedByPlr)]
def human_use_action_es(info : ParallelUpdateFrameDelayed;
                        eid : EntityId;
                        human_net_phys : HumanActor const?;
                        human_weap__gunEids : EidList;
                        human_use_object__lookAtObject : EntityId;
                        human_inventory__selectedItem : EntityId;
                        human_use_object__selectedObject : EntityId;
                        human_breath__isUnderWater = false;
                        isAlive = true;
                        var useActionAvailable : int&;
                        var useActionEid : EntityId&;
                        var lookAtEid : EntityId&;
                        var pickupItemName : das_string&;
                        var pickupItemEid : EntityId&)
  useActionAvailable = int(HumanAction ACTION_NONE)
  lookAtEid = INVALID_ENTITY_ID
  if human_net_phys == null || !isAlive
    pickupItemName := ""
    pickupItemEid = INVALID_ENTITY_ID
    useActionEid = INVALID_ENTITY_ID
    lookAtEid = INVALID_ENTITY_ID
    return
  if human_inventory__selectedItem == INVALID_ENTITY_ID
    pickupItemEid = INVALID_ENTITY_ID
    useActionEid = INVALID_ENTITY_ID
    pickupItemName := ""
  let selectedItemEid = human_inventory__selectedItem
  let selectedObjectEid = human_use_object__selectedObject
  if selectedObjectEid != INVALID_ENTITY_ID && doesEntityExist(selectedObjectEid)
    let doorState = get_bool(selectedObjectEid, "door_operations__curState")
    if doorState != null
      if get_bool(selectedObjectEid, "isDoor") ?? true
        useActionAvailable = *doorState ? int(HumanAction ACTION_CLOSE_DOOR) : int(HumanAction ACTION_OPEN_DOOR)
      else
        useActionAvailable = *doorState ? int(HumanAction ACTION_CLOSE_WINDOW) : int(HumanAction ACTION_OPEN_WINDOW)
    elif get_bool(selectedObjectEid, "isDowned") ?? false
      if !human_breath__isUnderWater
        useActionAvailable = int(HumanAction ACTION_REVIVE_TEAMMATE)
    else
      let attachedGunEid = get_Eid(selectedObjectEid, "human_attached_gun__attachedGunEid") ?? INVALID_ENTITY_ID
      if attachedGunEid != INVALID_ENTITY_ID
        pass
      elif has(selectedObjectEid, "vehicle_seats__seats") && get_bool(selectedObjectEid, "isAlive") ?? false
        useActionAvailable = int(HumanAction ACTION_USE)
      elif has(selectedObjectEid, "lootable") && !has(selectedObjectEid, "lootableGunOnly") && !(get_bool(selectedObjectEid, "isAlive") ?? true)
        useActionAvailable = int(HumanAction ACTION_LOOT_BODY)
      elif has(selectedObjectEid, "squad_member__squad") && has(selectedObjectEid, "human")
        useActionAvailable = int(HumanAction ACTION_REQUEST_AMMO)
      elif has(selectedObjectEid, "shell__shell_id__shell_id")
        useActionAvailable = int(HumanAction ACTION_THROW_BACK)
      elif has(selectedObjectEid, "human_gun_attached")
        useActionAvailable = int(HumanAction ACTION_USE)
      elif has(selectedObjectEid, "buildByPlayer")
        useActionAvailable = int(HumanAction ACTION_NONE)
      else
        useActionAvailable = int(HumanAction ACTION_USE)
    useActionEid = selectedObjectEid
  elif selectedItemEid != INVALID_ENTITY_ID
    var tryPickUp = false
    query(selectedItemEid) <| $ [es] (item__weapTemplate : string = "")
      if item__weapTemplate != ""
        query(selectedItemEid) <| $ [es] (item__weapSlots : Array)
          tryPickUp = false
          var haveEmptySlot = false
          for slot in item__weapSlots
            let slotName = get_string(slot, "")
            let slotIdx = HUWeaponSlots(slotName)
            if human_weap__gunEids[int(slotIdx)] != INVALID_ENTITY_ID
              continue
            haveEmptySlot = true
            break
          if !haveEmptySlot
            useActionAvailable = int(HumanAction ACTION_SWITCH_WEAPONS)
          else
            tryPickUp = true
      else
        tryPickUp = true

    if tryPickUp
      let volume = get_float(selectedItemEid, "item__volume") ?? 0f
      if volume == 0f || can_pickup_item_by_volume(selectedItemEid, eid) || can_auto_equip_gun_mod(selectedItemEid, eid)
        useActionAvailable = int(HumanAction ACTION_PICK_UP)
      elif !can_pickup_item_by_uniqueness(eid, selectedItemEid)
        useActionAvailable = int(HumanAction ACTION_DENIED_ALREADY_EQUIPIED)
      else
        useActionAvailable = int(HumanAction ACTION_DENIED_TOO_MUCH_WEIGHT)
    query(selectedItemEid) <| $ [es] (item__name : string)
      pickupItemName := item__name
    pickupItemEid = selectedItemEid
  elif has(selectedItemEid, "stationary_gun")
    useActionAvailable = int(HumanAction ACTION_USE)
  elif check_action_precondition(eid, "recover")
    useActionAvailable = int(HumanAction ACTION_RECOVER)
  elif check_action_precondition(eid, "melee")
    useActionAvailable = int(HumanAction ACTION_MELEE)
  if human_use_object__lookAtObject != INVALID_ENTITY_ID && doesEntityExist(human_use_object__lookAtObject)
    lookAtEid = human_use_object__lookAtObject