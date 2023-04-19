require ecs
require vehicle
require turrets
require DngActor
require DaWeapons
require DagorMath
require DagorSystem
require BallisticsProps
require enlisted.events_enlisted


[es(after=after_guns_update_sync, before=clear_gun_launch_events_es)]
def turret_recoil_apply_force_es(info : ParallelUpdateFrameDelayed;
                                 transform : float3x4;
                                 turret_control__gunEids : EidList;
                                 isAlive : bool;
                                 var vehicle_net_phys : VehiclePhysActor?)
  if !isAlive
    return

  let itm = inverse(transform)

  for turreEid in turret_control__gunEids
    query(turreEid) <| $ [es(REQUIRE=resolvedTurret)] (gun_launch_events : GunLaunchEvents;
                                                       turret_state : TurretState;
                                                       gun__recoilAmount : float = 0.0;
                                                       var turret_recoil__startTime : float?)
      for event in gun_launch_events.launchEvents
        if turret_recoil__startTime != null
          *turret_recoil__startTime = event.atTime

        if vehicle_net_phys != null && vehicle_net_phys.role != NetRole ROLE_REMOTELY_CONTROLLED_SHADOW
          projectile_get_props(int(event.shellId.shellId)) <| $(bulletProps : ProjectileProps)
            let recoilMultiplier = gun__recoilAmount
            let propellantSpeed = 1500.0
            let propellantWeightProportion = 1.0

            let pos = itm * turret_state.shoot.pos
            let recoil = ((length(event.vel) * bulletProps.mass +
                          propellantSpeed * propellantWeightProportion * bulletProps.mass) *
                          safeinv(info.dt) * recoilMultiplier)
            let impulse = -normalize(event.vel) * recoil

            let force = rotate(itm, impulse)
            vehicle_net_phys.phys |> addForce(pos, force)