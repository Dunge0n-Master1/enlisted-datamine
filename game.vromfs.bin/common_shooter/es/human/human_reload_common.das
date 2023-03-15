module human_reload_common shared
require ecs
require net
require math
require inventory
require DaWeaponProps
require WeapHelpers
require EnlistedWeapon
require DagorMath
require Gun
require game.es.events


enum ReloadAmmoMode
  CONSUME = 0
  INFINITE = 1


struct AmmoItemForGunResult
  ammoCount : int = 0
  itemIndex : int = -1
  haveDiffAmmoType : bool = false
  singleReload : bool = false
  availableAmmoCount : int = 0
  ammoPropsId : int = 0
  singleReloadAmmoCount : int = 1


struct AmmoData
  itemIndex : int
  availableAmmoCount : int
  maxShells : int
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
  var maxShellsCount = 0
  var totalAmmoCount = 0
  var maxAmmoCount = 0
  var isShell = false
  query(gun_eid) <| $ [es] (gun__ammoHolderIds : IntList;
                            gun__shell_prop_ids : GunShellPropIds;
                            gun__maxAmmo : int)
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
          maxShellsCount = max(maxShellsCount, gun__maxAmmo)
          maxAmmoCount = max(maxAmmoCount, availableAmmoCount)
          totalAmmoCount += availableAmmoCount
          ammoData |> push([[AmmoData
            itemIndex = i,
            availableAmmoCount = availableAmmoCount,
            maxShells = gun__maxAmmo,
            ammoPropsId = ammo_holder__id]])

        if shell_props != null && res.ammoCount <= 1 && is_shell_for_gun(*shell_props, gun__shell_prop_ids)
          res.itemIndex = i
          res.ammoCount = 1
          res.availableAmmoCount = res.ammoCount
          res.singleReload = false
          res.ammoPropsId = ammo_holder__id
          isShell = true

  if isShell
    return res

  if singleReload.maxAmmo > 0
    res.singleReload = (maxShellsCount - num_ammo) <= singleReload.maxAmmo || totalAmmoCount <= num_ammo || maxAmmoCount < num_ammo

  for ammo in ammoData
    res.haveDiffAmmoType = true
    var ammoCount = ammo.availableAmmoCount
    var match = ammoCount > res.ammoCount
    if res.singleReload
      res.singleReloadAmmoCount = min(ammo.availableAmmoCount, singleReload.ammoCount)
      ammoCount = min(ammo.maxShells, ammoCount + num_ammo)
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

    shell_props = gun__shell_prop_ids[0]
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
