require ecs
require DngNet
require common_shooter.events_common_shooter
require common_shooter.es.human.human_gun_common
require Gun
require DngPhys

[es(REQUIRE=(animchar_render__enabled, gun__propsId))]
def human_gun_delayed_shot_update(evt : CmdWeapPhysUpdate;
                                  eid : EntityId;
                                  gun__ammo : int;
                                  gun__manuallyUnloaded : bool;
                                  human_gun_attached : bool;
                                  gun : Gun;
                                  gun_delayed_shot__holdTriggerDelay : float;
                                  var gun_delayed_shot__delayTime : float&)
  if !human_gun_attached
    return

  let ownerEid = evt.owner
  let atTime = evt.atTime
  let dt = evt.dt
  let isForReal = evt.isForReal
  var gctrl = evt.gctrl
  let gloc = evt.gloc

  var charged = false
  if gctrl.shoot
    if gun_delayed_shot__delayTime < 0.
      gun_delayed_shot__delayTime = gun_delayed_shot__holdTriggerDelay
    else
      gun_delayed_shot__delayTime -= evt.dt
      if gun_delayed_shot__delayTime < 0.
        charged = true
  else
    gun_delayed_shot__delayTime = -1.

  try_reload_empty_gun(gun, eid, gun__manuallyUnloaded, gctrl.shoot, isForReal, gun__ammo, ownerEid, (atTime - dt))

  let rndSeed = phys_time_to_seed(atTime)

  gctrl.shoot = charged
  sendEventImmediate(eid, [[CmdGunUpdate atTime=atTime, isForReal=isForReal, seed=rndSeed, gctrl=gctrl, gloc=gloc]])

[es(tag=server)]
def delayed_shot_set_charge_status(evt : CmdWeapPhysUpdate; gun__ammo : int; var gun_charge_fx__active : bool&)
  gun_charge_fx__active = evt.gctrl.shoot && gun__ammo > 0

[es(tag=server, track=human_gun_attached)]
def delayed_shot_charge_disable_unattached(evt : Event; human_gun_attached : bool; var gun_charge_fx__active : bool&)
  gun_charge_fx__active &&= human_gun_attached

[es(tag=server, track=gun__owner)]
def delayed_shot_charge_disable_no_owner(evt : Event; gun__owner : EntityId; var gun_charge_fx__active : bool&)
  gun_charge_fx__active &&= !!gun__owner