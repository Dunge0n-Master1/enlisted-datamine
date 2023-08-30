module human_reload_common shared
require ecs
require net
require math
require inventory
require DaWeaponProps
require WeapHelpers
require DngWeapon
require DagorMath
require DagorSystem
require Gun
require game.es.events
require enlisted.events_enlisted


enum ReloadAmmoMode
  CONSUME = 0
  INFINITE = 1


enum GunReloadStyle
  RELOAD_STYLE_SIMPLE
  RELOAD_STYLE_ALT
  RELOAD_STYLE_ALT_JAMMED
  RELOAD_STYLE_JAMMED
  RELOAD_STYLE_DUAL_MAG


struct AmmoItemForGunResult
  ammoCount : int = 0
  itemIndex : int = -1
  singleReload : bool = false
  availableAmmoCount : int = 0
  ammoPropsId : int = 0
  singleReloadAmmoCount : int = 1


struct AmmoData
  itemIndex : int
  availableAmmoCount : int
  ammoPropsId : int


struct SingleReloadInfo
  maxAmmo : int = 0
  ammoCount : int = 1
  isSingle : bool = false


def get_gun_single_reload_info(gun_eid : EntityId; num_ammo : int)
  var reloadInfo = SingleReloadInfo()

  query(gun_eid) <| $ [es] (reload__singleBullet : Tag const?;
                            reload__singleIfNotEmpty : Tag const?;
                            reload__singleReloadAmmoCount = 1;
                            reload__singleReloadMaxAmmo = 0)
    reloadInfo.ammoCount = reload__singleReloadAmmoCount

    if reload__singleBullet != null
      reloadInfo.isSingle = true
    elif reload__singleIfNotEmpty != null && num_ammo > 0
      if reload__singleReloadMaxAmmo <= 0
        reloadInfo.isSingle = true
      else
        reloadInfo.maxAmmo = reload__singleReloadMaxAmmo
  return reloadInfo


def find_ammo_for_gun(gun_eid : EntityId;
                      item_container : EidList;
                      wish_ammo_item_id : int;
                      num_ammo : int)
  var res = AmmoItemForGunResult()
  let singleReload = get_gun_single_reload_info(gun_eid, num_ammo)
  res.singleReload = singleReload.isSingle

  var ammoData : array<AmmoData>
  var gunMaxAmmo = 0
  var totalAmmoCount = 0
  var bestHolderAmmoCount = 0
  var isShell = false
  query(gun_eid) <| $ [es] (gun__ammoHolderIds : IntList;
                            gun__shell_prop_ids : GunShellPropIds;
                            gun__maxAmmo : int)
    gunMaxAmmo = max(gunMaxAmmo, gun__maxAmmo)
    // try to load gun__ammoHolderIds[0] firstly
    var defaultAmmoHolderItemId = INVALID_ITEM_ID
    if wish_ammo_item_id == INVALID_ITEM_ID && length(gun__ammoHolderIds) > 1
      for itemEid in item_container
        query(itemEid) <| $ [es] (item__id : int = INVALID_ITEM_ID;
                                  ammo_holder__id : int = INVALID_ITEM_ID)
          if ammo_holder__id == gun__ammoHolderIds[0]
            defaultAmmoHolderItemId = item__id

        if defaultAmmoHolderItemId != INVALID_ITEM_ID
          break

    for i, itemEid in iter_range(item_container), item_container
      query(itemEid) <| $ [es] (item__id : int;
                                ammo_holder__id : int = INVALID_ITEM_ID;
                                ammo_holder__ammoCount : int = -1;
                                shell_props : ShellPropIds const? = null)
        if wish_ammo_item_id != INVALID_ITEM_ID && item__id != wish_ammo_item_id
          return
        if defaultAmmoHolderItemId != INVALID_ITEM_ID && item__id != defaultAmmoHolderItemId
          return

        if ammo_holder__id != INVALID_ITEM_ID && is_ammo_for_gun(ammo_holder__id, gun__ammoHolderIds)
          let availableAmmoCount = ammo_holder__ammoCount >= 0 ? ammo_holder__ammoCount : gun__maxAmmo

          bestHolderAmmoCount = max(bestHolderAmmoCount, availableAmmoCount)
          totalAmmoCount += availableAmmoCount

          ammoData |> push([[AmmoData
            itemIndex = i,
            availableAmmoCount = availableAmmoCount,
            ammoPropsId = ammo_holder__id]])

        if shell_props != null && is_shell_for_gun(*shell_props, gun__shell_prop_ids)
          res.itemIndex = i
          res.ammoCount = 1
          res.availableAmmoCount = 1
          res.singleReload = false
          res.ammoPropsId = ammo_holder__id
          isShell = true

  if isShell
    return res

  if singleReload.maxAmmo > 0
    res.singleReload = (gunMaxAmmo - num_ammo) <= singleReload.maxAmmo || totalAmmoCount <= num_ammo || bestHolderAmmoCount < num_ammo

  for ammo in ammoData
    var ammoCount = ammo.availableAmmoCount
    var match = ammoCount > res.ammoCount
    if res.singleReload
      res.singleReloadAmmoCount = min(ammo.availableAmmoCount, singleReload.ammoCount)
      ammoCount = min(gunMaxAmmo, ammoCount + num_ammo)
      match = (ammo.availableAmmoCount > 0 &&
              (res.availableAmmoCount == 0 || (ammo.availableAmmoCount >= singleReload.ammoCount && ammo.availableAmmoCount < res.availableAmmoCount)))

    if match
      res.itemIndex = ammo.itemIndex
      res.availableAmmoCount = ammo.availableAmmoCount
      res.ammoCount = ammoCount
      res.ammoPropsId = ammo.ammoPropsId

  return res

def find_ammo_for_gun(gun_eid : EntityId;
                      item_container : EidList;
                      wish_ammo_item_id : int;
                      num_ammo : int;
                      cb : block<(res : AmmoItemForGunResult) : void>)
  cb |> invoke(find_ammo_for_gun(gun_eid, item_container, wish_ammo_item_id, num_ammo))


def update_reload(human_eid : EntityId; at_time : float; dt : float)
  var partialReload = -1
  var isDualMagReload = false
  var reloadGunEid = INVALID_ENTITY_ID
  query(human_eid) <| $ [es] (human_weap__reloadStartTime : float;
                              human_weap__reloadFinishTime : float;
                              human_weap__reloadAtTime : float;
                              human_weap__reloadDelayTime : float;
                              human_weap__reloadGunEid : EntityId;
                              human_weap__isDualMagReload : bool;
                              human_weap__singleReload : bool = false;
                              entity_mods__reloadMult : float = 1.0f;
                              human_weap__singleReloadAmmoCount : int = 1;
                              var human_weap__isReloadRequested : bool&;
                              var human_weap__reloadPrevTime : float&)
    if human_weap__singleReload
      query(human_weap__reloadGunEid) <| $ [es] (gun_anim__reloadStyle : int;
                                                 single_reload__prepareTime : float = 0.1f;
                                                 single_reload__loopTime : float = 1.0f;
                                                 single_reload__postTime : float = 0.1f;
                                                 single_reload__jammedPostTime : float = 1.f)
        let isJammed = gun_anim__reloadStyle == int(GunReloadStyle RELOAD_STYLE_JAMMED)
        let postTime = (isJammed ? single_reload__jammedPostTime : single_reload__postTime) * entity_mods__reloadMult
        let prepareTime = single_reload__prepareTime * entity_mods__reloadMult
        let loopTime = single_reload__loopTime * entity_mods__reloadMult

        let loopStart = human_weap__reloadStartTime + prepareTime
        let loopEnd = human_weap__reloadAtTime - postTime
        if at_time - dt > loopStart && at_time <= loopEnd + loopTime * 0.5f
          let prevLoop = floori(safediv(human_weap__reloadPrevTime - loopStart, loopTime))
          let currentLoop = floori(safediv(at_time - loopStart, loopTime))
          if currentLoop > prevLoop
            partialReload = human_weap__singleReloadAmmoCount
            reloadGunEid = human_weap__reloadGunEid
    else
      isDualMagReload = human_weap__isDualMagReload
      let finishTime = human_weap__reloadFinishTime + human_weap__reloadDelayTime
      if at_time > finishTime && human_weap__isReloadRequested
        reloadGunEid = human_weap__reloadGunEid
        human_weap__isReloadRequested = false
    human_weap__reloadPrevTime = at_time

  if reloadGunEid != INVALID_ENTITY_ID
    query(human_eid) <| $ [es] (var itemContainer : EidList&;
                                human_weap__reloadMode : int = int(ReloadAmmoMode CONSUME))
      let mode = human_weap__reloadMode == 0 ? ReloadAmmoMode CONSUME : ReloadAmmoMode INFINITE // this should not be a thing, just ReloadAmmoMode(some int) should be a thing
      reload_impl(human_eid, reloadGunEid, itemContainer, mode, partialReload, isDualMagReload)


def reload_impl(eid : EntityId; slot_id : int; mode : ReloadAmmoMode)
  var isSuccess = false
  query(eid) <| $ [es] (human_weap__gunEids : EidList;
                        var itemContainer : EidList&)
    isSuccess = reload_impl(eid, human_weap__gunEids[slot_id], itemContainer, mode, -1)
  return isSuccess


def reload_impl(owner : EntityId;
                gun_eid : EntityId;
                var item_container : EidList&;
                mode : ReloadAmmoMode;
                partial_reload : int;
                is_dual_mag_reload : bool = false)
  var isOk = false
  query(gun_eid) <| $ [es] (gun__shell_prop_ids : GunShellPropIds;
                            gun__ammoHolderEid : EntityId;
                            gun__ammo : int;
                            gun__maxAmmo : int;
                            gun__wishAmmoItemType : int;
                            single_reload__postTime : float = 0.1f;
                            gun__reloadFinishMult : float = 0.9f;
                            var shell_props aka gun_shell_props : ShellPropIds&;
                            var gun__curShellId : ShellPropIds&;
                            var gun__isDualMagReady : bool?)
    var ammoForGun = find_ammo_for_gun(gun_eid, item_container, gun__wishAmmoItemType, gun__ammo)
    if ammoForGun.itemIndex < 0
      return

    isOk = true

    let itemEid = item_container[ammoForGun.itemIndex]

    shell_props = length(gun__shell_prop_ids) > 0 ? gun__shell_prop_ids[0] : ShellPropIds()
    query(itemEid) <| $ [es] (shell_props aka item_shell_props : ShellPropIds)
      gun_shell_props = item_shell_props
    gun__curShellId = shell_props

    var prevAmmoCount = gun__ammo
    var curAmmoCount = partial_reload > 0 ? min(ammoForGun.ammoCount, prevAmmoCount + partial_reload) : ammoForGun.ammoCount
    if partial_reload < 0 && has(itemEid, "ammo_holder__boxedAmmo")
      item_container |> erase(ammoForGun.itemIndex)
      let ammoToReuse = min(gun__maxAmmo - curAmmoCount, prevAmmoCount)
      prevAmmoCount -= ammoToReuse
      curAmmoCount += ammoToReuse
      while curAmmoCount < gun__maxAmmo
        var additionalAmmoForGun = find_ammo_for_gun(gun_eid, item_container, ammoForGun.ammoPropsId, curAmmoCount)
        if additionalAmmoForGun.itemIndex < 0
          break
        let additionalAmmoBox = item_container[additionalAmmoForGun.itemIndex]
        if !has(additionalAmmoBox, "ammo_holder__boxedAmmo")
          break
        let ammoToFill = min(gun__maxAmmo - curAmmoCount, additionalAmmoForGun.ammoCount)
        curAmmoCount += ammoToFill
        additionalAmmoForGun.ammoCount -= ammoToFill
        if is_server()
          item_container |> erase(additionalAmmoForGun.itemIndex)
          put_ammo_to_container(additionalAmmoForGun.ammoCount, additionalAmmoBox, owner)
          destroyEntity(additionalAmmoBox)
      item_container |> push(itemEid)
      ammoForGun.itemIndex = length(item_container) - 1

    if gun__isDualMagReady != null
      *gun__isDualMagReady = !is_dual_mag_reload

    sendEventImmediate(gun_eid, [[CmdLoadAmmo ammoNum=curAmmoCount]])

    var rest = 0
    if is_server()
      if ammoForGun.ammoPropsId != INVALID_ITEM_ID
        set_ammo_holder(gun_eid, itemEid)
      if mode == ReloadAmmoMode CONSUME
        item_container |> erase(ammoForGun.itemIndex)
        destroyEntity(gun__ammoHolderEid)
        rest = !ammoForGun.singleReload ? prevAmmoCount : ammoForGun.availableAmmoCount + prevAmmoCount - curAmmoCount
        if rest > 0 && ammoForGun.ammoPropsId != INVALID_ITEM_ID
          put_ammo_to_container(rest, itemEid, owner)
        elif ammoForGun.ammoPropsId == INVALID_ITEM_ID
          destroyEntity(itemEid)
      elif itemEid != gun__ammoHolderEid
        // We have infinite ammo holders and just changed ammo holder, destroy old one.
        destroyEntity(gun__ammoHolderEid)

    if ammoForGun.singleReload
      query(owner) <| $ [es] (human_weap__reloadPrevTime : float;
                              itemContainer : EidList;
                              var human_weap__reloadFinishTime : float&;
                              var human_weap__reloadAtTime : float&)
        if rest == 0
          let ammoForGun2 = find_ammo_for_gun(gun_eid, itemContainer, INVALID_ITEM_ID, gun__ammo)
          rest = ammoForGun2.ammoCount

        if rest != 0
          return

        let atTime = human_weap__reloadPrevTime
        human_weap__reloadFinishTime = atTime + single_reload__postTime * gun__reloadFinishMult
        human_weap__reloadAtTime = atTime + single_reload__postTime

  return isOk

// ===========================================
// Reload System 2.0 systems
// ===========================================

struct AmmoHolderInfo
  ammo : int = -1
  holderId : int = INVALID_ITEM_ID
  itemContainerId : int = -1


def has_holder_with_enough_bullets(owner : EntityId;
                                   wish_ammo_count : int;
                                   wish_ammo_item_id : int;
                                   allowed_ammo_holders : IntList;
                                   gun_max_ammo : int)
  var hasHolder = false
  query(owner) <| $ [es] (itemContainer : EidList)
    let holderInfo = find_smallest_holder_with_enough_bullets(itemContainer,
                                                              wish_ammo_count,
                                                              wish_ammo_item_id,
                                                              allowed_ammo_holders,
                                                              gun_max_ammo)
    if holderInfo.itemContainerId >= 0
      hasHolder = true

  return hasHolder


def find_smallest_holder_with_enough_bullets(item_container : EidList;
                                             wish_ammo_count : int;
                                             wish_ammo_item_id : int;
                                             allowed_ammo_holders : IntList;
                                             gun_max_ammo : int)
  var holderInfo = AmmoHolderInfo()
  for i, itemEid in iter_range(item_container), item_container
    query(itemEid) <| $ [es] (item__id : int;
                              ammo_holder__id : int = INVALID_ITEM_ID;
                              ammo_holder__ammoCount : int = -1)
      if wish_ammo_item_id != INVALID_ITEM_ID && item__id != wish_ammo_item_id
        return

      if ammo_holder__id != INVALID_ITEM_ID && is_ammo_for_gun(ammo_holder__id, allowed_ammo_holders)
        let availableAmmoCount = ammo_holder__ammoCount >= 0 ? ammo_holder__ammoCount : gun_max_ammo

        if availableAmmoCount >= wish_ammo_count && (availableAmmoCount < holderInfo.ammo || holderInfo.ammo == -1)
          holderInfo.ammo = availableAmmoCount
          holderInfo.itemContainerId = i
          holderInfo.holderId = ammo_holder__id
  return holderInfo


def create_ammo_holder_copy_with_bullets_for_gun(gun_eid : EntityId;
                                                 holder_to_copy_eid : EntityId;
                                                 bullets : int)
  query(holder_to_copy_eid) <| $ [es] (ammo_holder__templateName : string = "")
    if ammo_holder__templateName == ""
      logerr("Can't copy ammo holder {holder_to_copy_eid}<{getEntityTemplateName(holder_to_copy_eid)}> for gun and weapon as ammo_holder__templateName was empty")
      return

    let finalizeCreation <- @ <| (created_holder_eid : EntityId)
      set_ammo_holder(gun_eid, created_holder_eid)

    createEntity(ammo_holder__templateName, finalizeCreation) <| $(init)
      init |> set("ammo_holder__ammoCount", bullets)


// finds ammo holder with least bullets and at least ammo_to_reload
// amount in owner's item_container and puts them into gun_eid.
// used bullets are removed from selected ammo holder
// if selected holder became empty - gets deleted on the server
// !does not change gun's ammo holder
// !if it was not present (gun__ammoHolderEid == INVALID_ENTITY_ID) - creates a new one
def reload_with_bullets(owner : EntityId;
                        var item_container : EidList&;
                        gun_eid : EntityId;
                        ammo_to_reload : int;
                        mode : ReloadAmmoMode)
  var reloaded = false
  query(gun_eid) <| $ [es] (gun__shell_prop_ids : GunShellPropIds;
                            gun__ammoHolderEid : EntityId;
                            gun__ammoHolderIds : IntList;
                            gun__ammo : int;
                            gun__maxAmmo : int;
                            gun__wishAmmoItemType : int;
                            var shell_props aka gun_shell_props : ShellPropIds&;
                            var gun__curShellId : ShellPropIds&)
    let ammoHolderInfo = find_smallest_holder_with_enough_bullets(item_container,
                                                                  ammo_to_reload,
                                                                  gun__wishAmmoItemType,
                                                                  gun__ammoHolderIds,
                                                                  gun__maxAmmo)
    if ammoHolderInfo.itemContainerId < 0
      return

    let itemEid = item_container[ammoHolderInfo.itemContainerId]

    // we are loading in a new shell
    // if item has none - use the first one of the weapon
    gun_shell_props = length(gun__shell_prop_ids) > 0 ? gun__shell_prop_ids[0] : ShellPropIds()
    query(itemEid) <| $ [es] (shell_props aka item_shell_props : ShellPropIds)
      // if an item has one - use that
      gun_shell_props = item_shell_props
    gun__curShellId = shell_props

    // save gun_ammo cause CmdLoadAmmo will change it
    let newAmmoCount = gun__ammo + ammo_to_reload

    sendEventImmediate(gun_eid, [[CmdLoadAmmo ammoNum=newAmmoCount]])

    reloaded = true

    // creation/deletion of an ammo holder can be done by the server only
    // everything else is done on both server and client
    // for now this is important for staged reload so that the client does not wait for ammo holder info replication from the server
    // otherwise client and server might play different animations
    // TODO: this is not great as it can lead to ui ammo counter desync (it's still replicated from the server)
    if gun__ammoHolderEid == INVALID_ENTITY_ID
      if is_server()
        create_ammo_holder_copy_with_bullets_for_gun(gun_eid, itemEid, newAmmoCount)
    else
      query(gun__ammoHolderEid) <| $ [es] (var ammo_holder__ammoCount : int&)
        ammo_holder__ammoCount = newAmmoCount

    // skip updating the holder from which we took ammo = infinite ammo
    if mode == ReloadAmmoMode INFINITE
      return

    query(itemEid) <| $ [es] (var ammo_holder__ammoCount : int&)
      ammo_holder__ammoCount -= ammo_to_reload
      if ammo_holder__ammoCount <= 0
        if is_server()
          destroyEntity(itemEid)
        item_container |> erase(ammoHolderInfo.itemContainerId)
      else
        sendEvent(owner, [[EventUpdatedItemContainer]])

  return reloaded
