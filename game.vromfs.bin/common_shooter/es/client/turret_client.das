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
require math.base

[es(tag=input, on_appear, REQUIRE=turret_input__aimPos)]
def vehicle_input_reset_turret_dir_on_control_gain(evt : Event; var turret__isGunDirInited : bool&)
  turret__isGunDirInited = false

[es(after=turret_update_visual_shoot_tm_es, REQUIRE=resolvedTurret)]
def vehicle_input_turret_init_es(info : ParallelUpdateFrameDelayed;
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


def do_turret_grid_trace(from : float3;
                         dir : float3;
                         var t : float&;
                         ignore_eid : EntityId;
                         vehicle_seats__seatEids : EidList)
  using() <| $(var intersections : IntersectedEntities)
    trace_entities_in_grid(ecs_hash("humans"), from, dir, t, ignore_eid, intersections, SortIntersections NO)
    trace_entities_in_grid(ecs_hash("vehicles"), from, dir, t, ignore_eid, intersections, SortIntersections YES)
    for intersection in intersections
      if !is_vehicle_contain_owner(intersection.eid, vehicle_seats__seatEids)
        t = intersection.t
        break

[es(tag=gameClient, before=turret_shoot_correction_traces_start_job_es, REQUIRE=(turretsCorrectionUseThreadPool, heroVehicle, turretsCorrection))]
def turret_shoot_correction_prepare_pos_es(evt : ParallelUpdateFrameDelayed;
                                           turret_control__gunEids : EidList;
                                           isAlive : bool = true)
  if isAlive
    query(get_cur_cam_entity()) <| $ [es] (transform aka camera_transform : float3x4; camera__target : EntityId)
      let camPos = camera_transform[3]
      for gunEid in turret_control__gunEids
        query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, turretInput))] (turret_state : TurretState;
                                                                        var turret_aim__shootCorrectionDir : float3&;
                                                                        var turret_aim__shootCorrectionPos : float3&)
          if length_sq(turret_state.shoot.dir) > FLT_EPSILON
            turret_aim__shootCorrectionDir = turret_state.shoot.dir
            turret_aim__shootCorrectionPos = camPos
            query(camera__target) <| $ [es] (human_net_phys__isAiming : bool; human_weap__currentGunEid : EntityId)
              if human_net_phys__isAiming
                query(human_weap__currentGunEid) <| $ [es] (animchar : AnimcharBaseComponent; animchar_bsph : vec4f)
                  var tm : float3x4
                  animchar_get_tm(animchar, tm)
                  turret_aim__shootCorrectionPos = tm[3] + camera_transform[2] * animchar_bsph.w

[es(tag=gameClient, after=turret_shoot_correction_traces_wait_job_es, REQUIRE=(heroVehicle, turretsCorrection, turretsCorrectionUseThreadPool))]
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

    let cameraTm = get_cur_cam_entity() |> get_TMatrix("transform") ?? IDENT_TM
    let camPos = cameraTm[3]

    for gunEid in turret_control__gunEids
      query(gunEid) <| $ [es(REQUIRE=(resolvedTurret, turretInput))] (turret_state : TurretState;
                                                                      turret_aim__shootCorrectionPos : float3;
                                                                      turret_aim__shootCorrectionDir : float3;
                                                                      var turret_aim__shootDirWithCorrection : float3&;
                                                                      var turret_aim__correctionTraceLen : float&)
        do_turret_grid_trace(turret_aim__shootCorrectionPos, turret_aim__shootCorrectionDir, turret_aim__correctionTraceLen, eid, vehicle_seats__seatEids)

        var distToShootRange = 0.0
        if turret_aim__correctionTraceLen < turret_aim__shootRange
          distToShootRange = turret_aim__shootRange - turret_aim__correctionTraceLen
        elif turret_aim__shootRange > 0.0f
          turret_aim__correctionTraceLen = turret_aim__shootRange

        if turret_aim__correctionTraceLen > 0.01
          let turretPos = turret_state.shoot.pos
          turret_aim__shootDirWithCorrection = normalize(camPos + turret_aim__shootCorrectionDir * (turret_aim__correctionTraceLen + distToShootRange) - turretPos +
            (camPos - midGunPos) * (distToShootRange / turret_aim__correctionTraceLen))
        else
          turret_aim__shootDirWithCorrection = turret_aim__shootCorrectionDir

