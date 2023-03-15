require ecs
require ecs.safe
require ecs.common
require app
require common_shooter.events_common_shooter
require common_shooter.es.human_weap_common
require common_shooter.es.human.human_reload_common
require enlisted.events_enlisted
require daslib.strings_boost
require inventory
require game.events_game
require game.es.events
require math.base
require DagorRandom
require DagorSystem
require DagorMath
require DagorMathUtils
require DaWeaponProps
require DaWeapons
require Dacoll
require EnlistedNet
require EnlistedHuman
require EnlistedWeapon
require EnlistedPhys
require HumanPhys
require WeapHelpers
require Gun
require AnimV20
require GamePhys
require GridCollision


enum RecreateGunsFlags
  None         = 0
  Attach       = 1 << 0
  ParentLoaded = 1 << 1


def init_gun_comps(var init : ComponentsInitializer;
                   gun_slot : int;
                   eid : EntityId;
                   init_comps : Object? = null;
                   flags : int = 0)
  query(eid) <| $ [es] (human_weap__salt : IntList)
    let salt = human_weap__salt[gun_slot]
    if init_comps != null
      set(init, "gun__initialComponents", *init_comps)
      for kv in *init_comps
        set(init, kv.key, kv.value)

    set(init, "gun__salt", salt)

  set(init, "gun__owner", eid)
  set(init, "gun__initialSlotId", gun_slot)
  set(init, "gun__initialFlags", flags)


def create_gun_for_entity_impl(eid : EntityId;
                               gun_slot : int;
                               weap_templ_name : string;
                               init_comps : Object?;
                               flags : int;
                               create : block<(n : string; var ci : ComponentsInitializer) : EntityId>)
  if weap_templ_name == ""
    return INVALID_ENTITY_ID

  var name = weap_templ_name
  query(eid) <| $ [es] (human_weap__itemRemap : Object)
    if human_weap__itemRemap |> has(weap_templ_name)
      let n = human_weap__itemRemap[weap_templ_name] |> get_ecs_string()
      if n != null
        name = *n |> string()

  var gunEid = INVALID_ENTITY_ID
  using() <| $(var init : ComponentsInitializer)
    init_gun_comps(init, gun_slot, eid, init_comps, flags)
    gunEid = create |> invoke(name, init)
  return gunEid


def restore_ammo_type_impl(eid : EntityId;
                           var itemContainer : EidList;
                           ammo_template : string;
                           ammo_num : int;
                           calc_gun_ammo_cb : block<(ammo_item_id : int) : int>)
  if ammo_num <= 0
    return false

  let reserveAmmoItemId = ammo_template != "" ? int(ecs_hash(ammo_template)) : INVALID_ITEM_ID

  var initialNum = invoke(calc_gun_ammo_cb, reserveAmmoItemId) > 0 ? 1 : 0
  for itemEid in itemContainer
    var itemId = INVALID_ITEM_ID
    query(itemEid) <| $ [es] (item__id aka entity_item__id : int)
      itemId = entity_item__id
    initialNum += (itemId == reserveAmmoItemId) ? 1 : 0
  for _i in range(initialNum, ammo_num)
    var itemEid = INVALID_ENTITY_ID
    using() <| $(var init : ComponentsInitializer)
      set(init, "item__ownerEid", eid)
      set(init, "item__lastOwner", eid)
      itemEid = createInstantiatedEntitySync(ammo_template, init)
      if itemEid == INVALID_ENTITY_ID
        // createInstantiatedEntitySync may fail if the entity wasn't instantiated, it shouldn't be fatal, but should be fixed
        logerr("Template dependency '{ammo_template}' isn't instantiated in '{getEntityTemplateName(eid)}'")
        itemEid = createEntitySync(ammo_template, init)
    if find_index(itemContainer, itemEid) == -1
      itemContainer |> push(itemEid)

  return true


def restore_ammo_impl(eid : EntityId;
                      human_weap__gunEids : EidList;
                      gun_slot : int)
  var result = false
  query(eid) <| $ [es] (human_weap__weapInfo : Array;
                        var itemContainer : EidList)
    query(human_weap__gunEids[gun_slot]) <| $ [es(REQUIRE=gun)] (gun__ammo : int = 0; gun__ammoHolderEid : EntityId = INVALID_ENTITY_ID)
      let weapInfoSlot = human_weap__weapInfo[gun_slot] |> get_ecs_object()
      let curAmmoHolderItemId = get_int(gun__ammoHolderEid, "item__id") ?? INVALID_ITEM_ID
      assume calcGunAmmoCb = ($(ammoItemId : int) : int { return ammoItemId == curAmmoHolderItemId? gun__ammo : 0; })

      let numReserveAmmo = weapInfoSlot |> get_int("numReserveAmmo") ?? 0
      if numReserveAmmo > 0
        let reserveAmmoTemplate = weapInfoSlot |> get_ecs_string("reserveAmmoTemplate")
        if reserveAmmoTemplate == null
          logerr("'reserveAmmoTemplate' is missed in human_weap.weapInfo. See log for details.")
          print("eid: {eid} of template '{getEntityTemplateName(eid)}'")
          for item in human_weap__weapInfo
            let obj = item |> get_ecs_object()
            let objReserveAmmoTemplate = obj |> get_ecs_string("reserveAmmoTemplate")
            let objReserveAmmoTemplateStr = objReserveAmmoTemplate != null ? *objReserveAmmoTemplate |> string() : ""
            let objNumReserveAmmo = obj |> get_int("numReserveAmmo") ?? 0
            print("[reserveAmmoTemplate] = {objReserveAmmoTemplateStr}")
            print("[numReserveAmmo] = {objNumReserveAmmo}")
          return
        if !restore_ammo_type_impl(eid, itemContainer, string(*reserveAmmoTemplate), numReserveAmmo, calcGunAmmoCb)
          return

      let additionalAmmoTemplates = get_ecs_array(weapInfoSlot, "additionalReserveAmmoTemplates")
      let additionalAmmoNums = get_ecs_array(weapInfoSlot, "additionalNumReserveAmmos")
      if additionalAmmoTemplates != null && additionalAmmoNums != null
        for ammoTemplateItem, ammoNumItem in *additionalAmmoTemplates, *additionalAmmoNums
          let ammoTemplate = ammoTemplateItem ?? ""
          let ammoNum = ammoNumItem ?? 0
          if !restore_ammo_type_impl(eid, itemContainer, ammoTemplate, ammoNum, calcGunAmmoCb)
            return

      if (gun_slot != int(HUWeaponSlots EWS_GRENADE))
        reload_impl(eid, gun_slot, ReloadAmmoMode CONSUME)
      result = true
  return result


def restore_ammo_impl(eid : EntityId;
                      human_weap__gunEids : EidList)
  for i in iter_range(human_weap__gunEids)
    if human_weap__gunEids[i] != INVALID_ENTITY_ID
      restore_ammo_impl(eid, human_weap__gunEids, i)


def get_total_ammo_count(item_container : EidList;
                         wish_ammo_item_type : int;
                         gun_eid : EntityId)
  var res = 0
  query(gun_eid) <| $ [es] (gun__ammoHolderIds : IntList;
                            gun__shell_prop_ids : GunShellPropIds)
    for itemEid in item_container
      query(itemEid) <| $ [es] (shell_props : ShellPropIds const?;
                                item__id : int = INVALID_ITEM_ID;
                                ammo_holder__id : int const?;
                                ammo_holder__ammoCount : int const?)
        if wish_ammo_item_type != INVALID_ITEM_ID && item__id != wish_ammo_item_type
          return
        if ammo_holder__id != null && ammo_holder__ammoCount != null && is_ammo_for_gun(*ammo_holder__id, gun__ammoHolderIds)
          res += *ammo_holder__ammoCount
          return
        if shell_props != null && is_shell_for_gun(*shell_props, gun__shell_prop_ids)
          res++ // add 1 shell to total ammo count of gun
          return
  return res


def server_init_gun_ammo(gun_eid : EntityId)
  query(gun_eid) <| $ [es(REQUIRE=gun)] (gun__owner : EntityId;
                                         gun__ammo : int;
                                         gun__wishAmmoItemType : int;
                                         var gun__serverAmmo : int&;
                                         var gun__totalAmmo : int&)
    gun__serverAmmo = gun__ammo
    let itemContainer = get_ecs_EidList(gun__owner, "itemContainer")
    if itemContainer != null
      gun__totalAmmo = get_total_ammo_count(*itemContainer, gun__wishAmmoItemType, gun_eid)


[es(tag=server, on_appear, after=gun_init_shell_prop_ids_es)]
def gun_mod_custom_props_init_es(evt : Event;
                                 eid : EntityId;
                                 gunAttachable__slotName : string;
                                 var slot_attach__slotId : int&;
                                 var custom_props : Object?)
  let animcharSlotId = animchar_getSlotId(gunAttachable__slotName)
  slot_attach__slotId = animcharSlotId
  if custom_props != null
    human_gun_mod_from_custom_props(*custom_props, eid)
  server_init_gun_ammo(eid)


def attach_item_to_gun_impl(eid : EntityId;
                            human_weap__gunEids : EidList;
                            gun_slot_id : int;
                            slot_tag : string;
                            slot_name : string;
                            var human_weap__gunMods : Array;
                            var custom_props : Object? = null)
  if !human_weap__gunEids[gun_slot_id]
    return

  query(eid) <| $ [es] (var human_weap__gunModsBySlot : Array)
    var gunModSlots = human_weap__gunModsBySlot[gun_slot_id] |> getRW_ecs_object()
    if gunModSlots == null
      return

    if !*gunModSlots |> has(slot_name)
      return

    // Unload ammo from weapon mod, if any.
    human_gun_mod_to_custom_props(eid, gun_slot_id, slot_name, null)

    *gunModSlots |> set(slot_name, slot_tag)

    var gunMods = getRW_ecs_EidList(human_weap__gunMods[gun_slot_id])
    for i in iter_range(*gunMods)
      let gunModEid = (*gunMods)[i]
      var erased = false
      query(gunModEid) <| $ [es] (gunAttachable__gunSlotName : string)
        if gunAttachable__gunSlotName == slot_name
          destroyEntity(gunModEid)
          *gunMods |> erase(i)
          erased = true
      if erased
        break

    if slot_tag == ""
      return

    let gunEid = human_weap__gunEids[gun_slot_id]
    query(gunEid) <| $ [es] (gun_mods__slots : Object)
      let slot = gun_mods__slots |> get_ecs_object(slot_name)
      if slot == null
        logerr("Gun '{getEntityTemplateName(gunEid)}' does not have slot '{slot_name}' in component 'gun_mods.slots'")
        return
      let slotName = *slot |> get_ecs_string(slot_tag)
      if slotName == null
        var avSlotTags = ""
        for kv in *slot
          avSlotTags += kv.key
          avSlotTags += ","
        if avSlotTags != ""
          avSlotTags = avSlotTags |> chop(0, length(avSlotTags) - 1)
        logerr("Unknown slot_tag '{slot_tag}' for slot '{slot_name}' while creating gunMods for {human_weap__gunEids[gun_slot_id]}<{getEntityTemplateName(human_weap__gunEids[gun_slot_id])}>,\navailable slot tags are {avSlotTags}")
        return

      using() <| $(var comps : ComponentsInitializer)
        set(comps, "slot_attach__attachedTo", gunEid)

        // Weapon mod might be a weapon itself, so try and set mandatory weapon components.
        let weapSalt = get_ecs_IntList(eid, "human_weap__salt")
        if weapSalt != null
          set(comps, "gun__salt", (*weapSalt)[gun_slot_id])
        set(comps, "gun__owner", eid)

        using() <| $(var customPropsCopy : Object)
          if custom_props != null
            customPropsCopy := *custom_props
            set(comps, "custom_props", customPropsCopy)
            // Weapon mod might be created asynchronously, so we can't keep ref
            // to 'custom_props', we copy custom_props instead. But that's not enough,
            // custom_props might contain ammo holder eid that'll get freed if not reset,
            // so we reset it here. Ownership will be passed to weapon mod eventually.
            human_gun_mod_reset_custom_props(*custom_props)

          var modEid = INVALID_ENTITY_ID
          if is_dedicated()
            // Use createEntitySync on the server because we want as many set value to be at initial replication.
            // Otherwise the data will be sent as replica. In the sake of traffic reduction.
            modEid = createEntitySync(*slotName |> string(), comps)
          else
            modEid = createEntity(*slotName |> string(), comps)

          *gunMods |> push(modEid)


struct GunModInSlot
  key : string
  value : string


def server_init_gun(eid : EntityId;
                    gun_eid : EntityId;
                    slot_id : int;
                    var human_weap__gunEids : EidList)
  human_weap__gunEids[slot_id] = gun_eid
  query(eid) <| $ [es] (human_weap__currentGunSlot : int;
                        var human_weap__gunModsBySlot : Array;
                        var human_weap__gunMods : Array;
                        var human_weap__currentGunEid : EntityId&;
                        var human_weap__currentGunModEids : EidList&)
    let gunEidInSlot = human_weap__gunEids[slot_id]
    if gunEidInSlot != INVALID_ENTITY_ID
      var gunModsInSlot = human_weap__gunModsBySlot[slot_id] |> getRW_ecs_object()
      if gunModsInSlot != null
        restore_ammo_impl(eid, human_weap__gunEids, slot_id)
        query(gunEidInSlot) <| $ [es] (var gun_mods__slots : Object)
          for slot in gun_mods__slots
            let slotName = slot.key
            if !*gunModsInSlot |> has(slotName)
              *gunModsInSlot |> set(slotName, "")

        if length(*gunModsInSlot) > 0
          // Temp copy since we modifying gunModsBySlot[slot_id] within attach_item_to_gun_impl()
          var gunModsInSlotCopy : array<GunModInSlot>
          gunModsInSlotCopy |> reserve(length(*gunModsInSlot))
          for gunMod in *gunModsInSlot
            let gunModStr = gunMod.value |> get_ecs_string()
            let value = gunModStr != null ? *gunModStr |> string() : ""
            gunModsInSlotCopy |> push([[GunModInSlot key=gunMod.key, value=value]])
          for gunMod in gunModsInSlotCopy
            var nullCustomProps : Object? = null
            attach_item_to_gun_impl(eid, human_weap__gunEids, slot_id, gunMod.value,
                                    gunMod.key, human_weap__gunMods, nullCustomProps)

      server_init_gun_ammo(gunEidInSlot)

    if human_weap__currentGunSlot == slot_id
      human_weap__currentGunEid = human_weap__gunEids[slot_id]
      human_weap__currentGunModEids := *(human_weap__gunMods[slot_id] |> get_ecs_EidList())


[es(tag=server, on_appear)]
def server_init_gun_es(evt : Event;
                       eid : EntityId;
                       gun__owner : EntityId;
                       gun__initialSlotId : int;
                       gun__initialFlags : int)
  if gun__initialSlotId != -1
    let gunEid = eid
    var gunEids = getRW_ecs_EidList(gun__owner, "human_weap__gunEids")
    if gunEids == null // Parent was destroyed before guns creation?
      if !doesEntityExist(gun__owner)
        logwarn("Ignore gun[{gun__initialSlotId}] init since parent {gun__owner} doesn't exist anymore")
      else
        logerr("Gun's [{gun__initialSlotId}] parent {gun__owner}<{getEntityTemplateName(gun__owner)}> exist but doesn't have 'human_weap.gunEids' component?!")
      return
    server_init_gun(gun__owner, gunEid, gun__initialSlotId, *gunEids)
    if (gun__initialFlags & int(RecreateGunsFlags Attach)) != 0
      let attach = (gun__initialSlotId == get_int(gun__owner, "human_weap__currentGunSlot") ?? 0)
      sendEventImmediate(gunEid, [[CmdWeapAttach toEid=gun__owner, isAttached=attach, slotId=gun__initialSlotId]])

    if (gun__initialFlags & int(RecreateGunsFlags ParentLoaded)) != 0
      sendEvent(gunEid, [[EventOnParentLoaded eid=gun__owner, slotId=gun__initialSlotId]])
    if has(gun__owner, "hero")
      sendEvent(gun__owner, [[CmdTrackHeroWeapons]])


def server_recreate_guns(eid : EntityId;
                         human_weap__weapTemplates : Object;
                         flags : int;
                         var human_weap__gunEids : EidList;
                         var human_weap__gunMods : Array;
                         var human_weap__weapInitialComponents : Array)
  human_weap__gunEids |> resize(int(HUWeaponSlots EWS_NUM))
  var currentGunSlot = -1
  for slotId in range(int(HUWeaponSlots EWS_NUM))
    destroyEntity(human_weap__gunEids[slotId])
    var gunMods = human_weap__gunMods[slotId] |> getRW_ecs_EidList()
    if gunMods != null
      for gunModEid in *gunMods
        destroyEntity(gunModEid)
      *gunMods |> clear()
    if currentGunSlot < 0
      currentGunSlot = slotId
    let weaponSlotName = get_human_weapon_slot_name(slotId)
    let weapTempl = human_weap__weapTemplates |> get_ecs_string(weaponSlotName)
    let weapTemplStr = weapTempl != null ? *weapTempl |> string() : ""
    // Create entity synchronously on dedicated in order to be able add all it's guns in net scope on avatar creation
    // (i.e. this reduces latency for weapons creation). This also might reduce unwanted replication traffic
    var gunInitComps : Object? = null
    if slotId < length(human_weap__weapInitialComponents)
      gunInitComps = human_weap__weapInitialComponents[slotId] |> getRW_ecs_object()

    human_weap__gunEids[slotId] = create_gun_for_entity_impl(eid, slotId, weapTemplStr, gunInitComps, flags) <| $(n : string;
                                                                                                                  var ci : ComponentsInitializer)
      if is_dedicated()
        var newEid = createInstantiatedEntitySync(n, ci)
        if newEid == INVALID_ENTITY_ID
          // createInstantiatedEntitySync may fail if the entity wasn't instantiated, it shouldn't be fatal, but should be fixed
          logerr("Template dependency '{n}' isn't instantiated in '{getEntityTemplateName(eid)}'")
          newEid = createEntitySync(n, ci)
        return newEid
      else
        return createEntity(n, ci)

    if !human_weap__gunEids[slotId] && slotId == currentGunSlot
      currentGunSlot = -1
  return currentGunSlot


def setup_human_actor_weapon_slot(human_weap__gunEids : EidList;
                                  human_weap__currentGunSlot : int;
                                  var human_net_phys : HumanActor)
  if !human_weap__gunEids[int(human_net_phys.phys.producedCT.chosenWeapon)]
    if human_weap__currentGunSlot >= 0
      human_net_phys.phys.producedCT |> set_chosen_weapon(HUWeaponSlots(human_weap__currentGunSlot))
      human_net_phys.phys.currentState.weapEquipState.curSlot = HUWeaponSlots(human_weap__currentGunSlot)


[es(tag=server, on_appear)]
def human_weap_created_server_es(evt : Event;
                                 eid : EntityId;
                                 human_weap__weapTemplates : Object;
                                 var human_weap__gunEids : EidList;
                                 var human_weap__gunMods : Array;
                                 var human_weap__weapInitialComponents : Array;
                                 var human_weap__salt : IntList;
                                 var human_weap__currentGunSlot : int&;
                                 var human_net_phys : HumanActor?)
  for saltI in iter_range(human_weap__salt)
    if human_weap__salt[saltI] < 0
      human_weap__salt[saltI] = grnd()

  human_weap__currentGunSlot = server_recreate_guns(eid, human_weap__weapTemplates,
                                                    int(RecreateGunsFlags Attach) | int(RecreateGunsFlags ParentLoaded),
                                                    human_weap__gunEids, human_weap__gunMods, human_weap__weapInitialComponents)

  if human_net_phys != null
    setup_human_actor_weapon_slot(human_weap__gunEids, human_weap__currentGunSlot, *human_net_phys)


[es(tag=netClient, on_appear)]
def human_weap_created_client_es(evt : Event;
                                 eid : EntityId;
                                 human_weap__gunEids : EidList;
                                 human_weap__currentGunSlot : int;
                                 var human_net_phys : HumanActor?)
  if human_net_phys != null
    setup_human_actor_weapon_slot(human_weap__gunEids, human_weap__currentGunSlot, *human_net_phys)
  for i in range(int(HUWeaponSlots EWS_NUM))
    if human_weap__gunEids[i] != INVALID_ENTITY_ID
      let attach = (human_weap__currentGunSlot == i)
      add_delayed_action_client_wait_for_gun_creation(eid, human_weap__gunEids[i], attach, i)


[es(tag=netClient)]
def clear_client_pending_gun_creation_waits_es(evt : EventEntityManagerBeforeClear)
  remove_delayed_actions_client_wait_for_gun_creation()


// Tracking the creation of non-physical projectiles (displayed in hand)
[es(tag=netClient, REQUIRE_NOT=phys_obj_net_phys, on_appear)]
def replace_local_projectile_es(evt : Event;
                                eid : EntityId;
                                shell__owner : EntityId;
                                var slot_attach__attachedTo aka server_slot_attach__attachedTo : EntityId&;
                                var slot_attach__slotId aka server_slot_attach__slotId : int&;
                                var gun__visible aka server_gun__visible : bool&)
  // The local and the server projectiles must have the same owner
  // The owner of a long-living projectile may be already destroyed

  // human_weap__localProjectileEid is not found means the projectile's owner was destroyed
  query(shell__owner) <| $ [es] (var human_weap__localProjectileEid : EntityId&)
    let serverProjectileEid = eid

    // localProjectileEid == ecs::INVALID_ENTITY_ID means there was no client-side projectile or it's already destroyed
    // serverProjectileEid == localProjectileEid means this ES is processing the local projectile (name "serverProjectileEid" is misleading)
    if human_weap__localProjectileEid == INVALID_ENTITY_ID || serverProjectileEid == human_weap__localProjectileEid
      return
    // If there are two projectiles (local and server's) with the same owner, the local should be destroyed

    // Copy the visibility and attachment state from the local projectile, so if it was already displayed, new projectile will be too
    // Local projectile may not have the components if it's not yet created, hence the ECS_GET_OR
    query(human_weap__localProjectileEid) <| $ [es] (slot_attach__attachedTo aka local_slot_attach__attachedTo : EntityId)
      server_slot_attach__attachedTo = local_slot_attach__attachedTo

    query(human_weap__localProjectileEid) <| $ [es] (slot_attach__slotId aka local_slot_attach__slotId : int)
      server_slot_attach__slotId = local_slot_attach__slotId

    query(human_weap__localProjectileEid) <| $ [es] (gun__visible aka local_gun__visible : bool)
      server_gun__visible = local_gun__visible

    // The local projectile should be destroyed even if its asynchronous creation process is yet in progress
    destroyEntity(human_weap__localProjectileEid)
    human_weap__localProjectileEid = INVALID_ENTITY_ID


[es(tag=netClient, on_disappear)]
def destroy_local_projectile_es(evt : Event;
                                var human_weap__localProjectileEid : EntityId&)
  // Destroying the grenade in hand, when the human_weap is destroyed
  destroyEntity(human_weap__localProjectileEid)
  human_weap__localProjectileEid = INVALID_ENTITY_ID


[es(REQUIRE=human_weap, track=isDowned)]
def change_from_greande_thrower_on_revive(evt : Event;
                                          eid : EntityId;
                                          isDowned : bool;
                                          human_weap__gunEids : EidList;
                                          var human_weap__throwMode : bool&;
                                          var human_net_phys : HumanActor)
  if !isDowned && !human_weap__throwMode
    clear_throw_mode(eid, human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)], human_weap__gunEids,
                     human_weap__throwMode, human_net_phys.phys)


[es(REQUIRE=human_weap, REQUIRE_NOT=human_input)]
def human_weap_post_phys_es(evt : CmdPostPhysUpdate;
                            eid : EntityId;
                            transform : float3x4;
                            isInVehicle : bool;
                            human_vehicle__isHoldingGunPassenger : bool;
                            human_weap__lockedGrenadeThrowingCounter : int = 0;
                            human_weap__jumpDeviation : float = 0.;
                            human_weap__changePosDeviationCanAim : float = 0.;
                            human_weap__changePosDeviationCanNotAim : float = 0.;
                            human_phys__afterJumpDelay : float = 0.;
                            human_phys__jumpEndTime : float;
                            human_phys__isInAirLong : bool;
                            entity_mods__shotDeviationMult : float = 1.0;
                            entity_mods__rotationShotSpreadDecrMult : float = 1.0;
                            entity_mods__aimingAfterFireMult : float = 1.0;
                            entity_mods__boltActionMult : float = 1.0;
                            entity_mods__deviationBufferSizeMult : float = 1.0;
                            human_use_object__selectedObject : EntityId const? = null;
                            entity_mods__shotDeviationAdd : float = 0.0;
                            human_weap__fastThrowExclusive : bool = true;
                            human_unarmed__active : bool = false;
                            isAlive : bool = true;
                            isDowned : bool = false;
                            human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                            var human_net_phys : HumanActor;
                            var human_weap__gunEids : EidList;
                            var human_weap__throwMode : bool&)
  if isAlive && !isDowned
    let tick = evt.tick
    let dt = evt.dt
    let isForReal = evt.isForReal
    let atTime = float(tick + 1) * dt
    let gunDir = human_net_phys.phys.currentState.gunDir
    let physTransform = human_net_phys.phys.currentState.location |> location_makeTM()

    let updCtx = [[GunUpdateCtx
      dt=dt,
      atTime=atTime,
      isForReal=isForReal,
      eid=eid,
      isDowned=isDowned,
      isThrowingAllowed=human_weap__lockedGrenadeThrowingCounter == 0 && (human_vehicle__isHoldingGunPassenger || !isInVehicle),
      shotDeviationMult=entity_mods__shotDeviationMult,
      rotationShotSpreadDecrMult=entity_mods__rotationShotSpreadDecrMult,
      aimingAfterFireMult=entity_mods__aimingAfterFireMult,
      boltActionMult=entity_mods__boltActionMult,
      shotDeviationAdd=entity_mods__shotDeviationAdd,
      fastThrowExclusive=human_weap__fastThrowExclusive,
      deviationBufferSizeMult=entity_mods__deviationBufferSizeMult]]

    human_weap_gun_update(human_net_phys, human_weap__gunEids, human_weap__throwMode,
                          updCtx,  transform, gunDir, gunDir, physTransform,
                          human_net_phys.phys.appliedCT, human_use_object__selectedObject,
                          human_unarmed__active, human_attached_gun__attachedGunEid,
                          human_weap__jumpDeviation, human_weap__changePosDeviationCanAim, human_weap__changePosDeviationCanNotAim,
                          human_phys__jumpEndTime, human_phys__afterJumpDelay, human_phys__isInAirLong)


def determine_current_slot(cur_time : float;
                           human_net_phys : HumanActor;
                           human_inventory__entityToUse : EntityId;
                           human_weap__lockWeaponSwitch : bool;
                           isDowned : bool;
                           human_sec_anim__hideWeapon : bool;
                           human_sec_anim__hideMelee : bool;
                           human_sec_anim__play : bool;
                           human_unarmed__hiddenWeapon : bool;
                           action__running : bool;
                           burning__isPuttingOut : bool;
                           human_weap__radioMode : bool = false;
                           human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID)
  var curSlot = int(determine_current_weapon_slot(cur_time, human_net_phys))
  if human_weap__lockWeaponSwitch
    return curSlot

  let attachedToGun = (human_attached_gun__attachedGunEid != INVALID_ENTITY_ID)
  let isHealing = (human_inventory__entityToUse != INVALID_ENTITY_ID &&
                  has(human_inventory__entityToUse, "item__healAnimEnumValue"))
  if ((!action__running && (human_net_phys.phys.currentState |> human_phys_state_get_is_swimming))
      || attachedToGun || isHealing || burning__isPuttingOut || isDowned || human_unarmed__hiddenWeapon
      || human_net_phys.phys.currentState |> human_phys_state_attachedToLadder)
    curSlot = -1
  if human_sec_anim__play && (human_sec_anim__hideWeapon || (human_sec_anim__hideMelee && curSlot == int(HUWeaponSlots EWS_MELEE)))
    curSlot = -1
  if human_weap__radioMode
    curSlot = -1
  return curSlot


def has_any_attached_gun(human_weap__gunEids : EidList)
  for gunEid in human_weap__gunEids
    if get_bool(gunEid, "human_gun_attached") ?? false
      return true
  return false


def set_current_gun(eid : EntityId;
                    human_weap__gunEids : EidList;
                    cur_gun : int;
                    var human_weap__currentGunSlot : int&)
  if human_weap__currentGunSlot == cur_gun
    return

  human_weap__currentGunSlot = cur_gun
  for i in iter_range(human_weap__gunEids)
    let isAttached = (i == cur_gun)
    sendEvent(human_weap__gunEids[i], [[CmdWeapAttach toEid=eid, isAttached=isAttached, slotId=i]])

  sendEvent(eid, [[EventOnSelectWeap curr_gun_slot_id=human_weap__currentGunSlot]])


def send_attach_event_to_current_gun(eid : EntityId;
                                     human_weap__gunEids : EidList;
                                     human_weap__currentGunSlot : int)
  if human_weap__currentGunSlot < 0 || human_weap__currentGunSlot >= length(human_weap__gunEids)
    return
  let gunEid = human_weap__gunEids[human_weap__currentGunSlot]
  if !(get_bool(gunEid, "human_gun_attached") ?? true)
    sendEvent(gunEid, [[CmdWeapAttach toEid=eid, isAttached=true, slotId=human_weap__currentGunSlot]])


def human_weap_es_impl(var human_weap__currentGunSlot : int&;
                       cur_time : float;
                       eid : EntityId;
                       human_weap__gunEids : EidList;
                       human_net_phys : HumanActor;
                       human_inventory__entityToUse : EntityId;
                       action__running : bool;
                       isInVehicle : bool;
                       isInVehicleHidden : bool;
                       isDowned : bool;
                       human_vehicle__isHoldingGunPassenger : bool;
                       human_sec_anim__hideWeapon : bool;
                       human_sec_anim__hideMelee : bool;
                       human_sec_anim__play : bool;
                       human_unarmed__hiddenWeapon : bool;
                       human_weap__lockWeaponSwitch : bool;
                       burning__isPuttingOut : bool;
                       human_weap__radioMode : bool = false;
                       human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID)
  let curSlot = determine_current_slot(cur_time, human_net_phys, human_inventory__entityToUse,
    human_weap__lockWeaponSwitch, isDowned, human_sec_anim__hideWeapon, human_sec_anim__hideMelee,
    human_sec_anim__play, human_unarmed__hiddenWeapon, action__running, burning__isPuttingOut,
    human_weap__radioMode, human_attached_gun__attachedGunEid)

  let animSlot = isInVehicle && !isInVehicleHidden && !human_vehicle__isHoldingGunPassenger && !action__running ? -1 : curSlot

  if human_weap__currentGunSlot != curSlot || (animSlot < 0 && has_any_attached_gun(human_weap__gunEids))
    set_current_gun(eid, human_weap__gunEids, animSlot, human_weap__currentGunSlot)
  human_weap__currentGunSlot = curSlot

  if !isDowned
    send_attach_event_to_current_gun(eid, human_weap__gunEids, animSlot)


[es(tag=server, before=human_weap_post_phys_es)]
def human_weap_es(evt : CmdPostPhysUpdate;
                  eid : EntityId;
                  human_weap__gunEids : EidList;
                  human_net_phys : HumanActor;
                  human_inventory__entityToUse : EntityId;
                  action__running : bool = false;
                  isInVehicle : bool = false;
                  isInVehicleHidden : bool = false;
                  isDowned : bool = false;
                  human_vehicle__isHoldingGunPassenger : bool = false;
                  human_sec_anim__hideWeapon : bool = false;
                  human_sec_anim__hideMelee : bool = false;
                  human_sec_anim__play : bool = false;
                  human_unarmed__hiddenWeapon : bool = false;
                  human_weap__lockWeaponSwitch : bool = false;
                  burning__isPuttingOut : bool = false;
                  human_weap__radioMode : bool = false;
                  isAlive : bool;
                  human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                  var human_weap__currentGunSlot : int&)
  if isAlive
    human_weap_es_impl(
      human_weap__currentGunSlot, get_sync_time(), eid, human_weap__gunEids,
      human_net_phys, human_inventory__entityToUse, action__running,
      isInVehicle, isInVehicleHidden, isDowned, human_vehicle__isHoldingGunPassenger,
      human_sec_anim__hideWeapon, human_sec_anim__hideMelee,
      human_sec_anim__play, human_unarmed__hiddenWeapon, human_weap__lockWeaponSwitch, burning__isPuttingOut,
      human_weap__radioMode, human_attached_gun__attachedGunEid)


[es(tag=netClient, after=(human_phys_es, before_human_inventory_use_update), before=human_weap_update_es)]
def human_weap_client_es(info : ParallelUpdateFrameDelayed;
                         eid : EntityId;
                         human_weap__gunEids : EidList;
                         human_net_phys : HumanActor;
                         human_inventory__entityToUse : EntityId;
                         action__running : bool = false;
                         isInVehicle : bool = false;
                         isInVehicleHidden : bool = false;
                         isDowned : bool = false;
                         human_vehicle__isHoldingGunPassenger : bool = false;
                         human_sec_anim__hideWeapon : bool = false;
                         human_sec_anim__hideMelee : bool = false;
                         human_sec_anim__play : bool = false;
                         human_unarmed__hiddenWeapon : bool = false;
                         human_weap__lockWeaponSwitch : bool = false;
                         burning__isPuttingOut : bool = false;
                         human_weap__radioMode : bool = false;
                         isAlive : bool;
                         human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                         var human_weap__currentGunSlot : int&)
  if isAlive
    human_weap_es_impl(
      human_weap__currentGunSlot, info.curTime, eid, human_weap__gunEids,
      human_net_phys, human_inventory__entityToUse, action__running,
      isInVehicle, isInVehicleHidden, isDowned, human_vehicle__isHoldingGunPassenger,
      human_sec_anim__hideWeapon, human_sec_anim__hideMelee,
      human_sec_anim__play, human_unarmed__hiddenWeapon, human_weap__lockWeaponSwitch, burning__isPuttingOut,
      human_weap__radioMode, human_attached_gun__attachedGunEid)


[es(track=(isAlive, isDowned), on_event=EventEntityDied, before=destroy_nonlootable_weapons)]
def human_weap_drop_grenade_es(evt : Event;
                               eid : EntityId;
                               isAlive : bool;
                               isDowned : bool;
                               human_weap__gunEids : EidList;
                               var human_weap__throwMode : bool&;
                               var human_net_phys : HumanActor)
  if isAlive && !isDowned
    return

  if human_weap__throwMode
    query(human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)]) <| $ [es] (grenade_thrower__projectileEntity : EntityId)
      query(grenade_thrower__projectileEntity) <| $ [es] (slot_attach__attachedTo : EntityId;
                                                          shell__shell_id__shell_id : int;
                                                          var active : bool&;
                                                          var shell__explTime : float?)
        if !slot_attach__attachedTo
          return
        if !active && shell__explTime != null
          // If the soldier is downed before grenade's cookProgressTime, activate and set explosion timer anyway
          detonation_get_props(shell__shell_id__shell_id) <| $(detonationProps : DetonationProps)
            *shell__explTime = get_sync_time() + detonationProps.timer

        active = true
        query(eid) <| $ [es] (human_net_phys__velocity : float3)
          assume curState = human_net_phys.phys.currentState
          var tm = IDENT_TM
          let locTm = curState.location |> location_makeTM()
          human_net_phys.phys |> human_phys_calcGunTm(PrecomputedPresetMode FPV,
                                                      locTm,
                                                      curState.gunAngles.y,
                                                      curState.leanPosition,
                                                      curState.height,
                                                      tm)
          let curTime = get_sync_time()
          let isForReal = true
          let rndSeed = phys_time_to_seed(curTime)

          let dir = (!isAlive ? normalize(float3(0.14, -0.99, 0.0)) // Approximative down
                              : human_net_phys.phys.currentState.gunDir)

          using(dir, dir, human_net_phys__velocity, tm, tm) <| $(var gloc : GunLocation#)
            using() <| $(var gtrlNew : GunControls#)
              gtrlNew.shoot = true
              gtrlNew.wishShoot = false
              gtrlNew.boltActionMult = 1.0
              gtrlNew.timeStep = 0.01
              sendEventImmediate(
                human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)],
                [[CmdGunUpdate
                  atTime=curTime,
                  isForReal=isForReal,
                  seed=rndSeed,
                  gctrl := gtrlNew,
                  gloc := gloc]])
      clear_throw_mode(eid, human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)], human_weap__gunEids,
                       human_weap__throwMode, human_net_phys.phys)


def detach_guns(eid : EntityId;
                human_weap__gunEids : EidList)
  for i in iter_range(human_weap__gunEids)
    sendEvent(human_weap__gunEids[i], [[CmdWeapAttach toEid=eid, isAttached=false, slotId=i]])
    sendEvent(human_weap__gunEids[i], [[CmdWeapDetach]])


def on_detach_all_guns_impl(eid : EntityId;
                            human_weap__gunEids : EidList;
                            var human_weap__currentGunSlot : int&)
  detach_guns(eid, human_weap__gunEids)
  set_current_gun(eid, human_weap__gunEids, -1, human_weap__currentGunSlot)


def on_detach_all_guns(eid : EntityId;
                       human_weap__gunEids : EidList;
                       var human_weap__currentGunSlot : int&)
  on_detach_all_guns_impl(eid, human_weap__gunEids, human_weap__currentGunSlot)

  send_net_event(eid, [[HumanDetachAllGuns]])


[es(tag=server, track=isAlive, on_event=EventEntityDied, on_disappear, before=destroy_nonlootable_weapons)]
def human_weap_dead_es(evt : Event;
                       eid : EntityId;
                       human_weap__gunEids : EidList;
                       isAlive : bool;
                       var human_weap__currentGunSlot : int&)
  if !isAlive
    if human_weap__currentGunSlot >= 0
      on_detach_all_guns(eid, human_weap__gunEids, human_weap__currentGunSlot)


[es(tag=server)]
def human_weap_req_switch_firing_mode_es(evt : HumanWeapRequestSwitchFiringMode;
                                         human_weap__gunEids : EidList)
  let slotId = int(evt.slotId)
  let modeId = int(evt.modeId)
  if slotId >= length(human_weap__gunEids)
    return

  query(human_weap__gunEids[slotId]) <| $ [es] (var gun : Gun; var gun__firingModeIndex : int&)
    if gun |> gun_checkFiringModeIndex(modeId)
      gun |> gun_setFiringModeIndex(evt.modeId)
      gun__firingModeIndex = modeId


[es(tag=netClient)]
def human_weap_human_detach_all_guns_es(evt : HumanDetachAllGuns;
                                        eid : EntityId;
                                        human_weap__gunEids : EidList;
                                        var human_weap__currentGunSlot : int&)
  on_detach_all_guns_impl(eid, human_weap__gunEids, human_weap__currentGunSlot)


[es]
def human_weap_set_current_gun_es(evt : HumanWeapSetCurrentGun;
                                  var human_net_phys : HumanActor)
  human_net_phys.phys.producedCT |> set_chosen_weapon(HUWeaponSlots(int(evt.slot)))
  human_net_phys.phys.currentState.weapEquipState.curSlot = HUWeaponSlots(int(evt.slot))


[es]
def human_weap_weap_throw_back_abort_es(evt : HumanWeapThrowBackAbort;
                                        var human_weap__throwMode : bool&;
                                        var human_net_phys : HumanActor)
  if human_weap__throwMode && human_net_phys.phys.appliedCT |> is_control_bit_set(HumanPhysControlType HCT_THROW_BACK)
    human_weap__throwMode = false
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit(HumanPhysControlType HCT_THROW_BACK, false)


def update_total_ammo(gun_eid : EntityId;
                      itemContainer : EidList)
  query(gun_eid) <| $ [es(REQUIRE=gun)] (gun__wishAmmoItemType : int;
                                         var gun__totalAmmo : int&)
    gun__totalAmmo = get_total_ammo_count(itemContainer, gun__wishAmmoItemType, gun_eid)


[es(tag=server, track=(human_weap__gunEids, itemContainer))]
def human_weap_update_total_count_es(evt : Event;
                                     human_weap__gunEids : EidList;
                                     human_weap__gunMods : Array;
                                     itemContainer : EidList)
  for i in iter_range(human_weap__gunEids)
    update_total_ammo(human_weap__gunEids[i], itemContainer)
  for i in iter_range(human_weap__gunMods)
    let gunMods = get_ecs_EidList(human_weap__gunMods[i])
    if gunMods != null
      for gunModEid in *gunMods
        update_total_ammo(gunModEid, itemContainer)


[es(tag=server, track=(human_weap__gunEids, itemContainer))]
def human_weap_update_additional_ammo_count_es(evt : Event;
                                               human_weap__gunEids : EidList;
                                               itemContainer : EidList)
  for i in iter_range(human_weap__gunEids)
    let gunEid = human_weap__gunEids[i]
    query(gunEid) <| $ [es] (gun__isDualMagReady : bool;
                             var gun__additionalAmmo : int&)
      if gun__isDualMagReady
        find_ammo_for_gun(gunEid, itemContainer, INVALID_ITEM_ID, 0) <| $(ammoForGun : AmmoItemForGunResult)
          gun__additionalAmmo = ammoForGun.ammoCount


[es(tag=server, on_appear, track=(gun__isDualMagReady, gun__owner))]
def gun_update_additional_ammo_count_es(evt : Event;
                                        eid : EntityId;
                                        gun__owner : EntityId;
                                        gun__isDualMagReady : bool;
                                        var gun__additionalAmmo : int&)
  if !gun__isDualMagReady
    gun__additionalAmmo = 0
  else
    query(gun__owner) <| $ [es] (itemContainer : EidList)
      find_ammo_for_gun(eid, itemContainer, INVALID_ITEM_ID, 0) <| $(ammoForGun : AmmoItemForGunResult)
        gun__additionalAmmo = ammoForGun.ammoCount


[es(tag=server, track=gun__wishAmmoItemType)]
def human_weap_update_total_count_wish_ammo_item_type_es(evt : Event;
                                                         eid : EntityId;
                                                         gun__owner : EntityId;
                                                         gun__wishAmmoItemType : int;
                                                         var gun__totalAmmo : int&)
  query(gun__owner) <| $ [es] (itemContainer : EidList)
    gun__totalAmmo = get_total_ammo_count(itemContainer, gun__wishAmmoItemType, eid)


[es]
def human_weap_reinit_guns_es(evt : CmdReinitWeapons;
                              eid : EntityId;
                              human_weap__weapTemplates : Object;
                              var human_weap__currentGunSlot : int&;
                              var human_weap__gunEids : EidList;
                              var human_weap__gunMods : Array;
                              var human_weap__weapInitialComponents : Array)
  human_weap__currentGunSlot = server_recreate_guns(eid, human_weap__weapTemplates,
                                                    int(RecreateGunsFlags Attach),
                                                    human_weap__gunEids, human_weap__gunMods,
                                                    human_weap__weapInitialComponents)


[es(tag=server, on_appear)]
def reserve_ammo_props_init_es(evt : Event;
                               human_weap__weapInfo : Array;
                               var human_weap__reserveAmmoPropIds : IntList)
  let weapInfoSize = length(human_weap__weapInfo)
  human_weap__reserveAmmoPropIds |> resize(weapInfoSize)
  for i in range(weapInfoSize)
    let weapInfoSlot = get_ecs_object(human_weap__weapInfo[i])
    if weapInfoSlot != null
      let resvAmmoTypeName = weapInfoSlot |> get_string("reserveAmmoTemplate", "")
      human_weap__reserveAmmoPropIds[i] = resvAmmoTypeName != "" ? int(ecs_hash(resvAmmoTypeName)) : -1


[es(track=human_weap__mortarMode)]
def switch_to_mortar_mode_es(evt : Event;
                             human_weap__mortarMode : bool;
                             var human_weap__enableClampVertAimAngle : bool&)
  human_weap__enableClampVertAimAngle = !human_weap__mortarMode


[es(on_appear)]
def init_radio_slots_es(evt : Event;
                        radio__unequippedSlotName : string;
                        radio__equippedSlotName : string;
                        var radio__unequippedSlotId : int&;
                        var radio__equippedSlotId : int&)
  radio__unequippedSlotId = animchar_getSlotId(radio__unequippedSlotName)
  radio__equippedSlotId = animchar_getSlotId(radio__equippedSlotName)


[es(tag=gameClient)]
def human_weap_switch_to_first_weap_with_ammo(evt : CmdSwitchToFirstWeapWithAmmo;
                                              human_weap__gunEids : EidList;
                                              var human_net_phys : HumanActor)
  switch_to_first_weap_with_ammo(human_weap__gunEids, human_net_phys.phys)
