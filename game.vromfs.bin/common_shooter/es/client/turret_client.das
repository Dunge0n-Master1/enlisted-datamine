require ecs
require turrets
require common_shooter.events_common_shooter
require game.es.vehicle.vehicle_seats_common
require enlisted.events_enlisted
require EnlistedCamera
require DagorMathUtils
require GridCollision
require CollisionTraces
require Dacoll
require AnimV20


[es(after=turret_update_visual_shoot_tm_es, REQUIRE=resolvedTurret)]
def vehicle_input_turret_init_es(info : UpdateStageInfoAct;
                                 turret__owner : EntityId;
                                 var turret__isGunDirInited : bool&;
                                 var turret_input__aimPos : float3&;
                                 var turret_input__aimAngles : float2&)
  if !turret__isGunDirInited
    query(turret__owner) <| $ [es] (turret_current_visual_shoot_tm : float3x4)
      turret_input__aimAngles = dir_to_angles(turret_current_visual_shoot_tm[0])

      let dir = angles_to_dir(turret_input__aimAngles)
      query(get_cur_cam_entity()) <| $ [es] (transform aka camera_transform : float3x4)
        var aimDist = 500.0
        var norm = float3()
        traceray_normalized(camera_transform[3], dir, aimDist, norm, ETF_ALL)
        trace_entities_in_grid(ecs_hash("humans"), camera_transform[3], dir, aimDist, INVALID_ENTITY_ID)
        trace_entities_in_grid(ecs_hash("vehicles"), camera_transform[3], dir, aimDist, INVALID_ENTITY_ID)

        turret_input__aimPos = camera_transform[3] + dir * aimDist
        turret__isGunDirInited = true


def do_turret_trace(from : float3;
                    dir : float3;
                    var t : float&;
                    ignore_eid : EntityId;
                    vehicle_seats__seatEids : EidList)
  var norm : float3
  traceray_normalized(from, dir, t, norm)

  using() <| $(var intersections : IntersectedEntities#)
    trace_entities_in_grid(ecs_hash("humans"), from, dir, t, ignore_eid, intersections, SortIntersections NO)
    trace_entities_in_grid(ecs_hash("vehicles"), from, dir, t, ignore_eid, intersections, SortIntersections YES)
    for intersection in intersections
      if !is_vehicle_contain_owner(intersection.eid, vehicle_seats__seatEids)
        t = intersection.t
        break


[es(tag=gameClient, REQUIRE=(heroVehicle, turretsCorrection))]
def turret_shoot_correction_es(evt : ParallelUpdateFrameDelayed;
                               eid : EntityId;
                               isAlive : bool = true;
                               vehicle_seats__seatEids : EidList;
                               turret_control__gunEids : EidList;
                               turret_aim__shootRange : float = 0.0)
  if isAlive
    var turretsCount = 0
    var midGunPos = float3()
    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, turretInput))] (turret_state : TurretState)
        midGunPos += turret_state.shoot.pos
        ++turretsCount

    if turretsCount > 0
      midGunPos /= float(turretsCount)

    query(get_cur_cam_entity()) <| $ [es] (transform aka camera_transform : float3x4; camera__target : EntityId)
      let camPos = camera_transform[3]
      for gunEid in turret_control__gunEids
        query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, turretInput))] (turret_state : TurretState;
                                                                        var turret_aim__shootDirWithCorrection : float3&)
          let turretDir = turret_state.shoot.dir
          let turretPos = turret_state.shoot.pos

          var t = 500.0
          var tracePos = camPos
          query(camera__target) <| $ [es] (human_net_phys__isAiming : bool; human_weap__currentGunEid : EntityId)
            if human_net_phys__isAiming
              query(human_weap__currentGunEid) <| $ [es] (animchar : AnimcharBaseComponent; animchar_bsph : vec4f)
                var tm : float3x4
                animchar_get_tm(animchar, tm)
                tracePos = tm[3] + camera_transform[2] * animchar_bsph.w
          do_turret_trace(tracePos, turretDir, t, eid, vehicle_seats__seatEids)

          var distToShootRange = 0.0
          if t < turret_aim__shootRange
            distToShootRange = turret_aim__shootRange - t
          elif turret_aim__shootRange > 0.0f
            t = turret_aim__shootRange

          if t > 0.01
            turret_aim__shootDirWithCorrection = normalize(camPos + turretDir * (t + distToShootRange) - turretPos +
              (camPos - midGunPos) * (distToShootRange / t))
          else
            turret_aim__shootDirWithCorrection = turretDir