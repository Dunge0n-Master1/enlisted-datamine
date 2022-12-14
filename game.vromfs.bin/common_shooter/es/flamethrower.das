require ecs
require EnlistedPhys
require DagorMath
require game.utils.team
require common_shooter.events_common_shooter
require common_shooter.es.flamethrower_common
require DaWeapons
require enlisted.events_enlisted
require math.base

[es(tag=server, after=flamethrower_extinguish_under_water)]
def flamethrower_phys(evt : CmdWeapPhysUpdate;
                      eid : EntityId;
                      gun__ammo : int;
                      var flamethrower__flameCurrentLength : float&;
                      var flamethrower__active : bool&;
                      var flamethrower__hitAnything : bool?;
                      gun__owner : EntityId;
                      gun__propsId : int = -1;
                      gun__isOverheat : bool = false;
                      flamethrower__fireTemplate : string;
                      flamethrower__flameStreamRadius : float;
                      flamethrower__flameCloudRadius : float;
                      flamethrower__flameSpeed : float;
                      flamethrower__maxFlameLength : float;
                      flamethrower__streamDamagePerSecond : float;
                      flamethrower__cloudDamagePerSecond : float;
                      flamethrower__friendlyStreamDamagePerSecond : float;
                      flamethrower__friendlyCloudDamagePerSecond : float;
                      flamethrower__shouldSetFriendlyOnFire : bool;
                      flamethrower__minBetweenFireDist : float;
                      flamethrower__flameStartOffset : float;
                      flamethrower__dropletLength : float;
                      flamethrower__dropletSpreadYaw : float;
                      flamethrower__dropletSpreadPitchMin : float;
                      flamethrower__dropletSpreadPitchMax : float;
                      flamethrower__dropletNormalOffset : float;
                      flamethrower__cloudStartOffset : float;
                      flamethrower__additionalCheckDistance : float = 0.25;
                      flamethrower__maxFiresToReignite : int;
                      flamethrower__addFullForceTimePerSec : float;
                      flamethrower__underwater : bool;
                      flamethrower__minRadiusForSphereCast : float = 0.011;
                      flamethrower__numTracesSphereCast : int = 4)
  if !evt.isForReal
    return

  let canShoot = gun__ammo > 0 && !flamethrower__underwater && !gun__isOverheat
  if !evt.gctrl.shoot
    flamethrower__flameCurrentLength = 0.0
    if flamethrower__hitAnything != null
      *flamethrower__hitAnything = false
  elif canShoot
    let flameDamage = [[FlameDamage offender                = gun__owner,
                                    offenderTeam            = get_int(gun__owner, "team") ?? TEAM_UNASSIGNED,
                                    streamDamage            = evt.dt * flamethrower__streamDamagePerSecond,
                                    cloudDamage             = evt.dt * flamethrower__cloudDamagePerSecond,
                                    friendlyStreamDamage    = evt.dt * flamethrower__friendlyStreamDamagePerSecond,
                                    friendlyCloudDamage     = evt.dt * flamethrower__friendlyCloudDamagePerSecond,
                                    shouldSetFriendlyOnFire = flamethrower__shouldSetFriendlyOnFire,
                                    gunPropsId              = gun__propsId]]
    let dropletsSpread = [[DropletSpread yaw          = flamethrower__dropletSpreadYaw,
                                         pitchMin     = flamethrower__dropletSpreadPitchMin,
                                         pitchMax     = flamethrower__dropletSpreadPitchMax,
                                         maxLength    = flamethrower__dropletLength,
                                         normalOffset = flamethrower__dropletNormalOffset]]
    if evt.gloc.gunPos != null
      let gunPos = *(evt.gloc.gunPos)
      shoot_fire(evt.dt, gunPos, evt.gloc.gunDir, flamethrower__fireTemplate,
                 flamethrower__flameStreamRadius, flamethrower__flameCloudRadius,
                 flamethrower__minBetweenFireDist, flamethrower__additionalCheckDistance,
                 flameDamage, flamethrower__flameStartOffset, flamethrower__cloudStartOffset,
                 flamethrower__maxFlameLength, flamethrower__flameSpeed,
                 dropletsSpread, flamethrower__addFullForceTimePerSec, flamethrower__maxFiresToReignite,
                 flamethrower__flameCurrentLength, flamethrower__hitAnything, gun__owner,
                 flamethrower__minRadiusForSphereCast, flamethrower__numTracesSphereCast)

  flamethrower__active = evt.gctrl.shoot && canShoot
  using() <| $(var gctrl : GunControls#)
    gctrl.shoot = flamethrower__active
    gctrl.timeStep = evt.gctrl.timeStep
    sendEventImmediate(eid, [[CmdGunUpdate atTime=evt.atTime, isForReal=evt.isForReal, seed=phys_time_to_seed(evt.atTime), gctrl := gctrl, gloc=evt.gloc]])

[es(tag=netClient, REQUIRE=flamethrower__fireTemplate)]
def flamethrower_phys_client(evt : CmdWeapPhysUpdate; eid : EntityId; gun__isOverheat : bool = false)
  if evt.isForReal
    using() <| $(var gctrl : GunControls#)
      gctrl.shoot = evt.gctrl.shoot && !gun__isOverheat
      gctrl.timeStep = evt.gctrl.timeStep
      sendEventImmediate(eid, [[CmdGunUpdate atTime=evt.atTime, isForReal=evt.isForReal, seed=phys_time_to_seed(evt.atTime), gctrl := gctrl, gloc=evt.gloc]])

[es(on_appear)]
def flamethrower_init(evt : Event;
                      flamethrower__maxFlameLength : float;
                      flamethrower__maxFlameLengthTime : float;
                      var flamethrower__flameSpeed : float&)
  flamethrower__flameSpeed = safediv(flamethrower__maxFlameLength, flamethrower__maxFlameLengthTime)

[es(tag=server, track=human_weap__throwMode)]
def throw_mode_disable_flamethrower(evt : Event; human_weap__throwMode : bool; human_weap__currentGunEid : EntityId)
  if human_weap__throwMode
    query(human_weap__currentGunEid) <| $ [es] (var flamethrower__active : bool&)
      flamethrower__active = false