require turrets
require ecs
require ecs.common
require math.base
require vehicle
require EnlistedWeapon
require PhysVars
require game.utils.hero
require game.es.vehicle.vehicle_seats_common
require game.es.events
require common_shooter.events_common_shooter
require dm
require DagorMath
require DagorMathUtils
require AnimV20
require GeomNodeTree
require common_shooter.es.vehicle.vehicle_turret_common
require enlisted.events_enlisted
require AnimatedPhys

[es(on_event=CmdTurretsUpdate, after=turret_weap_apply_client_controls_es)]
def turret_weap_reset_shoot(evt : Event;
                            vehicle_seats__seatEids : EidList;
                            turret_control__gunEids : EidList)
  let turretsMask = get_turret_control_mask(vehicle_seats__seatEids)
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE=resolvedTurret)] (turret__id : int; var turret_aim__shootFlag : bool&)
      turret_aim__shootFlag &&= can_control_turret(turretsMask, turret__id)

[es(tag=server, on_event=CmdTurretsUpdate, REQUIRE_NOT=deadEntity)]
def turret_weap_can_shoot_updater(evt : Event;
                                  vehicle__isUnderwater : bool = false;
                                  turret_control__gunEids : EidList;
                                  damage_model : DamageModel)
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_dm_part__barrelDm, turret_dm_part__breechDm : int;
                                                        var turret__isBroken : bool&;
                                                        var turret__isUnderwater : bool&)
      let barrelDm = turret_dm_part__barrelDm
      let breechDm = turret_dm_part__breechDm
      if barrelDm >= 0
        turret__isBroken = int(get_rel_hp_fixed(damage_model.dmData, barrelDm)) <= 0
      if breechDm >= 0 && !turret__isBroken
        turret__isBroken = int(get_rel_hp_fixed(damage_model.dmData, breechDm)) <= 0

      turret__isUnderwater = vehicle__isUnderwater


def get_dm_part_hp(damage_model : DamageModel; part_no, var_id : int) : float
  return part_no >= 0 && var_id >= 0 ? float(get_rel_hp_fixed(damage_model.dmData, part_no)) / float(MAX_REL_HP_FIXED) : 1.f;


[es(tag=server, on_event=CmdTurretsUpdate, before=turret_weap_can_shoot_updater, REQUIRE_NOT=deadEntity)]
def update_turret_aim_drives_mult(evt : Event;
                                  turret_control__gunEids : EidList;
                                  damage_model : DamageModel;
                                  vehicle_mods__maxHorDriveMult : float = 1.0;
                                  vehicle_mods__maxVerDriveMult : float = 1.0)
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_drive_dm_part__horDriveDm, turret_drive_dm_part__verDriveDm, turret__yawSpeedMulVarId, turret__pitchSpeedMulVarId : int; var turret_aim_drives_mult : TurretAimDrivesMult)
      let horDriveRelHp = get_dm_part_hp(damage_model, turret_drive_dm_part__horDriveDm, turret__yawSpeedMulVarId)
      let verDriveRelHp = get_dm_part_hp(damage_model, turret_drive_dm_part__verDriveDm, turret__pitchSpeedMulVarId)
      set_aim_mult_yaw(turret_aim_drives_mult, vehicle_mods__maxHorDriveMult * horDriveRelHp)
      set_aim_mult_pitch(turret_aim_drives_mult, vehicle_mods__maxVerDriveMult * verDriveRelHp)


[es(on_event=CmdTurretsUpdate, REQUIRE_NOT=deadEntity)]
def turret_set_angles_es(evt : Event;
                         turret_control__gunEids : EidList;
                         var phys_vars : PhysVars)
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE=resolvedTurret)] (turret__owner : EntityId;
                                                        turret__wishYawVarId : int;
                                                        turret__wishPitchVarId : int;
                                                        turret__aimNodeId : int;
                                                        turret__limitsTable : Point4List const? = null;
                                                        turret_state : TurretState)
      if turret__wishYawVarId >= 0 && turret__wishPitchVarId >= 0
        var wishAngles = turret_state.wishAngles
        if turret__limitsTable != null && turret__aimNodeId >= 0
          query(turret__owner) <| $ [es] (animchar : AnimcharBaseComponent)
            let ang = float2(-wishAngles.x, wishAngles.y)
            var dir = angles_to_dir(ang)
            let parNodeId = geomtree_getParentNodeIdx(*animchar.nodeTree, turret__aimNodeId)

            var mx : float3x4

            if parNodeId >= 0
              var tm : float3x4
              var wt : float3x4

              *animchar.originalNodeTree |> geomtree_getNodeTmScalar(turret__aimNodeId, tm)
              *animchar.nodeTree |> geomtree_getNodeWtmRelScalar(parNodeId, wt)

              mx  = wt * tm
              dir = rotate(inverse(mx), dir)
            else
              identity(mx)

            wishAngles.x = -rad_to_deg(atan2(dir.z, dir.x))
            wishAngles.y = +rad_to_deg(atan2(dir.y, length(float2(dir.x, dir.z))))

            for lim in *turret__limitsTable
              if (wishAngles.x > lim.x && wishAngles.x < lim.y)
                wishAngles.x = clamp(wishAngles.x, lim.x, lim.y)
                wishAngles.y = clamp(wishAngles.y, lim.z, lim.w)

            wishAngles.x = deg_to_rad(wishAngles.x)
            wishAngles.y = deg_to_rad(wishAngles.y)

            dir = rotate(mx, angles_to_dir(wishAngles))

            wishAngles   = dir_to_angles(dir)
            wishAngles.x = -wishAngles.x

        setVar(phys_vars, turret__wishYawVarId, rad_to_deg(wishAngles.x))
        setVar(phys_vars, turret__wishPitchVarId, rad_to_deg(wishAngles.y))

def turret_get_angles(transform : float3x4;
                      turret_control__gunEids : EidList;
                      net_phys__timeStep : float;
                      phys_vars : PhysVars)
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE=resolvedTurret)] (turret__curYawVarId : int;
                                                        turret__curPitchVarId : int;
                                                        turret__curWorldYawVarId : int;
                                                        turret__curWorldPitchVarId : int;
                                                        var turret_state : TurretState)
      var curAngles = float2()
      if turret__curWorldYawVarId >= 0 && turret__curWorldPitchVarId >= 0
        curAngles = float2(deg_to_rad(getVar(phys_vars, turret__curWorldYawVarId)),
                           deg_to_rad(getVar(phys_vars, turret__curWorldPitchVarId)))
      elif turret__curYawVarId >= 0 && turret__curPitchVarId >= 0
        curAngles = float2(-deg_to_rad(getVar(phys_vars, turret__curYawVarId)),
                            deg_to_rad(getVar(phys_vars, turret__curPitchVarId)))
        let dir = normalize(rotate(transform, angles_to_dir(curAngles)))
        curAngles = dir_to_angles(dir)
      turret_state.speed  = (curAngles - turret_state.angles) * safeinv(net_phys__timeStep)
      turret_state.angles = curAngles

[es(tag=server, on_event=CmdTurretsUpdate, before=turret_shoot_tm_save_es, REQUIRE_NOT=(heroVehicle, deadEntity))]
def turret_get_angles_es(evt : Event;
                         transform : float3x4;
                         turret_control__gunEids : EidList;
                         net_phys__timeStep : float;
                         phys_vars : PhysVars)
  turret_get_angles(transform, turret_control__gunEids, net_phys__timeStep, phys_vars)

// To work correctly we need this order:
// update phys (interpolate transform) -> update animchar -> anim_phys_update -> turret_get_angles -> turret_shoot_tm_save_es
// Although actual order in frame will be like this, its still valid:
// anim_phys_update -> turret_get_angles -> turret_shoot_tm_save_es -> update phys (interpolate transform) -> update animchar
// Important part is to apply aim angles (calculated by animchar aim controller) to the same transform matrix which was used by animchar
[es(on_event=CmdTurretsUpdate, REQUIRE=heroVehicle, before=turret_shoot_tm_save_es, REQUIRE_NOT=deadEntity)]
def turret_get_angles_client_es(evt : Event;
                                transform : float3x4;
                                turret_control__gunEids : EidList;
                                net_phys__timeStep : float;
                                var animchar : AnimcharBaseComponent;
                                var anim_phys : AnimatedPhys;
                                var phys_vars : PhysVars)
  anim_phys_update(anim_phys, animchar, phys_vars) // To get the most actual vars
  turret_get_angles(transform, turret_control__gunEids, net_phys__timeStep, phys_vars)

def send_turrets_update_event(eid, tick, dt)
  sendEventImmediate(eid, [[CmdTurretsUpdate tick=tick, dt=dt]])

[es(REQUIRE=turret_control__gunEids)]
def turret_post_phys_update_es(evt : CmdPostPhysUpdate;
                               eid : EntityId;
                               phys__isAsleep : bool = false)
  if evt.isForReal && !phys__isAsleep
    send_turrets_update_event(eid, evt.tick, evt.dt)

[es(REQUIRE=turret_control__gunEids)]
def turret_post_phys_update_remote_shadow_es(evt : CmdPostPhysUpdateRemoteShadow;
                                             eid : EntityId;
                                             phys__isAsleep : bool = false)
  if !phys__isAsleep
    send_turrets_update_event(eid, evt.tick, evt.dt)

[es(tag=server, on_appear, before=turret_gun_es, REQUIRE=isTurret)]
def turret_gun_init_max_ammo(evt : Event; var gun__maxAmmo : int&; gun__shellsAmmo : Array)
  if gun__maxAmmo > 0
    return
  gun__maxAmmo = 0
  for shellsAmmo in gun__shellsAmmo
    gun__maxAmmo += get_int(shellsAmmo) ?? 0

[es(tag=server, on_appear, after=turret_gun_es, before=turret_gun_ammo_by_shell_es, REQUIRE=isTurret)]
def turret_gun_init_total_ammo_es(evt : Event;
                                  gun__ammo : int;
                                  gun__ammo_by_shell : IntList;
                                  var gun__totalAmmo : int&)
  if length(gun__ammo_by_shell) > 0
    gun__totalAmmo = gun__ammo_by_shell[0] - gun__ammo

[es(tag=server, track=gun__ammo)]
def turret_gun_ammo_by_shell_es(evt : Event;
                                gun__ammo : int;
                                var gun__ammo_by_shell : IntList&;
                                gun__totalAmmo : int;
                                currentBulletId : int = 0;
                                lastBulletId : int = 0)
  if currentBulletId == lastBulletId && lastBulletId < length(gun__ammo_by_shell)
    gun__ammo_by_shell[lastBulletId] = gun__totalAmmo + gun__ammo

[es(tag=server, after=turret_gun_ammo_by_shell_es, track=currentBulletId)]
def turret_on_change_current_shell_es(evt : Event;
                                      var gun__ammo : int&;
                                      var lastBulletId : int&;
                                      var gun__totalAmmo : int&;
                                      currentBulletId : int;
                                      gun__ammo_by_shell : IntList;
                                      gun__reloadable : bool = false)
  if gun__reloadable
    return
  if currentBulletId < length(gun__ammo_by_shell)
    gun__ammo = gun__ammo_by_shell[currentBulletId]
    gun__totalAmmo = 0
  lastBulletId = currentBulletId

[es(tag=server, after=turret_gun_ammo_by_shell_es, track=currentBulletId)]
def turret_on_change_current_shell_reloadable_es(evt : Event;
                                                 currentBulletId : int;
                                                 var gun__ammo : int&;
                                                 var lastBulletId : int&;
                                                 var gun__totalAmmo : int&;
                                                 gun__ammo_by_shell : IntList;
                                                 gun__reloadable : bool = false)
  if !gun__reloadable || currentBulletId == lastBulletId
    return
  if currentBulletId < length(gun__ammo_by_shell)
    gun__ammo = 0
    gun__totalAmmo = gun__ammo_by_shell[currentBulletId]
  lastBulletId = currentBulletId