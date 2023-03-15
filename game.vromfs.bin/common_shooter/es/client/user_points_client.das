require ecs
require EnlistedNet
require game.events_game
require common_shooter.events_common_shooter
require Dacoll
require DagorMath
require CollRes
require PhysMat
require common_shooter.es.user_points_common
require EnlistedCamera

def try_set_mark_from_vehicle(vehicle_eid : EntityId; player_eid : EntityId; mark_type : string; ray_mat : int)
  var wasSet = false
  query(vehicle_eid) <| $ [es] (turretAimPos : float3; isTurretAimPosValid : bool)
    if isTurretAimPosValid
      query(get_cur_cam_entity()) <| $ [es] (transform aka camera_transform : float3x4)
        let from = camera_transform[3]
        let dir = normalize(turretAimPos - from)
        set_mark(mark_type, player_eid, from, dir, ray_mat)
        wasSet = true
  return wasSet

def on_cmd_set_mark(player, possessed : EntityId; always_enemy : bool)
  let isExistsAndAlive = query(possessed) <| $ [es(REQUIRE_NOT=deadEntity)] (human__aimTm : float3x4;
                                                                             human_anim__vehicleSelected : EntityId;
                                                                             human_weap__currentGunEid : EntityId;
                                                                             human_net_phys__isAiming : bool;
                                                                             camera__lookDir : float3 = float3())
    let markType = human_net_phys__isAiming || always_enemy ? "enemy" : "main"
    let aimRayMatId = get_int(human_weap__currentGunEid, "gun__aimRayMatId") ?? PHYSMAT_INVALID
    if !try_set_mark_from_vehicle(human_anim__vehicleSelected, player, markType, aimRayMatId)
      set_mark(markType, player, human__aimTm[3], human_net_phys__isAiming ? human__aimTm[0] : camera__lookDir, aimRayMatId)
  if !isExistsAndAlive
    find_query() <| $ [es(REQUIRE=spectator__target)] (transform : float3x4)
      let markType = always_enemy ? "enemy" : "main"
      set_mark(markType, player, transform[3], transform[2])
      return true

[es(tag = gameClient, on_event=CmdSetMarkEnemy)]
def on_cmd_set_mark_enemy(evt : Event; eid, possessed : EntityId)
  on_cmd_set_mark(eid, possessed, true)

[es(tag = gameClient, on_event=CmdSetMarkMain)]
def on_cmd_set_mark_main(evt : Event; eid, possessed : EntityId)
  on_cmd_set_mark(eid, possessed, false)

[es(tag = gameClient)]
def on_cmd_create_map_point(evt : CmdCreateMapPoint; eid : EntityId; possessed : EntityId)
  let len = 500.0
  let x = evt.x
  let z = evt.z
  var upmostPos = float3(x, len, z)
  let traceDir = float3(0.0, -1.0, 0.0)
  var norm : float3
  var t = len
  var pmid : int
  var rendInstDesc = RendInstDesc()
  query(possessed) <| $ [es] (human_weap__currentGunEid : EntityId)
    var aimRayMatId = PHYSMAT_INVALID
    query(human_weap__currentGunEid) <| $ [es] (gun__aimRayMatId : int)
      aimRayMatId = gun__aimRayMatId

    traceray_normalized(upmostPos, traceDir, t, pmid, norm, ETF_DEFAULT, rendInstDesc, aimRayMatId)
    upmostPos.y = t >= 0.0 ? len - t : 0.0
  send_net_event(eid, [[CmdCreateMapUserPoint pos = upmostPos, dir = traceDir, norm = norm, item_name = "way_point", markOwnerEid = INVALID_ENTITY_ID ]])

[es(tag=gameClient, no_order, REQUIRE_NOT=userPointVehicleOffset)]
def userpoint_update_vehicle_marker_position(act : UpdateStageInfoAct; userPointVehicleTargetEid : EntityId; var transform aka userpoint_transform : float3x4&)
  query(userPointVehicleTargetEid) <| $ [es(REQUIRE=vehicle)] (transform : float3x4; collres : CollisionResource)
    userpoint_transform[3] = transform * BBox3(collres.vFullBBox).center

[es(tag=gameClient, no_order)]
def userpoint_update_point_on_vehicle_marker_position(act : UpdateStageInfoAct;
                                                      userPointVehicleTargetEid : EntityId;
                                                      var transform aka userpoint_transform : float3x4&;
                                                      userPointVehicleOffset : float3)
  query(userPointVehicleTargetEid) <| $ [es(REQUIRE=vehicle)] (transform : float3x4)
    userpoint_transform[3] = transform * userPointVehicleOffset
