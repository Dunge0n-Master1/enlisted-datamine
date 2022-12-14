require ecs
require DagorSystem
require app
require math
require DagorMath
require DagorMathUtils
require vehicle
require AnimV20
require GeomNodeTree

def collect_affected_optics(pos : float3;
                            eid : ecs::EntityId;
                            cylinder_radius : float;
                            cylinder_height : float;
                            cylinder_bottom_offset : float;
                            var out_affected_optics : ecs::IntList)
  query(eid) <| $ [es] (animchar : AnimcharBaseComponent; vehicle_seats__seatEids : EidList)
    for seatNo in iter_range(vehicle_seats__seatEids)
      let node = get_int(vehicle_seats__seatEids[seatNo], "seat__cameraNodeNo") ?? -1
      if node < 0
        continue
      var wtm : float3x4
      geomtree_getNodeWtmScalar(*animchar.nodeTree, node, wtm)
      let opticPos = wtm[3]
      let opticDir = normalize(wtm[0]) * cylinder_radius

      let p0 = opticPos
      let p1 = opticPos + opticDir
      let cylinder_p0 = pos + float3(0.0, cylinder_bottom_offset, 0.0)
      let cylinder_p1 = pos + float3(0.0, cylinder_height, 0.0)
      if test_segment_cylinder_intersection(p0, p1, cylinder_p0, cylinder_p1, cylinder_radius)
        push(out_affected_optics, seatNo)

def calc_fire_size(time : float; start_time : float; spread_time : float; full_force_time : float; fade_time : float; scale : float) : float
  let maxSpreadTime = start_time + spread_time
  if time < maxSpreadTime
    return scale * cvt(time, start_time, maxSpreadTime, 0.0, 1.0)
  let fadeStartTime = maxSpreadTime + full_force_time
  if time < fadeStartTime
    return scale
  return scale * cvt(time, fadeStartTime, fadeStartTime + fade_time, 1.0, 0.0)

def change_visibility(node_attached__entity : ecs::EntityId;
                      fire_affected_optics : ecs::IntList;
                      visibility_change : int)
  query(node_attached__entity) <| $ [es] (vehicle_seats__seatEids : EidList)
    for affectedIndex in fire_affected_optics
      if affectedIndex >= length(vehicle_seats__seatEids)
        logerr("fire_affected_optics has invalid seatIndex: {affectedIndex}. Total seats: {length(vehicle_seats__seatEids)}")
      else
        query(vehicle_seats__seatEids[affectedIndex]) <| $ [es] (var seat__limitedVisibility : int&)
          seat__limitedVisibility += visibility_change


[es(tag=server, on_appear)]
def fire_source_init_start_time(evt : Event; var fire_source__startTime : float&)
  fire_source__startTime = get_sync_time()

[es(tag=server, on_appear)]
def fire_source_init_affected_optics(evt : Event; transform : float3x4;
                                     node_attached__entity : ecs::EntityId;
                                     var fire_affected_optics : ecs::IntList;
                                     visibilityRestrictionRadius : float = 0.5;
                                     visibilityRestrictionHeight : float = 1.0;
                                     visibilityRestrictionBottomOffset : float = -0.35)
  collect_affected_optics(transform[3], node_attached__entity,
      visibilityRestrictionRadius, visibilityRestrictionHeight, visibilityRestrictionBottomOffset, fire_affected_optics)
  change_visibility(node_attached__entity, fire_affected_optics, +1)

[es(tag=server, on_disappear)]
def fire_source_destroyed_restore_affected_optics(evt : Event;
                                                  node_attached__entity : ecs::EntityId;
                                                  fire_affected_optics : ecs::IntList)
  change_visibility(node_attached__entity, fire_affected_optics, -1)

[es(tag=server, no_order)]
def fire_source_progress(info : UpdateStageInfoAct;
                         eid : ecs::EntityId;
                         var sphere_zone__radius : float&;
                         fire_source__startTime : float;
                         fire_source__fullForceTime : float;
                         fire_source__spreadTime : float = 0.0;
                         fire_source__fadeTime : float = 0.0;
                         fire_source__scale : float = 1.0)
  let duration = fire_source__spreadTime + fire_source__fullForceTime + fire_source__fadeTime
  let time = info.curTime
  if time > fire_source__startTime + duration
    destroyEntity(eid)
  else
    sphere_zone__radius = calc_fire_size(time, fire_source__startTime,
        fire_source__spreadTime, fire_source__fullForceTime, fire_source__fadeTime, fire_source__scale)

[es(tag=render, no_order)]
def fire_source_effect(info : UpdateStageInfoAct;
                       var effect__scale : float&;
                       fire_source__startTime : float;
                       fire_source__effectScale : float;
                       fire_source__fullForceTime : float;
                       fire_source__spreadTime : float = 0.0;
                       fire_source__fadeTime : float = 0.0;
                       fire_source__scale : float = 1.0;
                       fire_source__effectMinScale : float = 0.0)
  let zone_size = calc_fire_size(info.curTime, fire_source__startTime,
      fire_source__spreadTime, fire_source__fullForceTime, fire_source__fadeTime, fire_source__scale)
  effect__scale = max(fire_source__effectMinScale, zone_size * fire_source__effectScale)
