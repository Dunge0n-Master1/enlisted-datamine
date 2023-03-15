require ecs
require Gun
require game.utils.team
require common_shooter.events_common_shooter
require common_shooter.es.flamethrower_common
require enlisted.events_enlisted

[es(tag=input, REQUIRE=(resolvedTurret, flamethrower__active), after=vehicle_input_gunner_es, before=vehicle_input_gunner_turret_with_group_es)]
def shoot_to_overheat_turret_es(info : ParallelUpdateFrameDelayed;
                                turret_aim__shootFlag : bool;
                                gun__isOverheat : bool;
                                var turret_input__shootFlag : bool&)
  turret_input__shootFlag ||= turret_aim__shootFlag && !gun__isOverheat

[es(tag=server, after=flamethrower_extinguish_under_water)]
def flamethrower_turret_phys(evt : CmdGunUpdate;
                             gun__ammo : int;
                             gun : Gun;
                             var flamethrower__flameCurrentLength : float&;
                             var flamethrower__active : bool&;
                             var flamethrower__hitAnything : bool?;
                             gun__owner : EntityId;
                             turret__owner : EntityId;
                             gun__propsId : int = -1;
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
  query(turret__owner) <| $ [es] (net_phys__timeStep : float)
    let dt = net_phys__timeStep
    let canShoot = gun__ammo > 0 && !flamethrower__underwater && gun.curState.loaded
    if !evt.gctrl.shoot
      flamethrower__flameCurrentLength = 0.0
      if flamethrower__hitAnything != null
        *flamethrower__hitAnything = false
    elif canShoot
      let flameDamage = [[FlameDamage offender                = gun__owner,
                                      offenderTeam            = get_int(gun__owner, "team") ?? TEAM_UNASSIGNED,
                                      streamDamage            = dt * flamethrower__streamDamagePerSecond,
                                      cloudDamage             = dt * flamethrower__cloudDamagePerSecond,
                                      friendlyStreamDamage    = dt * flamethrower__friendlyStreamDamagePerSecond,
                                      friendlyCloudDamage     = dt * flamethrower__friendlyCloudDamagePerSecond,
                                      shouldSetFriendlyOnFire = flamethrower__shouldSetFriendlyOnFire,
                                      gunPropsId              = gun__propsId]]
      let dropletsSpread = [[DropletSpread yaw          = flamethrower__dropletSpreadYaw,
                                           pitchMin     = flamethrower__dropletSpreadPitchMin,
                                           pitchMax     = flamethrower__dropletSpreadPitchMax,
                                           maxLength    = flamethrower__dropletLength,
                                           normalOffset = flamethrower__dropletNormalOffset]]
      if evt.gloc.gunPos != null
        let gunPos = *(evt.gloc.gunPos)
        shoot_fire(dt, gunPos, evt.gloc.gunDir, flamethrower__fireTemplate,
                   flamethrower__flameStreamRadius, flamethrower__flameCloudRadius,
                   flamethrower__minBetweenFireDist, flamethrower__additionalCheckDistance,
                   flameDamage, flamethrower__flameStartOffset, flamethrower__cloudStartOffset,
                   flamethrower__maxFlameLength, flamethrower__flameSpeed,
                   dropletsSpread, flamethrower__addFullForceTimePerSec, flamethrower__maxFiresToReignite,
                   flamethrower__flameCurrentLength, flamethrower__hitAnything, turret__owner,
                   flamethrower__minRadiusForSphereCast, flamethrower__numTracesSphereCast)
    flamethrower__active = evt.gctrl.shoot && canShoot

[es(tag=server, track=gun__owner)]
def disable_flamethrower_turret(evt : Event; gun__owner : EntityId; var flamethrower__active : bool&)
  flamethrower__active &&= !!gun__owner