require ecs
require GamePhys
require HumanPhys
require EnlistedHuman
require game.es.events
require DagorMath
require math.base
require common_shooter.es.human_weap_common

[es]
def update_weapon_equip_state(evt : CmdPostPhysUpdate;
                              human_weap__gunMatId : int;
                              human_weap__gunBackoffVisc : float = 0.1;
                              human_weap__gunTraceTime : float = 0.2;
                              human_weap__gunMaxBackoff : float = 0.0;
                              human_net_phys__isSimplifiedPhys : bool = false;
                              var human_net_phys : HumanActor&)
  assume phys = human_net_phys.phys
  assume currentState = phys.currentState
  assume appliedCT = phys.appliedCT
  assume weapEquipState = currentState.weapEquipState
  assume weaponParams = phys.weaponParams

  if !phys.hasGuns
    return

  var humanTm : float3x4
  currentState.location |> location_toTM(humanTm)
  var gunTm : float3x4
  human_phys_calcGunTm(phys, PrecomputedPresetMode TPV, humanTm, currentState.gunAngles.y, currentState.leanPosition, currentState.height, gunTm)

  if weapEquipState.curState == HUWeaponEquipState EES_EQUIPED || weapEquipState.curState == HUWeaponEquipState EES_DOWN
    if appliedCT.chosenWeapon != weapEquipState.curSlot && weaponParams[int(appliedCT.chosenWeapon)].exists && phys.canSwitchWeapon
      phys |> reset_weapon_state()

  if weapEquipState.curState == HUWeaponEquipState EES_EQUIPED
    if human_phys_state_forceWeaponUp(currentState) || human_phys_state_attachedToExternalGun(currentState)
      return
    var backoff = 0.
    if !human_net_phys__isSimplifiedPhys
      let intersects = check_gun_trace(phys, gunTm, -1., human_weap__gunMatId, human_weap__gunMaxBackoff, backoff)
      if intersects || human_phys_state_get_forceWeaponDown(currentState) || human_phys_state_get_isClimbing(currentState)
        currentState.gunTraceTimer = 0.
        weapEquipState.curState = HUWeaponEquipState EES_DOWN
    currentState.gunBackoffAmount = approach(currentState.gunBackoffAmount, backoff, evt.dt, human_weap__gunBackoffVisc)

  elif weapEquipState.curState == HUWeaponEquipState EES_HOLSTERING
    let holsterTime = weaponParams[int(weapEquipState.curSlot)].holsterTime
    let holsterMult = currentState.fasterChangeWeaponMult * weaponParams[int(weapEquipState.nextSlot)].holsterSwapSpeedMult
    weapEquipState.progress += safediv(evt.dt, holsterTime) * holsterMult
    if appliedCT.chosenWeapon != weapEquipState.nextSlot
      weapEquipState.nextSlot = appliedCT.chosenWeapon
    if weapEquipState.progress >= 1.
      weapEquipState.progress -= 1.
      weapEquipState.curState = HUWeaponEquipState EES_EQUIPING
    if currentState.moveState == HUMoveState EMS_SPRINT && !phys.allowWeaponSwitchOnSprint
      weapEquipState.progress = 0.
      weapEquipState.curState = HUWeaponEquipState EES_EQUIPED
  elif weapEquipState.curState == HUWeaponEquipState EES_EQUIPING
    let equipTime = weaponParams[int(weapEquipState.nextSlot)].equipTime
    let equipMult = currentState.fasterChangeWeaponMult * weaponParams[int(weapEquipState.nextSlot)].equipSpeedMult
    weapEquipState.progress += safediv(evt.dt, equipTime) * equipMult
    if weapEquipState.progress >= 1.
      weapEquipState.progress = 0.
      weapEquipState.curState = HUWeaponEquipState EES_EQUIPED
      if phys.canSwitchWeapon
        weapEquipState.curSlot = weapEquipState.nextSlot
  elif weapEquipState.curState == HUWeaponEquipState EES_DOWN
    var backoff = 0.
    let isGunDownByState = human_phys_state_get_forceWeaponDown(currentState) || human_phys_state_get_isClimbing(currentState)
    if (human_phys_state_forceWeaponUp(currentState)
        || human_phys_state_attachedToExternalGun(currentState)
        || (!isGunDownByState &&
           (human_net_phys__isSimplifiedPhys || !check_gun_trace(phys, gunTm, -1., human_weap__gunMatId, human_weap__gunMaxBackoff, backoff))))
      currentState.gunTraceTimer += evt.dt
      if (currentState.gunTraceTimer > human_weap__gunTraceTime)
        weapEquipState.curState = HUWeaponEquipState EES_EQUIPED
