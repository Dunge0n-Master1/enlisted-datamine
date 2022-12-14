module user_points_common shared
require ecs
require app
require game.utils.team
require EnlistedNet
require common_shooter.events_common_shooter
require Dacoll
require PhysMat


def find_and_delete_point(player_eid : EntityId; trace_pos, trace_dir : float3)
  var result = false
  query() <| $ [es(REQUIRE=hudUserPoint)] (eid, userPointOwner : EntityId;
                                           transform : float3x4;
                                           deleteAngle : float;
                                           userPointVehicleTargetEid : EntityId = INVALID_ENTITY_ID;
                                           timer__delta : float;
                                           team aka point_owner_team : int;
                                           var timer__destroy : float&)
    if userPointOwner !=  player_eid
      return
    let dir = normalize(transform[3] - trace_pos)
    let dist = distance(transform[3], trace_pos)
    let angle = 1.0 - dot(dir, trace_dir)
    if angle * max(dist, 1.0) < deleteAngle
      var needDeleteMapUserPoint = true
      query(userPointVehicleTargetEid) <| $ [es] (team : int)
        if team != point_owner_team && team != TEAM_UNASSIGNED
          timer__destroy = get_sync_time() + timer__delta
          needDeleteMapUserPoint = false
      if needDeleteMapUserPoint
        send_net_event(eid, [[CmdDeleteMapUserPoint]])
      result = true
  return result


def set_mark(name : string; player_eid : EntityId; trace_pos, trace_dir : float3; ray_mat_id : int; mark_owner_eid : EntityId)
  let dst = 2000.0
  var t = dst
  var norm : float3
  var pmid : int
  var rendInstDesc = RendInstDesc()
  traceray_normalized(trace_pos, trace_dir, t, pmid, norm, ETF_DEFAULT, rendInstDesc, ray_mat_id)
  let markPos = t < dst ? trace_pos + trace_dir * t : float3()
  if !find_and_delete_point(player_eid, trace_pos, trace_dir)
    send_net_event(player_eid, [[CmdCreateMapUserPoint pos = markPos, dir = trace_dir, norm = norm, item_name = name, markOwnerEid = mark_owner_eid ]])


def set_mark(name : string; player_eid : EntityId; trace_pos, trace_dir : float3)
  set_mark(name, player_eid, trace_pos, trace_dir, PHYSMAT_INVALID, INVALID_ENTITY_ID)


def set_mark(name : string; player_eid : EntityId; trace_pos, trace_dir : float3; ray_mat_id : int)
  set_mark(name, player_eid, trace_pos, trace_dir, ray_mat_id, INVALID_ENTITY_ID)


def set_mark(name : string; player_eid : EntityId; trace_pos, trace_dir : float3; mark_owner_eid : EntityId)
  set_mark(name, player_eid, trace_pos, trace_dir, PHYSMAT_INVALID, mark_owner_eid)