require ecs
require ecs.common
require vehicle
require turrets
require EnlistedWeapon
require PhysVars
require math.base
require DagorMath
require game.utils.hero
require game.es.vehicle.vehicle_seats_common
require DagorMathUtils
require common_shooter.es.vehicle.vehicle_turret_common
require game.utils.team
require enlisted.events_enlisted

def get_aim_yaw_delta_deg(turret_state : TurretState)
  let wishYaw = renorm_ang(-turret_state.wishAngles.x, turret_state.angles.x)
  let curYaw = turret_state.angles.x
  return rad_to_deg(abs(wishYaw - curYaw))

[es(no_order)]
def turret_aim_activate_es(info : ParallelUpdateFrameDelayed;
                           animchar__updatable : bool;
                           vehicle_seats__seatEids : EidList;
                           turret_control__gunEids : EidList;
                           var phys_vars : PhysVars)
  if !animchar__updatable
    return
  let turretsMask = get_turret_control_mask(vehicle_seats__seatEids)
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE=resolvedTurret)] (turret__id, turret__turretAimActiveVarId, turret__yawSpeedMulVarId, turret__pitchSpeedMulVarId : int;
                                                        turret_aim_drives_mult : TurretAimDrivesMult;
                                                        turret_state : TurretState;
                                                        turret_guidance__reductionAtYawAngleDeg : float = 5.0;
                                                        turret_guidance__pitchMultWhenAimingYaw : float = 1.0)
      if turret__turretAimActiveVarId < 0
        return
      let canTurretControl = can_control_turret(turretsMask, turret__id)
      let aimDrivesMult = turret_aim_drives_mult.aimDrivesMult
      if turret__yawSpeedMulVarId >= 0
        setVar(phys_vars, turret__yawSpeedMulVarId, aimDrivesMult.x)
      var pitchMult = aimDrivesMult.y
      if turret_guidance__pitchMultWhenAimingYaw < 1.0 && get_aim_yaw_delta_deg(turret_state) >= turret_guidance__reductionAtYawAngleDeg
        pitchMult *= turret_guidance__pitchMultWhenAimingYaw
      if turret__pitchSpeedMulVarId >= 0
        setVar(phys_vars, turret__pitchSpeedMulVarId, pitchMult)
      setVar(phys_vars, turret__turretAimActiveVarId, canTurretControl ? 1.f : 0.f)


[es(after=turret_aim_activate_es, REQUIRE=movableCannon)]
def movable_turret_reset_aim_yaw_es(info : ParallelUpdateFrameDelayed;
                                    animchar__updatable : bool;
                                    vehicle_seats__seatEids : EidList;
                                    vehicle_seats__restrictToTeam : int;
                                    turret_control__gunEids : EidList;
                                    transform : float3x4;
                                    var phys_vars : PhysVars)
  if !animchar__updatable
    return
  let turretsMask = get_turret_control_mask(vehicle_seats__seatEids)
  for turretEid in turret_control__gunEids
    query(turretEid) <| $ [es(REQUIRE=resolvedTurret)] (turret__id, turret__turretAimActiveVarId : int;
                                                        turret__wishYawVarId : int;
                                                        turret__curYawVarId : int)
      if turret__turretAimActiveVarId < 0
        return
      let canTurretControl = can_control_turret(turretsMask, turret__id)
      if !canTurretControl && vehicle_seats__restrictToTeam != TEAM_UNASSIGNED
        //before turning off the movement of the barrel, first return it to zero
        setVar(phys_vars, turret__turretAimActiveVarId, 1.f)
        let wishDir = rotate(transform, float3(1.f, 0.f, 0.f))
        let wishYaw = -rad_to_deg(dir_to_angles(wishDir).x)
        let currentYaw = getVar(phys_vars, turret__curYawVarId)
        if !is_equal_float(currentYaw, wishYaw)
          setVar(phys_vars, turret__wishYawVarId, wishYaw)
        else
          setVar(phys_vars, turret__turretAimActiveVarId, 0.f)
