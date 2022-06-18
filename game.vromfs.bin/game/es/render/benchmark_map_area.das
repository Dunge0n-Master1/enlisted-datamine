require ecs
require app
require DagorTime
require Dacoll
require EnlistedCamera
require DagorMath
require DagorSystem
require game.es.events


def addCameraPoint(pos : float3;
                   rot_rad : float;
                   var map_benchmark__cameraTracks : Array&)
  using <| $(var obj : Object#)
    obj |> set("pos", pos)
    obj |> set("rot", rot_rad)
    map_benchmark__cameraTracks |> push(obj)

[es(on_event=EventLevelLoaded)]
def mapBenchmarkInit(evt : Event;
                     map_benchmark__pointsCount : int;
                     map_benchmark__areaBegin : float2;
                     map_benchmark__areaEnd : float2;
                     var map_benchmark__cameraTracks : Array&;
                     var map_benchmark__cameraEid : EntityId&)
  let x_point_step = (map_benchmark__areaEnd.x - map_benchmark__areaBegin.x) / float(map_benchmark__pointsCount)
  let y_point_step = (map_benchmark__areaEnd.y - map_benchmark__areaBegin.y) / float(map_benchmark__pointsCount)
  var x = map_benchmark__areaBegin.x
  var y = map_benchmark__areaBegin.y
  let trace_pos_height = 100.0
  while x <= map_benchmark__areaEnd.x
    while y <= map_benchmark__areaEnd.y
      var pos = float3(x, 0.0, y)
      var height = trace_pos_height
      pos.y = trace_pos_height
      tracedown_normalized(pos, height, ETF_DEFAULT)
      pos.y = trace_pos_height - height + 2.0
      addCameraPoint(pos, PI / 2.0, map_benchmark__cameraTracks)
      addCameraPoint(pos, PI / 2.0, map_benchmark__cameraTracks)
      addCameraPoint(pos, PI / 2.0, map_benchmark__cameraTracks)
      addCameraPoint(pos, PI / 2.0, map_benchmark__cameraTracks)
      y += y_point_step
    y = map_benchmark__areaBegin.y
    x += x_point_step

  map_benchmark__cameraEid = get_cur_cam_entity()

[es(no_order)]
def mapBenchmarkProc(info : UpdateStageInfoAct;
                     var map_benchmark__cameraTrackIter : int&;
                     map_benchmark__cameraTrackCdMs : int;
                     var map_benchmark__cameraTrackLastTrigerTime : int&;
                     var map_benchmark__frameSection : int&;
                     map_benchmark__cameraEid : EntityId&;
                     map_benchmark__cameraTracks : Array)
  let cur_time = get_time_msec()
  if map_benchmark__cameraTrackLastTrigerTime == 0
    map_benchmark__cameraTrackLastTrigerTime = cur_time
    return

  if map_benchmark__cameraTrackIter >= length(map_benchmark__cameraTracks)
    exit_game("Erea benchmark completed")

  map_benchmark__frameSection += 1
  if cur_time > map_benchmark__cameraTrackLastTrigerTime + map_benchmark__cameraTrackCdMs
    assume tracks = map_benchmark__cameraTracks
    let curTrack = get_ecs_object(tracks[map_benchmark__cameraTrackIter])
    let position = *get_Point3(curTrack, "pos")
    let rotation = *get_float(curTrack, "rot")

    var rot_mat : float3x4
    var q : quat
    euler_to_quat(rotation, 0.0f, 0.0f, q)
    make_tm(q, float3(), rot_mat)

    query(map_benchmark__cameraEid) <| $ [es] (var transform : float3x4&)
      transform[3] = position
      transform = transform * rot_mat

    let section_time = float(cur_time - map_benchmark__cameraTrackLastTrigerTime) / 1000.0
    let fps = float(map_benchmark__frameSection) / section_time
    print("Benchmark section: fps={fps}, section_time={section_time}, frames={map_benchmark__frameSection}, at_position={position}, iteration={map_benchmark__cameraTrackIter}")

    map_benchmark__cameraTrackIter += 1
    map_benchmark__cameraTrackLastTrigerTime = cur_time
    map_benchmark__frameSection = 0
