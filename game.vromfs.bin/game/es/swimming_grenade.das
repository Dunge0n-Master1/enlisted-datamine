require ecs
require game.es.events
require enlisted.events_enlisted
require common_shooter.events_common_shooter
require Gun
require DaWeapons
require HumanPhys
require DngHuman

def cancel_grenade_throw(eid : EntityId;
                         transform : float3x4;
                         human_net_phys : HumanActor;
                         human_weap_gun_eids : EidList;
                         at_time : float;
                         dt : float)
  let grenadeSlotEid = human_weap_gun_eids[int(HUWeaponSlots EWS_GRENADE)]

  using <| $(var gctrl : GunControls#)
    gctrl.shoot = false
    gctrl.timeStep = 0.01
    let dir = transform[0] //throw forward
    using(dir, dir, human_net_phys.phys.currentState.velocity, transform, transform) <| $(var gloc : GunLocation#)
      sendEventImmediate(grenadeSlotEid, [[CmdWeapPhysUpdate
                                           owner = eid,
                                           atTime = at_time,
                                           dt = dt,
                                           isForReal = true,
                                           slotId = int(HUWeaponSlots EWS_GRENADE),
                                           gctrl := gctrl,
                                           gloc := gloc]])

[es(REQUIRE=human_weap, REQUIRE_NOT=human_input)]
def swimming_grenade_thrower_post_phys(evt : CmdPostPhysUpdate;
                                       eid : EntityId;
                                       transform : float3x4;
                                       human_net_phys : HumanActor;
                                       human_net_phys__isSwimming : bool;
                                       human_weap__throwMode : bool;
                                       human_weap__gunEids : EidList)
  if !human_net_phys__isSwimming || !human_weap__throwMode || !evt.isForReal
    return

  assume ct = human_net_phys.phys.appliedCT

  if !is_control_bit_set(ct, HumanPhysControlType HCT_SHOOT)
    return

  let atTime = float(evt.tick + 1) * evt.dt
  cancel_grenade_throw(eid, transform, human_net_phys, human_weap__gunEids, atTime, evt.dt)

[es(REQUIRE=(human_input, human_weap), after=after_net_phys_sync)]
def swimming_grenade_thrower(info : ParallelUpdateFrameDelayed;
                             eid : EntityId;
                             transform : float3x4;
                             human_net_phys : HumanActor;
                             human_net_phys__isSwimming : bool;
                             human_weap__throwMode : bool;
                             human_weap__gunEids : EidList)
  if !human_net_phys__isSwimming || !human_weap__throwMode
    return

  assume ct = human_net_phys.phys.producedCT

  if !is_control_bit_set(ct, HumanPhysControlType HCT_SHOOT)
    return

  cancel_grenade_throw(eid, transform, human_net_phys, human_weap__gunEids, info.curTime, info.dt)
