module human_weap_common shared
require ecs
require ecs.common
require ecs.safe
require common_shooter.events_common_shooter
require common_shooter.es.grenade_thrower_common
require game.es.events
require game.es.action_common
require game.events_game
require game.utils.net_utils
require game.utils.animchar
require inventory
require HumanPhys
require DaWeaponProps
require DaWeapons
require DagorSystem
require DngWeapon
require DngHuman
require DngNet
require Gun
require AnimV20
require DagorMath
require DagorMathUtils
require WeapHelpers
require common_shooter.es.human.human_reload_common
require RendInst
require Dacoll
require daslib.strings_boost
require game.es.inventory_drop_common
require AnimatedPhys


def reset_weapon_state(var phys : HumanPhys&)
  assume weapEquipState = phys.currentState.weapEquipState
  weapEquipState.progress = 0.
  weapEquipState.curState = HUWeaponEquipState EES_HOLSTERING
  weapEquipState.nextSlot = phys.appliedCT.chosenWeapon

def check_gun_trace(var phys : HumanPhys;
                    gun_tm : float3x4;
                    len_override : float;
                    gun_mat_id : int;
                    max_backoff : float;
                    var backoff : float&)
  assume currentState = phys.currentState
  assume weaponParams = phys.weaponParams[int(currentState.weapEquipState.curSlot)]

  let traceHandle = human_phys_getTraceHandle(phys)
  let gunDir = currentState.gunDir

  backoff = 0.

  if (phys.precompWeaponPos == null ||
      !phys.precompWeaponPos.isLoaded ||
      !weaponParams.exists ||
      currentState.isCrawl ||
      weaponParams.gunLen < 0.05)
    return false

  let gunLen = len_override >= 0. ? len_override : weaponParams.gunLen
  let backupDist = min(0.2, gunLen * 0.5)
  let gunStartPos = gun_tm[3] - gunDir * backupDist

  let gunAimPos = gun_tm * weaponParams.offsAimNode - gunDir * backupDist
  let leftPos = gun_tm * weaponParams.offsCheckLeftNode - gunDir * backupDist
  let rightPos = gun_tm * weaponParams.offsCheckRightNode - gunDir * backupDist
  var t = gunLen + backupDist
  var pmid = -1
  var norm : float3
  var riDesc = RendInstDesc()
  let res = (traceray_normalized(gunStartPos, gunDir, t, pmid, norm, ETF_DEFAULT, riDesc, gun_mat_id, traceHandle) ||
             traceray_normalized(gunAimPos, gunDir, t, pmid, norm, ETF_DEFAULT, riDesc, gun_mat_id, traceHandle) ||
             traceray_normalized(leftPos, gunDir, t, pmid, norm, ETF_DEFAULT, riDesc, gun_mat_id, traceHandle) ||
             traceray_normalized(rightPos, gunDir, t, pmid, norm, ETF_DEFAULT, riDesc, gun_mat_id, traceHandle))
  if !res
    return false
  let backoffAmount = gunLen + backupDist - t
  if backoffAmount <= max_backoff
    backoff = backoffAmount
    return false
  return true

def is_human_allowed_shooting(eid : EntityId; attached_gun_eid : EntityId; human_net_phys : HumanActor) : bool
  assume currentState = human_net_phys.phys.currentState
  let isSprinting = currentState.moveState == HUMoveState EMS_SPRINT
  let isMelee = currentState.weapEquipState.curSlot == HUWeaponSlots EWS_MELEE
  let isGunEquiped = currentState.weapEquipState.curState == HUWeaponEquipState EES_EQUIPED || attached_gun_eid != INVALID_ENTITY_ID
  let isMoving = currentState.moveState != HUMoveState EMS_STAND
  var res = (!(isSprinting && !isMelee) &&
            !currentState |> human_phys_state_get_is_swimming() && isGunEquiped &&
            currentState |> human_phys_state_get_canShoot() &&
            !(currentState |> human_phys_state_get_forceWeaponDown()) &&
            !(currentState.isCrawl && isMoving))
  if !res
    return false
  query(eid) <| $ [es] (isInVehicle : bool = false; isShootingAllowed : bool = true;
                        human_weap__blockAiming : bool = false; human_vehicle__isHoldingGunPassenger : bool = false)
    res = (isShootingAllowed && !human_weap__blockAiming &&
          (!isInVehicle || human_vehicle__isHoldingGunPassenger))
  return res


def is_human_allowed_shooting(eid : EntityId)
  var res = false
  query(eid) <| $ [es] (human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                        human_net_phys : HumanActor)
    res = is_human_allowed_shooting(eid, human_attached_gun__attachedGunEid, human_net_phys)
  return res

def human_weap_clamp_vert_aim_angle(angle : float; interp_quat : quat; limits : float2)
  var pitchBasis : float
  var heading : float
  var bank : float
  quat_to_euler(interp_quat, heading, pitchBasis, bank)
  return clamp(angle, pitchBasis + limits.x, pitchBasis + limits.y)

def apply_gun_angle_offsets(phys : HumanPhys; at_time : float; limits : float2; var angles : float2&)
  assume prevState = phys.previousState
  assume curState  = phys.currentState
  let prevOffset = prevState.breathOffset + prevState.handsShakeOffset + prevState.gunAimOffset
  let curOffset = curState.breathOffset + curState.handsShakeOffset + curState.gunAimOffset
  let interpK = get_phys_interpk_clamped(phys, at_time)

  angles += lerp(prevOffset, curOffset, float2(interpK))
  let interpQuat = slerp(prevState.location.O.quat, curState.location.O.quat, interpK)
  angles.y = human_weap_clamp_vert_aim_angle(angles.y, interpQuat, limits)


def human_weap_get_shoot_tm(eid : EntityId; at_time : float; var out_tm : float3x4&) : bool
  let gun = get_human_gun(eid)
  if gun == null || !is_human_allowed_shooting(eid)
    return false
  var isOk = false
  query(eid) <| $ [es] (human_net_phys : HumanActor)
    isOk = true
    human_gun_get_shoot_tm(*gun, human_net_phys.phys, at_time, out_tm)
  return isOk


def human_weap_get_aim_tm_impl(human_net_phys : HumanActor; at_time : float; apply_offsets : bool; vert_limits : float2) : float3x4
  var gunDir = human_net_phys.phys.producedCT.wishShootDir
  var gunAngles = dir_to_angles(gunDir)
  if apply_offsets
    apply_gun_angle_offsets(human_net_phys.phys, at_time, vert_limits, gunAngles)
  gunDir = angles_to_dir(gunAngles)
  var camPos : float3

  find_query() <| $ [es] (camera__active : bool; transform : float3x4)
    if camera__active
      camPos = transform[3]
    return camera__active

  var outTm : float3x4
  outTm[3] = camPos
  outTm[0] = gunDir
  outTm[2] = normalize(cross(gunDir, float3(0.0, 1.0, 0.0)))
  outTm[1] = normalize(cross(outTm[2], gunDir))
  return outTm


def human_weap_get_aim_tm(eid : EntityId; at_time : float; var out_tm : float3x4&) : bool
  if !has(eid, "watchedByPlr")
    return human_weap_get_shoot_tm(eid, at_time, out_tm)

  if !is_human_allowed_shooting(eid)
    return false

  var isOk = false
  query(eid) <| $ [es] (human_net_phys : HumanActor;
                        human_weap__crawlClampVertAngleRad : float2;
                        human_weap__clampVertAngleRad : float2;
                        human_weap__mortarMode : bool = false;
                        human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID)
    isOk = true
    let applyOffsets = !human_attached_gun__attachedGunEid && !human_weap__mortarMode
    let vertLimits = human_net_phys.phys.currentState.isCrawl ? human_weap__crawlClampVertAngleRad : human_weap__clampVertAngleRad
    out_tm = human_weap_get_aim_tm_impl(human_net_phys, at_time, applyOffsets, vertLimits)
  return isOk


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


def search_grenade_for_fast_throw(var result_ammo_type : int&;
                                  eid : EntityId;
                                  grenade_gun_eid : EntityId;
                                  start_ammo_type : int;
                                  control_state : HumanControlState&)
  var foundGrenade = false
  query(eid) <| $ [es] (itemContainer : EidList)
    query(grenade_gun_eid) <| $ [es(REQUIRE=gun)] (gun__ammoHolderIds : IntList&;
                                                   gun__shell_prop_ids : GunShellPropIds&)
      gather_ammo_for_gun(gun__ammoHolderIds, gun__shell_prop_ids, itemContainer) <| $(ammoItems)
        let ammoItemsCount = length(ammoItems)
        let curSlot = ammoItems |> find_index(start_ammo_type)
        if !(control_state |> human_control_state_is_throw_state_set(HumanControlThrowSlot HCTS_ALL))
          return
        for i in range(ammoItemsCount)
          let ammoItemId = ammoItems[(i + curSlot) % ammoItemsCount]
          find_ammo_for_gun(grenade_gun_eid, itemContainer, ammoItemId, 0) <| $(ammoForGun : AmmoItemForGunResult)
            if ammoForGun.itemIndex < 0
              return
            let itemEid = itemContainer[ammoForGun.itemIndex]
            query(itemEid) <| $ [es] ([[shared_comp]] fastThrowSlots : Object;
                                      item__grenadeType : string)
              let slotConfig = *fastThrowSlots[item__grenadeType] as int
              if slotConfig != null
                for slot in each_enum(HumanControlThrowSlot HCTS_SLOT0)
                  if int(slot) == 1 << (*slotConfig - 1) && control_state |> human_control_state_is_throw_state_set(slot)
                    result_ammo_type = ammoItemId
                    foundGrenade = true
          if foundGrenade
            return
  return foundGrenade


def human_weap_gun_update(var human_net_phys : HumanActor;
                          human_weap__gunEids : EidList;
                          var human_weap__throwMode : bool&;
                          ctx : GunUpdateCtx;
                          transform : float3x4;
                          gun_dir : float3;
                          gun_shoot_dir : float3;
                          phys_transform : float3x4;
                          ct : HumanControlState;
                          grenade_rethrow__grenadeEid : EntityId const?;
                          human_unarmed__active : bool;
                          human_attached_gun__attachedGunEid : EntityId;
                          human_weap__jumpDeviation : float;
                          human_weap__changePosDeviationCanAim : float;
                          human_weap__changePosDeviationCanNotAim : float;
                          human_phys__jumpEndTime : float;
                          human_phys__afterJumpDelay : float;
                          human_phys__isInAirLong : bool)
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
    elif grenade_rethrow__grenadeEid != null
      grenadeEid = *grenade_rethrow__grenadeEid
    if grenadeEid != INVALID_ENTITY_ID
      human_weap__throwMode = throw_grenade_away(ctx.eid, grenadeEid, human_weap__gunEids)
    if is_server() && !human_weap__throwMode
      send_net_event(ctx.eid, [[HumanWeapThrowBackAbort]], target_entity_conn(ctx.eid))

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
  var isLungeMine = false
  query(gunEid) <| $ [es] (subsidiaryGunEid : EntityId const?; lunge_mine : Tag const?)
    if subsidiaryGunEid != null
      overrideGunEid = *subsidiaryGunEid
    isLungeMine = lunge_mine != null

  var wgun : Gun const? = null
  var gunDev : GunDeviation? = null
  var gunAmmo = 0
  var jumpDeviation = human_weap__jumpDeviation
  var grenadeThrower : GrenadeThrower const? = null
  var defaultInit = false
  if curGun == HUWeaponSlots EWS_MELEE || isLungeMine
    if !has(gunEid, "melee_weapon__propsId")
      return
  elif curGun == HUWeaponSlots EWS_GRENADE
    query(gunEid) <| $ [es] (grenade_thrower : GrenadeThrower const?)
      grenadeThrower = grenade_thrower
    if grenadeThrower == null
      return
    defaultInit = true
  else
    defaultInit = true

  if defaultInit
    query(overrideGunEid) <| $ [es(trust_access)] (gun : Gun const?;
                                                   var gun_deviation : GunDeviation?;
                                                   gun__jumpDeviation : float const?;
                                                   gun__ammo : int = 0)
      wgun = gun
      gunDev = gun_deviation
      gunAmmo = gun__ammo
      jumpDeviation = gun__jumpDeviation ?? jumpDeviation
    if wgun == null && !has(gunEid, "itemInWeaponSlot")
      return

  let isJumping = ((uint(phys.currentState.states) & uint(StateFlag ST_JUMP)) != 0u
    || phys.currentState.jumpStartTime > 0.
    || ctx.atTime - human_phys__jumpEndTime < human_phys__afterJumpDelay
    || human_phys__isInAirLong)

  if gunDev != null && ctx.isForReal
    *gunDev |> gun_deviation_getAppliedCT() <| $(var gunDevCT : GunDeviationInput#)
      gunDevCT.bufferSizeMult = ctx.deviationBufferSizeMult
      gunDevCT.tauMult = ctx.shotDeviationMult
      gunDevCT.rotationShotSpreadDecrMult = ctx.rotationShotSpreadDecrMult
      gunDevCT.aimingAfterFireMult = ctx.aimingAfterFireMult
      gunDevCT.movement = phys.currentState.velocity.xz
      let changePoseDeviation = human_phys_state_can_aim(phys.currentState) ? human_weap__changePosDeviationCanAim : human_weap__changePosDeviationCanNotAim
      gunDevCT.minExtraDev = (lerp(get_float(overrideGunEid, "gun__deviationInFireReady") ?? 0.0, 0.0, phys.currentState.aimPosition)
                            + ctx.shotDeviationAdd
                            + max(cvt(abs(phys.currentState.heightCurVel), 0., 1., 0., changePoseDeviation),
                                 (isJumping ? jumpDeviation : 0.0)))

  var needsInterruptActions = false
  var shoot = ((human_weap__throwMode
    ? isFastThrow || ct |> is_control_bit_set(HumanPhysControlType HCT_THROW_BACK) || isHctShootSet
    : (isHctShootSet && allowShootingNoAttach)) && !ctx.isDowned)

  if shoot
    query(ctx.eid) <| $ [es] (human_inventory__entityToUse : EntityId;
                              human_sec_anim__play : bool = false;
                              human_weap__reloadFinishTime : float = -1.0;
                              human_weap__isReloading : bool = false;
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
        shoot &&= ctx.atTime > human_weap__reloadFinishTime && !human_weap__isReloading
        shoot &&= human_weap__weapModActivateStartTime < 0.0
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
      let isMeleeWeapon = (curGun == HUWeaponSlots EWS_MELEE) || human_unarmed__active || isLungeMine
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
        var isSelectedGunChosen = false

        let selectedGunIdx = int(selectedGun)
        if selectedGunIdx >= 0 && selectedGunIdx < int(HUWeaponSlots EWS_NUM)
          query(human_weap__gunEids[selectedGunIdx]) <| $ [es] (gun__totalAmmo : int = 0; gun__ammo : int = 0)
            if gun__totalAmmo > 0 || gun__ammo > 0
              phys.producedCT |> set_chosen_weapon(selectedGun)
              isSelectedGunChosen = true

        if !isSelectedGunChosen
          switch_to_first_weap_with_ammo(human_weap__gunEids, human_net_phys.phys)

  if ctx.isForReal && !isFastThrow
    let isRequestingReload = ct |> is_control_bit_set(HumanPhysControlType HCT_RELOAD)
    // If we have subsidiary gun attached, reload it instead.
    // we can pick which gun to reload with some other key m.b. ?
    if isRequestingReload
      sendEvent(ctx.eid, [[CmdRequestReload atTime=ctx.atTime, gunEid=overrideGunEid]])
    query(overrideGunEid) <| $ [es] (var gun_reload__isRequesting : bool&)
      gun_reload__isRequesting = isRequestingReload


  using() <| $(var gctrl : GunControls#)
    gctrl.shoot = shoot
    gctrl.wishShoot = isHctShootSet
    gctrl.boltActionMult = ctx.boltActionMult
    gctrl.timeStep = human_net_phys.phys.timeStep

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

def human_weap_can_reload(human_eid : EntityId; gun_eid : EntityId) : bool
  var canReload = true
  query(human_eid) <| $ [es] (human_net_phys : HumanActor;
                              human_weap__throwMode : bool;
                              human_weap__weapModActivateStartTime : float;
                              boltActionProgress : float;
                              human_weap__isReloading : bool = false;
                              human_weap__canOperate : bool = true;
                              human_weap__lockWeaponReload : bool = false;
                              burning__isBurning : bool = false;
                              human_attached_gun__attachedGunEid : EntityId = INVALID_ENTITY_ID;
                              human_inventory__entityToUse : EntityId = INVALID_ENTITY_ID)
    assume currentState = human_net_phys.phys.currentState
    assume eqState = currentState.weapEquipState.curState
    assume mvState = currentState.moveState
    let isCrawlMoving = currentState.isCrawl && mvState != HUMoveState EMS_STAND
    let isAttachedToGun = !!human_attached_gun__attachedGunEid
    let isBlockedByBoltAction = ((get_bool(gun_eid, "reload__waitBoltActionFinished") ?? false) &&
                                  boltActionProgress > 0. && boltActionProgress < 1.)
    let usingItem = !!human_inventory__entityToUse && has(human_inventory__entityToUse, "item__interruptsReloading")

    canReload = (!human_weap__throwMode &&
                 !isCrawlMoving &&
                 !human_weap__isReloading &&
                 !burning__isBurning &&
                 (eqState == HUWeaponEquipState EES_EQUIPED || eqState == HUWeaponEquipState EES_DOWN || isAttachedToGun) &&
                 !isBlockedByBoltAction && !human_weap__lockWeaponReload && (human_weap__weapModActivateStartTime < 0.) &&
                 !usingItem &&
                 human_weap__canOperate)
  return canReload


def unload_gun_ammo(gun_eid, owner : EntityId) : void
  if !is_server()
    return

  query(gun_eid) <| $ [es(REQUIRE=gun, REQUIRE_NOT=gun__disableAmmoUnload)] (gun__ammoHolderEid : EntityId;
                                                                             gun__ammo : int)
    if gun__ammoHolderEid != INVALID_ENTITY_ID
      put_ammo_to_container(gun__ammo, gun__ammoHolderEid, owner)
      set_ammo_holder(gun_eid, ecs::INVALID_ENTITY_ID)
      destroyEntity(gun__ammoHolderEid)
      sendEventImmediate(gun_eid, [[CmdUnloadAmmo unloadManually=true]])


def human_gun_to_custom_props2(gun_eid : EntityId;
                               var custom_props : Object& |#) : bool
  var res = false
  query(gun_eid) <| $ [es] (gun__initialComponents : Object const?;
                            gun__curShellId : ShellPropIds const?;
                            var gun__ammoHolderEid : EntityId?;
                            gun__ammo : int = 0)
    res = true
    custom_props |> set("ammoCount", gun__ammo)
    custom_props |> set("shellPropsId", gun__curShellId != null ? *gun__curShellId :  ShellPropIds())
    custom_props |> set("itemEid", gun__ammoHolderEid != null ? *gun__ammoHolderEid : INVALID_ENTITY_ID)
    if gun__ammoHolderEid != null
      *gun__ammoHolderEid = INVALID_ENTITY_ID
    if (gun__initialComponents != null && !empty(*gun__initialComponents))
      custom_props |> set("initialComponents", *gun__initialComponents)

  return res


// unloads gun mod's ammo
def human_gun_mod_to_custom_props2(human_eid : EntityId;
                                   slot_id : int;
                                   slot_name : string) : void
  query(human_eid) <| $ [es] (human_weap__gunMods, human_weap__gunModsBySlot : Array)
    if slot_id >= length(human_weap__gunMods)
      return

    var gunModsBySlot = human_weap__gunModsBySlot[slot_id] |> get_ecs_object()
    var gunMods = human_weap__gunMods[slot_id] |> get_ecs_EidList()
    if gunModsBySlot == null || gunMods == null
      return

    for gunModEid in *gunMods
      query(gunModEid) <| $ [es] (gunAttachable__gunSlotName : string)
        if !empty(slot_name) && (gunAttachable__gunSlotName != slot_name)
          return

        unload_gun_ammo(gunModEid, human_eid)


def human_gun_mod_to_custom_props2(human_eid : EntityId;
                                   slot_id : int;
                                   slot_name : string;
                                   var custom_props : Object& |#) : void
  query(human_eid) <| $ [es] (human_weap__gunMods, human_weap__gunModsBySlot : Array)
    if slot_id >= length(human_weap__gunMods)
      return

    var gunModsBySlot = human_weap__gunModsBySlot[slot_id] |> get_ecs_object()
    var gunMods = human_weap__gunMods[slot_id] |> get_ecs_EidList()
    if gunModsBySlot == null || gunMods == null
      return

    var customPropsGunMods = custom_props["gunMods"] |> getRW_ecs_object()
    if customPropsGunMods == null
      using() <| $(var emptyGunMods : Object)
        custom_props |> set("gunMods", emptyGunMods)
      customPropsGunMods = custom_props["gunMods"] |> getRW_ecs_object()

    for mod in *gunModsBySlot
      if (empty(slot_name) || (mod.key == slot_name))
        let slot = mod.value |> get_ecs_string()
        *customPropsGunMods |> set(mod.key, slot != null ? string(*slot) : "")

    using() <| $(var gunModPropsBySlot : Object)
      for gunModEid in *gunMods
        query(gunModEid) <| $ [es] (gunAttachable__gunSlotName : string)
          if !empty(slot_name) && (gunAttachable__gunSlotName != slot_name)
            return

          using() <| $(var gunModProps : Object)
            if human_gun_to_custom_props2(gunModEid, gunModProps)
              if *gunModsBySlot |> has(gunAttachable__gunSlotName)
                gunModPropsBySlot |> set(gunAttachable__gunSlotName, gunModProps)
              else
                human_gun_custom_props_cleanup(gunModProps)

      var customPropsGunModsProps = custom_props["gunModProps"] |> getRW_ecs_object()
      if customPropsGunModsProps == null
        using() <| $(var emptyGunModProps : Object)
          custom_props |> set("gunModProps", emptyGunModProps)
        customPropsGunModsProps = custom_props["gunModProps"] |> getRW_ecs_object()
      for modProps in gunModPropsBySlot
        (*customPropsGunModsProps) |> set(modProps.key, modProps.value)


def attach_item_to_gun_impl2(eid : EntityId;
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
    human_gun_mod_to_custom_props2(eid, gun_slot_id, slot_name)

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


def dead_or_downed(eid : EntityId) : bool
  var res = false
  query(eid) <| $ [es] (isAlive : bool = true;
                        isDowned : bool = false)
    res = !isAlive || isDowned
  return res


def steal_gun_from_owner2(eid, item_eid : EntityId) : void
  query(eid) <| $ [es] (var itemContainer aka to_itemContainer : EidList&)
    query(item_eid) <| $ [es] (gun__owner : EntityId = INVALID_ENTITY_ID;
                               item__lastOwner : EntityId = INVALID_ENTITY_ID;
                               gun__ammoHolderIds : IntList const?;
                               gun__shell_prop_ids : GunShellPropIds const?)
      let owner = gun__owner != INVALID_ENTITY_ID ? gun__owner : item__lastOwner
      if owner == INVALID_ENTITY_ID || owner == eid
        return

      query(owner) <| $ [es(REQUIRE=human_weap__ammunitionCanBeStolen)] (var human_weap__gunEids : EidList&;
                                                                         var itemContainer aka from_itemContainer : EidList&;
                                                                         maxLootableAmmoCount : int = -1)
        for gunEid in human_weap__gunEids
          if gunEid == item_eid
            gunEid = INVALID_ENTITY_ID
            break

        if gun__ammoHolderIds != null && gun__shell_prop_ids != null
          let itemContainerLen = length(from_itemContainer)
          var ammoLeftToLoot = maxLootableAmmoCount >= 0 ? maxLootableAmmoCount : itemContainerLen
          for idx in range(0, itemContainerLen)
            let reverseIdx = itemContainerLen - 1 - idx
            let itemEid = from_itemContainer[reverseIdx]
            if is_item_ammo_for_gun(itemEid, *gun__ammoHolderIds, *gun__shell_prop_ids)
              if --ammoLeftToLoot < 0
                break

              to_itemContainer |> push(itemEid)
              from_itemContainer |> erase(reverseIdx)


def find_best_weap_slot_id2(eid, item_eid : EntityId;
                            slot_id, currentSlot : int) : int
  var slotId = slot_id
  query(eid) <| $ [es] (human_weap__gunEids : EidList)
    query(item_eid) <| $ [es] (item__weapSlots : Array)
      for slot in item__weapSlots
        let slotName = slot ?? ""
        let slotIdx = int(HUWeaponSlots(slotName))
        if slotIdx == -1
          logerr("incorrect weap slot name '{slotName}' for weapon {item_eid}<{getEntityTemplateName(item_eid)}>")
          continue

        if has(human_weap__gunEids[slotIdx], "disableItemDrop")
          continue
        if slotId < 0 || slotIdx == currentSlot
          slotId = slotIdx

  return slotId


def human_weap_attach_item_to_gun2(eid : EntityId;
                                   gun_slot_id : int;
                                   slot_tag, slot_name : string;
                                   with_sfx : bool;
                                   var custom_props : Object?)
  query(eid) <| $ [es] (human_weap__gunEids : EidList;
                        var human_weap__gunMods : Array&)
    attach_item_to_gun_impl2(eid, human_weap__gunEids, gun_slot_id, slot_tag, slot_name, human_weap__gunMods, custom_props)
    sendEvent(eid, [[EventOnInstallWeapMod slotTag=slot_tag, gunSlotId=gun_slot_id, withSfx=with_sfx]])


def human_weap_attach_item_to_gun2(eid : EntityId;
                                   gun_slot_id : int;
                                   mod_eid : EntityId;
                                   slot_name : string;
                                   with_sfx : bool;
                                   var custom_props : Object?)
  query(mod_eid) <| $ [es] (gunAttachable__slotTag : string = "")
    human_weap_attach_item_to_gun2(eid, gun_slot_id, gunAttachable__slotTag, slot_name, with_sfx, custom_props)


def change_current_slot_on_weapon_swap(from_slot_id, to_slot_id : int;
                                       var human_net_phys : HumanActor) : void
  assume weapEquipState = human_net_phys.phys.currentState.weapEquipState
  let curSlot = int(weapEquipState.curSlot)
  if ((curSlot == from_slot_id || curSlot == to_slot_id)
      && (from_slot_id == int(HUWeaponSlots EWS_PRIMARY) || from_slot_id == int(HUWeaponSlots EWS_SECONDARY))
      && (to_slot_id == int(HUWeaponSlots EWS_PRIMARY) || to_slot_id == int(HUWeaponSlots EWS_SECONDARY)))
    weapEquipState.progress = 0.f
    weapEquipState.curState = HUWeaponEquipState EES_EQUIPED
    weapEquipState.curSlot = HUWeaponSlots(int(human_net_phys.phys.appliedCT.chosenWeapon) == from_slot_id ? to_slot_id : from_slot_id)


def swap_weapons_in_slots_impl2(eid : EntityId;
                                from_slot_id, to_slot_id : int;
                                var human_weap__gunEids : EidList;
                                var human_weap__weapTemplates : Object;
                                var human_weap__gunMods, human_weap__gunModsBySlot : Array) : void
  if from_slot_id < 0 || to_slot_id < 0 || dead_or_downed(eid)
    return

  var weapFrom = human_weap__weapTemplates |> getRW_ecs_string(get_human_weapon_slot_name(from_slot_id))
  var weapTo = human_weap__weapTemplates |> getRW_ecs_string(get_human_weapon_slot_name(to_slot_id))
  if (weapFrom != null && weapTo != null)
    var tmp <- weapFrom
    weapFrom <- weapTo
    weapTo <- tmp
  swap(human_weap__gunEids[from_slot_id], human_weap__gunEids[to_slot_id])
  var fromGunMods = getRW_ecs_EidList(human_weap__gunMods[from_slot_id])
  var toGunMods = getRW_ecs_EidList(human_weap__gunMods[to_slot_id])
  if fromGunMods != null && toGunMods != null
    swap(*fromGunMods, *toGunMods)
  var fromGunModsBySlot = getRW_ecs_object(human_weap__gunModsBySlot[from_slot_id])
  var toGunModsBySlot = getRW_ecs_object(human_weap__gunModsBySlot[to_slot_id])
  if fromGunModsBySlot != null && toGunModsBySlot != null
    swap(*fromGunModsBySlot, *toGunModsBySlot)


def swap_weapons_in_slots2(eid : EntityId; from_slot_id, to_slot_id : int) : void
  if eid == INVALID_ENTITY_ID
    return

  var canSwapWeapons = true
  query(eid) <| $ [es] (human_unarmed__hiddenWeapon : bool = false)
    canSwapWeapons = !human_unarmed__hiddenWeapon

  if !canSwapWeapons
    return

  query(eid) <| $ [es] (var human_weap__gunEids : EidList;
                        var human_weap__weapTemplates : Object;
                        var human_weap__gunMods, human_weap__gunModsBySlot : Array;
                        var human_net_phys : HumanActor)
    if !is_server()
      send_net_event(eid, [[HumanSwapWeapRequest fromSlotId=from_slot_id, toSlotId=to_slot_id]])
    swap_weapons_in_slots_impl2(eid, from_slot_id, to_slot_id,
                               human_weap__gunEids, human_weap__weapTemplates,
                               human_weap__gunMods, human_weap__gunModsBySlot)
    if human_weap__gunEids[from_slot_id] != INVALID_ENTITY_ID
      change_current_slot_on_weapon_swap(from_slot_id, to_slot_id, human_net_phys)
    else
      human_net_phys.phys.producedCT |> set_chosen_weapon(HUWeaponSlots(to_slot_id))
      human_net_phys.phys.currentState.weapEquipState.curSlot = HUWeaponSlots(to_slot_id)


def swap_weapons_in_slots2(eid : EntityId; from_slot_name, to_slot_name : string) : void
  let fromSlotId = int(HUWeaponSlots(from_slot_name))
  let toSlotId = int(HUWeaponSlots(to_slot_name))
  if fromSlotId < 0 || toSlotId < 0
    return
  swap_weapons_in_slots2(eid, fromSlotId, toSlotId)


def remove_item_from_weap_impl2(eid : EntityId; slot_id : int; weap_slot : string; to_ground : bool) : EntityId
  if !is_server()
    logerr("[Remove item from weap impl] Attempted to call remove_item_from_weap_impl2 from client.")
    return INVALID_ENTITY_ID

  var result = INVALID_ENTITY_ID
  query(eid) <| $ [es] (transform : float3x4;
                        human_weap__gunMods : Array;
                        human_inventory__dropLootOffset : float3;
                        itemContainer : EidList const?;
                        human_inventory__dropsLoot : bool = true;
                        isAlive : bool = true;
                        isDowned : bool = false)
    if !isAlive || isDowned
      return

    let gunMods = human_weap__gunMods[slot_id] |> get_ecs_EidList()
    if gunMods == null
      return
    var curGunMod = INVALID_ENTITY_ID
    for gunModEid in *gunMods
      var found = false
      query(gunModEid) <| $ [es] (gunAttachable__gunSlotName : string)
        if gunAttachable__gunSlotName == weap_slot
          curGunMod = gunModEid
          found = true
      if !found
        break

    if curGunMod == INVALID_ENTITY_ID
      return

    query(curGunMod) <| $ [es] (item__template : string)
      if to_ground
        if human_inventory__dropsLoot
          using() <| $(var desc : ItemDesc)
            desc |> setTemplOverride(item__template)
            desc |> setAddTemplate("item_in_world")
            desc.ownerEid = eid;
            desc.tm = transform;
            desc.tm[3] = transform * human_inventory__dropLootOffset
            drop_item2(desc, -1.0, true, INVALID_ENTITY_ID)

        sendEvent(eid, [[EventOnLootDrop itemEid=INVALID_ENTITY_ID]])
        var nullCustomProps : Object? = null
        human_weap_attach_item_to_gun2(eid, slot_id, "", weap_slot, false, nullCustomProps)
      else
        if itemContainer == null
          return

        var nullCustomProps : Object? = null
        human_weap_attach_item_to_gun2(eid, slot_id, "", weap_slot, true, nullCustomProps)
        result = createEntitySync(item__template) <| $(var init : ComponentsInitializer)
          set(init, "item__ownerEid", eid)

  return result


def remove_item_from_weap2(eid : EntityId; slot_name, weap_slot : string; to_ground : bool) : void
  if eid == INVALID_ENTITY_ID
    return
  let slotId = int(HUWeaponSlots(slot_name))
  if slotId < 0
    return

  if is_server()
    remove_item_from_weap_impl2(eid, slotId, weap_slot, to_ground)
  else
    send_net_event(eid, [[HumanRemoveItemFromWeapRequest slotId=slotId, slotName=weap_slot, toGround=to_ground]])


def is_gunmod_allowed2(gun_eid, mod_eid : EntityId) : bool
  var isAllowed = false
  query(gun_eid) <| $ [es] (gun_mods__slots : Object)
    query(mod_eid) <| $ [es] (gunAttachable__gunSlotName, gunAttachable__slotTag : string)
      let slot = gun_mods__slots |> get_ecs_object(gunAttachable__gunSlotName)
      if slot == null
        return
      let slotName = *slot |> get_ecs_string(gunAttachable__slotTag)
      isAllowed = (slotName != null)

  return isAllowed


def swap_weapon_mods_impl2(eid : EntityId;
                           from_slot : int;
                           from_weap_mod_slot : string;
                           to_slot : int;
                           to_weap_mod_slot : string) : void
  if from_slot < 0 || to_slot < 0 || dead_or_downed(eid)
    return

  query(eid) <| $ [es] (human_weap__gunMods : Array;
                        human_weap__gunEids : EidList const?;
                        var itemContainer : EidList?)
    var gunMods = human_weap__gunMods[from_slot] |> get_ecs_EidList()
    if gunMods == null
      return

    var gunModFrom = INVALID_ENTITY_ID
    for gunModEid in *gunMods
      var found = false
      query(gunModEid) <| $ [es] (gunAttachable__gunSlotName : string)
        if gunAttachable__gunSlotName == from_weap_mod_slot
          gunModFrom = gunModEid
          found = true
      if found
        break

    if gunModFrom == INVALID_ENTITY_ID
      return

    if !is_server()
      logerr("[Swap weapon mods impl2] Attempted to call swap_weapon_mods_impl2 from client.")
      return

    if human_weap__gunEids == null
      return

    if !is_gunmod_allowed2((*human_weap__gunEids)[to_slot], gunModFrom)
      return

    var fromSlotTag = ""
    // We need a copy of gunAttachable.slotTag because it will be destroyed at human_weap_attach_item_to_gun
    query(gunModFrom) <| $ [es] (gunAttachable__slotTag : string)
      fromSlotTag = gunAttachable__slotTag

    // clear the source mod slot
    var nullCustomProps : Object? = null
    human_weap_attach_item_to_gun2(eid, from_slot, "", from_weap_mod_slot, false, nullCustomProps)

    var gunModsTo = human_weap__gunMods[to_slot] |> get_ecs_EidList()
    if gunModsTo == null
      return

    var gunModTo = INVALID_ENTITY_ID
    for gunModEid in *gunModsTo
      var found = false
      query(gunModEid) <| $ [es] (gunAttachable__gunSlotName : string)
        if gunAttachable__gunSlotName == to_weap_mod_slot
          gunModTo = gunModEid
          found = true
      if found
        break

    if gunModTo != INVALID_ENTITY_ID
      if is_gunmod_allowed2((*human_weap__gunEids)[from_slot], gunModTo)
        // put the destination item back to the source slot
        human_weap_attach_item_to_gun2(eid, from_slot, gunModTo, from_weap_mod_slot, false, nullCustomProps)
      else
        // clear the source mod slot
        human_weap_attach_item_to_gun2(eid, from_slot, "", from_weap_mod_slot, false, nullCustomProps)

        if itemContainer != null
          query(gunModTo) <| $ [es] (item__template : string)
            *itemContainer |> push(createEntitySync(item__template))

    human_weap_attach_item_to_gun2(eid, to_slot, fromSlotTag, to_weap_mod_slot, true, nullCustomProps)


def swap_weapon_mods2(eid : EntityId;
                      from_slot, from_weap_mod_slot, to_slot, to_weap_mod_slot : string) : void
  if eid == INVALID_ENTITY_ID
    return
  let fromSlotId = int(HUWeaponSlots(from_slot))
  let toSlotId = int(HUWeaponSlots(to_slot))

  if fromSlotId < 0 || toSlotId < 0
    return
  if is_server()
    swap_weapon_mods_impl2(eid, fromSlotId, from_weap_mod_slot, toSlotId, to_weap_mod_slot)
  else
    send_net_event(eid, [[HumanSwapWeaponModsRequest fromSlotId=fromSlotId, fromWeapModSlot=from_weap_mod_slot, toSlotId=toSlotId, toWeapModSlot=to_weap_mod_slot]])

enum RecreateGunsFlags
  None         = 0
  Attach       = 1 << 0
  ParentLoaded = 1 << 1


def init_gun_comps(var init : ComponentsInitializer;
                   gun_slot : int;
                   eid : EntityId;
                   init_comps : Object const? = null)
  query(eid) <| $ [es] (human_weap__salt : IntList)
    let salt = human_weap__salt[gun_slot]
    if init_comps != null
      set(init, "gun__initialComponents", *init_comps)
      for kv in *init_comps
        set(init, kv.key, kv.value)

    set(init, "gun__salt", salt)
    set(init, "gun__owner", eid)


def create_gun_for_entity_impl(eid : EntityId;
                               gun_slot : int;
                               weap_templ_name : string;
                               init_comps : Object const?;
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
    init_gun_comps(init, gun_slot, eid, init_comps)
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
    if ammo_template == ""
      logerr("Can't restore ammo with invalid ammo template ( isn't define in '{getEntityTemplateName(eid)} )")
      return false
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
    if gun_slot >= length(human_weap__weapInfo)
      let guid = get_string(eid, "guid", "none")
      print("Failed to restore ammo for eid {eid}  template '{getEntityTemplateName(eid)}'  guid {guid}")
      print("weapInfo count {length(human_weap__weapInfo)}  gunEids count {length(human_weap__gunEids)}  wanted slot {gun_slot}")
      logerr("Can't restore ammo for guid {guid}. See log for more details")
      return
    query(human_weap__gunEids[gun_slot]) <| $ [es(REQUIRE=gun)] (gun__ammo : int = 0; gun__ammoHolderEid : EntityId = INVALID_ENTITY_ID)
      let weapInfoSlot = human_weap__weapInfo[gun_slot] |> get_ecs_object()
      let curAmmoHolderItemId = get_int(gun__ammoHolderEid, "item__id") ?? INVALID_ITEM_ID
      assume calcGunAmmoCb = ($(ammoItemId : int) : int { return ammoItemId == curAmmoHolderItemId? gun__ammo : 0; })

      let numReserveAmmo = weapInfoSlot |> get_int("numReserveAmmo") ?? 0
      if numReserveAmmo > 0
        let reserveAmmoTemplate = weapInfoSlot |> get_ecs_string("reserveAmmoTemplate")
        if reserveAmmoTemplate == null
          print("eid: {eid} of template '{getEntityTemplateName(eid)}'")
          logerr("'reserveAmmoTemplate' is missed in human_weap.weapInfo. See log for details.")
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
          // Temp copy since we modifying gunModsBySlot[slot_id] within attach_item_to_gun_impl2()
          var gunModsInSlotCopy : array<GunModInSlot>
          gunModsInSlotCopy |> reserve(length(*gunModsInSlot))
          for gunMod in *gunModsInSlot
            let gunModStr = gunMod.value |> get_ecs_string()
            let value = gunModStr != null ? *gunModStr |> string() : ""
            gunModsInSlotCopy |> push([[GunModInSlot key=gunMod.key, value=value]])
          for gunMod in gunModsInSlotCopy
            var nullCustomProps : Object? = null
            attach_item_to_gun_impl2(eid, human_weap__gunEids, slot_id, gunMod.value,
                                    gunMod.key, human_weap__gunMods, nullCustomProps)

      server_init_gun_ammo(gunEidInSlot)

    if human_weap__currentGunSlot == slot_id
      human_weap__currentGunEid = human_weap__gunEids[slot_id]
      human_weap__currentGunModEids := *(human_weap__gunMods[slot_id] |> get_ecs_EidList())


def human_weap_set_item_to_slot(eid : EntityId;
                                template_name, custom_skin : string;
                                slot_id : int;
                                var custom_props : Object?) : void
  if !is_server()
    logerr("[Human weap set item to slot] Attempted to call human_weap_set_item_to_slot from client.")
    return

  query(eid) <| $ [es] (human_gun_skin_list : Array;
                        human_weap__currentGunSlot : int;
                        anim_phys : AnimatedPhys const?;
                        var human_net_phys : HumanActor;
                        var human_weap__gunEids : EidList;
                        var human_weap__gunMods : Array;
                        var human_weap__weapTemplates : Object;
                        var human_weap__gunModsBySlot : Array)
    var gunMods = human_weap__gunMods[slot_id] |> getRW_ecs_EidList()
    if gunMods == null
      return

    for gunModEid in *gunMods
      destroyEntity(gunModEid)
    *gunMods |> clear()

    if human_weap__gunEids[slot_id] != INVALID_ENTITY_ID
      destroyEntity(human_weap__gunEids[slot_id])

    human_weap__weapTemplates |> set(get_human_weapon_slot_name(slot_id), template_name)

    if anim_phys != null
      var gunInitComps : Object const?
      if custom_props != null
        gunInitComps = ((*custom_props)["initialComponents"]) |> get_ecs_object()

      var fullTemplate = template_name
      var skinTemplate = custom_skin
      for item in human_gun_skin_list
        let skin = item |> get_ecs_object()
        if skin != null && template_name == get_string(skin, "gunTemplate", "")
          skinTemplate = get_string(skin, "subTemplate", "")
          break

      if skinTemplate != ""
        fullTemplate = add_sub_template_name(fullTemplate, skinTemplate)

      human_weap__gunEids[slot_id] = create_gun_for_entity_impl(eid, slot_id, fullTemplate, gunInitComps) <| $(n : string;
                                                                                                               var ci : ComponentsInitializer)// TODO: async creation
        return createEntitySync(n, ci)
      let selectFirstAvailableWeap = (slot_id == human_weap__currentGunSlot ||
                                      human_weap__gunEids[int(human_net_phys.phys.currentState.weapEquipState.curSlot)] == INVALID_ENTITY_ID)

      if human_weap__gunEids[slot_id] != INVALID_ENTITY_ID
        query(human_weap__gunEids[slot_id]) <| $ [es] (var gun__customSkin : das_string)
          gun__customSkin := skinTemplate

        var weapSlot = human_weap__gunModsBySlot[slot_id] |> getRW_ecs_object()
        if weapSlot == null
          return
        *weapSlot |> clear()

        query(human_weap__gunEids[slot_id]) <| $ [es] (gun_mods__slots : Object)
          for slot in gun_mods__slots
            *weapSlot |> set(slot.key, "")
        let isAttached = (human_weap__currentGunSlot == slot_id)
        sendEvent(human_weap__gunEids[slot_id], [[CmdWeapAttach toEid=eid, isAttached=isAttached, slotId=slot_id]])
        sendEvent(human_weap__gunEids[slot_id], [[EventOnParentLoaded eid=eid, slotId=slot_id]])
        if human_weap__currentGunSlot == slot_id
          sendEvent(eid, [[EventOnSelectWeap curr_gun_slot_id=human_weap__currentGunSlot]])
      elif selectFirstAvailableWeap
        for i in iter_range(human_weap__gunEids)
          if human_weap__gunEids[i] != INVALID_ENTITY_ID
            sendEvent(eid, [[HumanWeapSetCurrentGun slot=uint8(i)]])
            human_net_phys.phys.producedCT |> set_chosen_weapon(HUWeaponSlots(i))
            human_net_phys.phys.currentState.weapEquipState.curSlot = HUWeaponSlots(i)
            break

    if human_weap__gunEids[slot_id] != INVALID_ENTITY_ID
      if custom_props != null
        human_gun_from_custom_props(*custom_props, human_weap__gunEids[slot_id])
        let gunModsObj = ((*custom_props)["gunMods"]) |> get_ecs_object()
        if gunModsObj != null
          var gunModPropsBySlot = ((*custom_props)["gunModProps"]) |> getRW_ecs_object()
          for mod in *gunModsObj
            var nullCustomProps : Object? = null
            let slotTag = mod.value |> get_ecs_string()
            human_weap_attach_item_to_gun2(eid, slot_id, slotTag != null ? string(*slotTag) : "", mod.key, false,
              (gunModPropsBySlot != null ? getRW_ecs_object((*gunModPropsBySlot)[mod.key]) : nullCustomProps))

    if custom_props != null
      human_gun_custom_props_cleanup(*custom_props)
