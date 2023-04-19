require ecs
require DngNet
require HumanPhys
require DngHuman
require game.es.events
require common_shooter.es.human_weap_common
require common_shooter.events_common_shooter
require Gun
require DaWeapons
require DaWeaponProps
require DngWeapon
require enlisted.events_enlisted
require common_shooter.es.human.human_reload_common

def reload_projectile(owner_eid : EntityId;
                      grenade_eid : EntityId;
                      prev_ammo_type : int;
                      gun__wishAmmoItemType : int)
  if !is_server()
    return
  if prev_ammo_type != gun__wishAmmoItemType
    destroyEntity(obtain_owned_projectile_entity(owner_eid, HUWeaponSlots EWS_GRENADE))
  if reload_impl(owner_eid, int(HUWeaponSlots EWS_GRENADE), ReloadAmmoMode CONSUME)
    reload_projectile(owner_eid, grenade_eid)

def try_enable_throw_mode(owner_eid : EntityId;
                          grenade_eid : EntityId;
                          shoot : bool;
                          ct : HumanControlState;
                          gun__ammo : int;
                          gun__totalAmmo : int;
                          var gun__wishAmmoItemType : int&;
                          var human_weap__throwMode : bool&)
  if !shoot
    return false

  let prevAmmoType = gun__wishAmmoItemType

  let isFastThrow = is_control_bit_set(ct, HumanPhysControlType HCT_THROW_BACK)
  if isFastThrow
    human_weap__throwMode = gun__totalAmmo > 0 || gun__ammo > 0
  else
    var newAmmoType : int
    human_weap__throwMode = search_grenade_for_fast_throw(newAmmoType, owner_eid, grenade_eid, prevAmmoType, ct)
    if human_weap__throwMode
      gun__wishAmmoItemType = newAmmoType

  if human_weap__throwMode
    reload_projectile(owner_eid, grenade_eid, prevAmmoType, gun__wishAmmoItemType)

  return human_weap__throwMode

def downed_grenade_update(eid : EntityId;
                          transform : float3x4;
                          at_time : float;
                          dt : float;
                          is_for_real : bool;
                          isThrowingAllowed : bool;
                          ct : HumanControlState;
                          human_net_phys : HumanActor;
                          human_weap__gunEids : EidList;
                          var human_weap__throwMode : bool&)
  if !is_for_real
    return

  let grenadeSlotEid = human_weap__gunEids[int(HUWeaponSlots EWS_GRENADE)]

  query(grenadeSlotEid) <| $ [es] (grenade_thrower : GrenadeThrower;
                                   gun__ammo : int;
                                   gun__totalAmmo : int;
                                   var gun__wishAmmoItemType : int&)
    let shoot = isThrowingAllowed && (is_control_bit_set(ct, HumanPhysControlType HCT_THROW) || is_control_bit_set(ct, HumanPhysControlType HCT_THROW_BACK))
    if (!human_weap__throwMode &&
        !try_enable_throw_mode(eid, grenadeSlotEid, shoot, ct,
                               gun__ammo, gun__totalAmmo, gun__wishAmmoItemType,
                               human_weap__throwMode))
      return

    using() <| $(var gctrl : GunControls#)
      gctrl.shoot = shoot
      gctrl.timeStep = 0.01
      let dir = normalize(float3(0.14, -0.99, 0.0)) // approximative down
      using(dir, dir, human_net_phys.phys.currentState.velocity, transform, transform) <| $(var gloc : GunLocation#)
        sendEventImmediate(grenadeSlotEid, [[CmdWeapPhysUpdate
                                             owner = eid,
                                             atTime = at_time,
                                             dt = dt,
                                             isForReal = is_for_real,
                                             slotId = int(HUWeaponSlots EWS_GRENADE),
                                             gctrl := gctrl,
                                             gloc := gloc]])

    update_reload(eid, at_time, dt)

    if grenade_thrower.state == (GrenadeThrowState GTS_READY)
      human_weap__throwMode = false

[es(REQUIRE=(human_weap, canDropGrenadeInDowned), REQUIRE_NOT=human_input)]
def downed_grenade_thrower_post_phys(evt : CmdPostPhysUpdate;
                                     eid : EntityId;
                                     isAlive : bool;
                                     isDowned : bool;
                                     human_net_phys : HumanActor;
                                     transform : float3x4;
                                     human_weap__gunEids : EidList;
                                     var human_weap__throwMode : bool&;
                                     human_weap__lockedGrenadeThrowingCounter : int = 0)
  if !isAlive || !isDowned
    return
  let atTime = float(evt.tick + 1) * evt.dt
  let isThrowingAllowed = human_weap__lockedGrenadeThrowingCounter == 0
  downed_grenade_update(eid, transform, atTime, evt.dt, evt.isForReal, isThrowingAllowed,
                        human_net_phys.phys.appliedCT, human_net_phys, human_weap__gunEids,
                        human_weap__throwMode)


[es(REQUIRE=(human_input, human_weap, canDropGrenadeInDowned), after=after_net_phys_sync)]
def downed_grenade_thrower(info : ParallelUpdateFrameDelayed;
                           eid : EntityId;
                           isAlive : bool;
                           isDowned : bool;
                           human_net_phys : HumanActor;
                           transform : float3x4;
                           human_weap__gunEids : EidList;
                           var human_weap__throwMode : bool&;
                           human_weap__lockedGrenadeThrowingCounter : int = 0)
  if !isAlive || !isDowned
    return
  let dt = info.dt;
  let atTime = info.curTime;
  let isThrowingAllowed = human_weap__lockedGrenadeThrowingCounter == 0
  downed_grenade_update(eid, transform, atTime, dt, true, isThrowingAllowed,
                        human_net_phys.phys.producedCT, human_net_phys, human_weap__gunEids,
                        human_weap__throwMode)
