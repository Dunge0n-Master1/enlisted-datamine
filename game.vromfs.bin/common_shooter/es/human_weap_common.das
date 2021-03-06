module human_weap_common shared
require ecs
require common_shooter.events_common_shooter
require common_shooter.es.grenade_thrower_common
require game.es.events
require game.events_game
require game.utils.animchar
require inventory
require HumanPhys
require DaWeaponProps
require DaWeapons
require DagorSystem
require Action
require EnlistedWeapon
require EnlistedHuman
require EnlistedNet
require Gun
require AnimV20


def human_weap_switch_to_slot(eid : EntityId;
                              gun_eid : EntityId;
                              alternative : bool)
  query(gun_eid) <| $ [es] (gun_attach__mainSlotId : int;
                            gun_attach__altSlotId : int = -1;
                            var slot_attach__slotId : int&)
    let slot = alternative ? gun_attach__altSlotId : gun_attach__mainSlotId
    anim_attach(slot_attach__slotId, eid, slot, gun_eid)
    sendEvent(eid, [[EventOnSelectWeap curr_gun_slot_id=slot]])


def clear_throw_mode(eid : EntityId;
                     gun_eid : EntityId;
                     human_weap__gunEids : EidList;
                     var human_weap__throwMode : bool&;
                     var phys : HumanPhys)
  human_weap__throwMode = false
  let curGun = phys.currentState.weapEquipState.curSlot
  if curGun != HUWeaponSlots EWS_GRENADE // Fast throw
    sendEvent(gun_eid, [[CmdWeapAttach toEid=eid, isAttached=false, slotId=int(curGun)]])
    if int(curGun) < length(human_weap__gunEids)
      human_weap_switch_to_slot(eid, human_weap__gunEids[int(curGun)], false)
    phys.currentState.weapEquipState.curState = HUWeaponEquipState EES_EQUIPED
    query(gun_eid) <| $ [es] (var gun__curShellId : ShellPropIds;
                              var gun__ammo : int&)
      if gun__ammo > 0
        gun__ammo = 0
        gun__curShellId = ShellPropIds()
  elif !take_grenade_in_hand(eid, human_weap__gunEids, phys)
    switch_to_first_weap_with_ammo(human_weap__gunEids, phys)


def set_cur_ammo_num(gun_eid : EntityId; num : int)
  if num > 0
    query(gun_eid) <| $ [es] (gun__owner : EntityId;
                              gun__shell_prop_ids : GunShellPropIds;
                              var gun__curShellId : ShellPropIds)
      if int(gun__curShellId.shellId) < 0
        gun__curShellId = gun__shell_prop_ids[0]
      sendEventImmediate(gun_eid, [[CmdLoadAmmo ammoNum=num]])
      reload_projectile(gun__owner, gun_eid)
  else
    sendEventImmediate(gun_eid, [[CmdUnloadAmmo unloadManually=false]])


def human_gun_mod_reset_custom_props(var custom_props : Object)
  if custom_props |> has("itemEid")
    custom_props |> set("itemEid", INVALID_ENTITY_ID)


def human_gun_from_custom_props(var custom_props : Object;
                                gun_eid : EntityId)
  var ammoHolderEid = INVALID_ENTITY_ID
  if custom_props |> has("itemEid")
    ammoHolderEid = custom_props["itemEid"] |> get_Eid() ?? INVALID_ENTITY_ID
  if custom_props |> has("ammoCount")
    set_cur_ammo_num(gun_eid, custom_props["ammoCount"] |> get_int() ?? 0)
  var isGun = false
  query(gun_eid) <| $ [es(REQUIRE=gun)] (var gun__curShellId : ShellPropIds;
                                         var gun__ammoHolderEid : EntityId&)
    isGun = true
    if custom_props |> has("shellPropsId")
      let shellPropsIdContainer = custom_props["shellPropsId"]
      if shellPropsIdContainer != null
        let shellPropsId = *shellPropsIdContainer |> get_shell_props_ids()
        if shellPropsId != null
          gun__curShellId = *shellPropsId
    gun__ammoHolderEid = ammoHolderEid
  if !isGun
    // Not a gun, ownership not passed, destroy ammo holder.
    destroyEntity(ammoHolderEid)

  human_gun_mod_reset_custom_props(custom_props)


def human_gun_mod_from_custom_props(var custom_props : Object;
                                    mod_eid : EntityId)
  human_gun_from_custom_props(custom_props, mod_eid)


struct GunUpdateCtx
  dt : float
  atTime : float
  isForReal : bool
  eid : EntityId
  isDowned : bool
  isThrowingAllowed : bool
  shotDeviationMult : float
  rotationShotSpreadDecrMult : float
  aimingAfterFireMult : float
  boltActionMult : float
  shotDeviationAdd : float
  fastThrowExclusive : bool
  deviationBufferSizeMult : float


def human_weap_gun_update(var human_net_phys : HumanActor;
                          var human_weap__gunEids : EidList;
                          var human_weap__throwMode : bool&;
                          ctx : GunUpdateCtx;
                          transform : float3x4;
                          gun_dir : float3;
                          gun_shoot_dir : float3;
                          phys_transform : float3x4;
                          ct : HumanControlState;
                          human_use_object__selectedObject : EntityId?;
                          human_unarmed__active : bool;
                          human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID)
  assume phys = human_net_phys.phys
  let selectedGun = determine_current_weapon_slot(ctx.atTime, human_net_phys)
  var curGun = selectedGun

  let allowShootingNoAttach = is_human_allowed_shooting(ctx.eid) && !human_attached_gun__attachedGunEid
  let isHctShootSet = ct |> is_control_bit_set(HumanPhysControlType HCT_SHOOT)
  let grenadeSlotEid = human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)]
  var hasGrenade = false
  query(grenadeSlotEid) <| $ [es] (gun__totalAmmo : int = 0;
                                   gun__ammo : int = 0)
    hasGrenade = gun__totalAmmo > 0 || gun__ammo > 0

  if (ct |> is_control_bit_set(HumanPhysControlType HCT_THROW_BACK) && ctx.isForReal &&
     !human_weap__throwMode && allowShootingNoAttach && curGun != HUWeaponSlots EWS_GRENADE)
    var grenadeEid = INVALID_ENTITY_ID
    if is_server()
      grenadeEid = find_rethrowable_grenade(ctx.eid)
    elif human_use_object__selectedObject != null
      grenadeEid = *human_use_object__selectedObject
    if grenadeEid != INVALID_ENTITY_ID
      human_weap__throwMode = throw_grenade_away(ctx.eid, grenadeEid, human_weap__gunEids)
      if is_server() && !human_weap__throwMode
        send_net_event(ctx.eid, [[HumanWeapThrowBackAbort]])

  var reloadGrenade = false
  var isFastThrow = false
  if ctx.isForReal && ctx.isThrowingAllowed && hasGrenade && allowShootingNoAttach
    let isFastThrowReq = ct |> human_control_state_is_throw_state_set(HumanControlThrowSlot HCTS_SLOT0)
    if isFastThrowReq && ctx.fastThrowExclusive && !human_weap__throwMode && curGun != HUWeaponSlots EWS_GRENADE
      human_weap__throwMode = true
      let gunEid = human_weap__gunEids[int(curGun)]
      human_weap_switch_to_slot(ctx.eid, gunEid, true)
      reloadGrenade = true
    let isExtendedFastThrowReq = ct |> is_control_bit_set(HumanPhysControlType HCT_THROW)
    if isExtendedFastThrowReq && !ctx.fastThrowExclusive && !human_weap__throwMode && grenadeSlotEid != INVALID_ENTITY_ID
      let prevAmmoType = get_int(grenadeSlotEid, "gun__wishAmmoItemType") ?? INVALID_ITEM_ID
      var newAmmoType = 0
      human_weap__throwMode = search_grenade_for_fast_throw(newAmmoType, ctx.eid, grenadeSlotEid, prevAmmoType, ct)
      if human_weap__throwMode
        query(grenadeSlotEid) <| $ [es(REQUIRE=gun)] (var gun__wishAmmoItemType : int&)
          gun__wishAmmoItemType = newAmmoType
        human_weap_switch_to_slot(ctx.eid, grenadeSlotEid, true)

      reloadGrenade = human_weap__throwMode
      if is_server() && reloadGrenade && prevAmmoType != (get_int(grenadeSlotEid, "gun__wishAmmoItemType") ?? INVALID_ITEM_ID)
        let obtainOwnedProjectileEntity = obtain_owned_projectile_entity(ctx.eid, HUWeaponSlots EWS_NUM)
        destroyEntity(obtainOwnedProjectileEntity)
    isFastThrow = (isFastThrowReq || isExtendedFastThrowReq) && human_weap__throwMode
    if (!isFastThrow && curGun == HUWeaponSlots EWS_GRENADE && human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)] != INVALID_ENTITY_ID
        && !human_weap__throwMode && isHctShootSet && !ctx.isDowned)
      human_weap__throwMode = true
      reloadGrenade = true

  if reloadGrenade
    if reload_impl(ctx.eid, int(HUWeaponSlots EWS_GRENADE), ReloadAmmoMode CONSUME)
      // Creating the projectile both on the server and the client so that the client will see the projectile in hand immediately
      let projectileEid = reload_projectile(ctx.eid, human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)])

      if !is_server()
        // Storing the projectile eid so that the projectile can be destroyed later when the server's projectile arrive
        query(ctx.eid) <| $ [es] (var human_weap__localProjectileEid : EntityId&)
          destroyEntity(human_weap__localProjectileEid)
          human_weap__localProjectileEid = projectileEid

  curGun = human_weap__throwMode ? HUWeaponSlots EWS_GRENADE : curGun
  let gunEid = human_weap__gunEids[int(curGun)]
  // overrideGunEid is gun eid or subsidiary gun, if activated.
  var overrideGunEid = gunEid
  query(gunEid) <| $ [es] (subsidiaryGunEid : EntityId)
    overrideGunEid = subsidiaryGunEid

  var wgun : Gun? = null
  var gunDev : GunDeviation? = null
  var gunAmmo = 0
  var grenadeThrower : GrenadeThrower? = null
  var defaultInit = false
  if curGun == HUWeaponSlots EWS_MELEE
    if !has(gunEid, "melee_weapon__propsId")
      return
  elif curGun == HUWeaponSlots EWS_GRENADE
    query(gunEid) <| $ [es] (grenade_thrower : GrenadeThrower?)
      grenadeThrower = grenade_thrower
    if grenadeThrower == null
      return
    defaultInit = true
  else
    defaultInit = true

  if defaultInit
    query(overrideGunEid) <| $ [es] (gun : Gun?;
                                     gun_deviation : GunDeviation?;
                                     gun__ammo : int = 0)
      wgun = gun
      gunDev = gun_deviation
      gunAmmo = gun__ammo
    if wgun == null && !has(gunEid, "itemInWeaponSlot")
      return

  if gunDev != null && ctx.isForReal
    *gunDev |> gun_deviation_getAppliedCT() <| $(var gunDevCT : GunDeviationInput#)
      gunDevCT.bufferSizeMult = ctx.deviationBufferSizeMult
      gunDevCT.tauMult = ctx.shotDeviationMult
      gunDevCT.rotationShotSpreadDecrMult = ctx.rotationShotSpreadDecrMult
      gunDevCT.aimingAfterFireMult = ctx.aimingAfterFireMult
      gunDevCT.movement = phys.currentState.velocity.xz
      gunDevCT.minExtraDev = lerp(get_float(overrideGunEid, "gun__deviationInFireReady") ?? 0.0, 0.0,
                                  phys.currentState.aimPosition) + ctx.shotDeviationAdd

  var needsInterruptActions = false
  var shoot = ((human_weap__throwMode
    ? isFastThrow || ct |> is_control_bit_set(HumanPhysControlType HCT_THROW_BACK) || isHctShootSet
    : (isHctShootSet && allowShootingNoAttach)) && !ctx.isDowned)

  if shoot
    query(ctx.eid) <| $ [es] (human_inventory__entityToUse : EntityId;
                              human_sec_anim__play : bool = false;
                              human_weap__reloadFinishTime : float = -1.0;
                              human_weap__weapModActivateStartTime : float = -1.0;
                              building_action__target : EntityId = INVALID_ENTITY_ID)
      if human_sec_anim__play
        logerr("sec anim active in human_weap_gun_update with HCT_SHOOT set")
      if human_inventory__entityToUse != INVALID_ENTITY_ID
        if has(human_inventory__entityToUse, "item__ignoreLmbInterrupt")
          shoot = false
        else
          logerr("active human_inventory.entityToUse in human_weap_gun_update with HCT_SHOOT set")

      if !human_weap__throwMode
        shoot = ctx.atTime > human_weap__reloadFinishTime && shoot
        shoot = human_weap__weapModActivateStartTime < 0.0 && shoot
      elif ctx.isForReal
        query(gunEid) <| $ [es] (grenade_thrower__projectileEntity : EntityId;
                                 shell__autoThrowCountdown : float = 1.2)
          let explTime = get_float(grenade_thrower__projectileEntity, "shell__explTime") ?? 0.0
          if shell__autoThrowCountdown > 0.0 && explTime > 0.0 && ctx.atTime > explTime - shell__autoThrowCountdown
            shoot = false

      query(gunEid) <| $ [es] (blockShoot : bool;
                               blockShootReason : string = "")
        if blockShoot && wgun != null && !wgun.appliedControls.wishShoot
          broadcastEvent([[EventOnGunBlocksShoot reason=blockShootReason]])
        shoot = !blockShoot && shoot

      let isMeleeWeapon = (curGun == HUWeaponSlots EWS_MELEE) || human_unarmed__active
      let buildingAction = building_action__target != INVALID_ENTITY_ID
      let isBuildingToolGun = has(gunEid, "previewEid") && buildingAction
      let itemGuninstallationInProgress = get_bool(gunEid, "placeable_item__inProgress") ?? false
      needsInterruptActions = shoot && !isMeleeWeapon && !isBuildingToolGun && !itemGuninstallationInProgress

  shoot = !human_unarmed__active && shoot

  if (wgun != null && gunAmmo == 0 && ctx.isForReal && !wgun.appliedControls.shoot && shoot &&
      phys.currentState.weapEquipState.curState == HUWeaponEquipState EES_EQUIPED && !isFastThrow)
    // Check ammo of a subsidiary gun, if activated. Again, we might want to
    // change this if we're gonna have subsidiary guns that can fire together
    // with main gun.
    query(overrideGunEid) <| $ [es(REQUIRE_NOT=doNotHideWeapWithoutAmmo)] (gun__totalAmmo : int = 0)
      if gun__totalAmmo == 0
        var bestSlot = selectedGun
        var i = 0
        while i < int(HUWeaponSlots EWS_NUM) && bestSlot == selectedGun
          if i == int(HUWeaponSlots EWS_GRENADE) || i == int(selectedGun)
            ++i
            continue
          query(human_weap__gunEids[i]) <| $ [es] (gun__totalAmmo : int = 0; gun__ammo : int = 0)
            if gun__totalAmmo > 0 || gun__ammo > 0
              bestSlot = HUWeaponSlots(i)
          ++i
        phys.producedCT |> set_chosen_weapon(bestSlot)

  if ct |> is_control_bit_set(HumanPhysControlType HCT_RELOAD) && ctx.isForReal && !isFastThrow
    // If we have subsidiary gun attached, reload it instead.
    // we can pick which gun to reload with some other key m.b. ?
    sendEvent(ctx.eid, [[CmdRequestReload atTime=ctx.atTime, gunEid=overrideGunEid]])

  using() <| $(var gctrl : GunControls#)
    gctrl.shoot = shoot
    gctrl.boltActionMult = ctx.boltActionMult
    gctrl.wishShoot = isHctShootSet

    if ct |> human_control_state_get_shootPos_packed() > 0u
      let worldShootPos = phys_transform * ct |> human_control_state_unpack_shootPos()
      using(gun_dir, gun_shoot_dir, human_net_phys.phys.currentState.velocity, worldShootPos) <| $(var gloc : GunLocation#)
        sendEventImmediate(gunEid, [[CmdWeapPhysUpdate
                                     owner=ctx.eid,
                                     atTime=ctx.atTime,
                                     dt=ctx.dt,
                                     isForReal=ctx.isForReal,
                                     slotId=int(curGun),
                                     gctrl := gctrl,
                                     gloc := gloc]])
    else
      using(gun_dir, gun_shoot_dir, human_net_phys.phys.currentState.velocity, transform, phys_transform) <| $(var gloc : GunLocation#)
        sendEventImmediate(gunEid, [[CmdWeapPhysUpdate
                                     owner=ctx.eid,
                                     atTime=ctx.atTime,
                                     dt=ctx.dt,
                                     isForReal=ctx.isForReal,
                                     slotId=int(curGun),
                                     gctrl := gctrl,
                                     gloc := gloc]])

  if needsInterruptActions
    // Call 'interrupt_actions' after CmdWeapPhysUpdate, cause it in turn may trigger actions
    // and that can cause jittery behavior, like action is always starting and interrupting in a loop.
    interrupt_actions(ctx.eid)

  update_reload(ctx.eid, ctx.atTime, ctx.dt)

  if (human_weap__throwMode && ctx.isForReal && grenadeThrower != null &&
      grenadeThrower.state == GrenadeThrowState GTS_READY && !ctx.isDowned)
    clear_throw_mode(ctx.eid, gunEid, human_weap__gunEids, human_weap__throwMode, phys)


def obtain_owned_projectile_entity(eid : EntityId;
                                   slot : HUWeaponSlots)
  var projectileEid = INVALID_ENTITY_ID
  query(eid) <| $ [es] (human_weap__throwMode : bool;
                        human_weap__currentGunSlot : int = -1;
                        human_weap__gunEids : EidList)
    let currentGunSlot = int(slot) < int(HUWeaponSlots EWS_NUM) ? int(slot) : human_weap__currentGunSlot
    let gunEidsCount = length(human_weap__gunEids)
    if human_weap__throwMode && int(HUWeaponSlots EWS_GRENADE) >= gunEidsCount
      return
    if !human_weap__throwMode && uint(currentGunSlot) >= uint(gunEidsCount)
      return

    let gunEid = human_weap__gunEids[human_weap__throwMode ? int(HUWeaponSlots EWS_GRENADE) : currentGunSlot]
    query(gunEid) <| $ [es] (var grenade_thrower__projectileEntity : EntityId&)
      projectileEid = obtain_grenade_thrower_projectile_entity(grenade_thrower__projectileEntity)

  return projectileEid


def take_grenade_in_hand(eid : EntityId;
                         human_weap__gunEids : EidList;
                         var phys : HumanPhys)
  let grenadeSlotEid = human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)]
  var hasGrenade = false
  query(grenadeSlotEid) <| $ [es] (gun__totalAmmo : int;
                                   gun__ammo : int)
    hasGrenade = gun__totalAmmo > 0 || gun__ammo > 0

  if !hasGrenade
    return false
  let slot_id = HUWeaponSlots EWS_GRENADE
  if reload_impl(eid, int(slot_id), ReloadAmmoMode INFINITE) // do not consume ammo, just setup shellID
    let obtainOwnedProjectileEntity = obtain_owned_projectile_entity(eid, HUWeaponSlots EWS_GRENADE)
    if is_server()
      destroyEntity(obtainOwnedProjectileEntity)

    // Creating the projectile both on the server and the client so that the client will see the projectile in hand immediately
    let newProjectileEid = reload_projectile(eid, human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)])

    if !is_server()
      // Storing the projectile eid so that the projectile can be destroyed later when the server's projectile arrive
      query(eid) <| $ [es] (var human_weap__localProjectileEid : EntityId&)
        destroyEntity(human_weap__localProjectileEid)
        human_weap__localProjectileEid = newProjectileEid

    phys.producedCT |> set_chosen_weapon(HUWeaponSlots EWS_GRENADE)
    return true
  return false


def switch_to_first_weap_with_ammo(human_weap__gunEids : EidList;
                                   var phys : HumanPhys)
  var choosenSlot = -1
  for i in range(int(HUWeaponSlots EWS_NUM))
    query(human_weap__gunEids[i]) <| $ [es] (gun__totalAmmo : int;
                                             gun__ammo : int)
      if i != int(HUWeaponSlots EWS_GRENADE) && (gun__totalAmmo > 0 || gun__ammo > 0)
        choosenSlot = i

    if choosenSlot > -1
      phys.producedCT |> set_chosen_weapon(HUWeaponSlots(choosenSlot))
      break

  return choosenSlot > -1