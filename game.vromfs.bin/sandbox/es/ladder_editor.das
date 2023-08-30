require ecs
require DagorMath
require gameObject
require math.base
require DagorDebug3D
require game.es.ladder_entities_common

[es(no_order, REQUIRE=daeditor__selected)]
def draw_debug_ladder_es(info : UpdateStageInfoRenderDebug;
                         transform : float3x4;
                         ladder__numSteps : uint16;
                         ladder__height : float;
                         ladder__width : float;
                         ladder__thickness : float)
  let orient = quat(transform)
  let upDir = quat_get_up(orient)
  let leftDir = quat_get_left(orient)
  for i in range(int(ladder__numSteps))
    let ht = lerp(0., ladder__height, float(i) / float(int(ladder__numSteps) - 1))
    let start = transform[3] + upDir * ht
    let end = start + (leftDir * ladder__width)
    draw_debug_line_buffered(start, end, E3DCOLOR(0xFFFFFF00), 1)

  let bboxTm = make_ladder_tm(ladder__height, ladder__width, ladder__thickness, transform)
  draw_debug_box_buffered(bboxTm[3], bboxTm[0], bboxTm[1], bboxTm[2], E3DCOLOR(0xFFFFFF00), 1)


def private update_ladder_game_object(transform : float3x4;
                                      ladder__height : float;
                                      ladder__width : float;
                                      ladder__thickness : float;
                                      ladder__sceneIndex : uint;
                                      ladder__numSteps : uint16)
  query() <| $ [es] (var game_objects : GameObjects&)
    if game_objects.ladders == null || ladder__sceneIndex == uint(-1)
      return
    let orient = quat(transform)
    var bboxTm = make_ladder_tm(ladder__height, ladder__width, ladder__thickness, transform)
    bboxTm[3] += (quat_get_left(orient) * ladder__width + quat_get_up(orient) * ladder__height + quat_get_forward(orient) * ladder__thickness) * 0.5f
    reallocate(*game_objects.ladders, ladder__sceneIndex,  mat44f(bboxTm), uint16(0) /*pool*/, ladder__numSteps)


[es(no_order, REQUIRE=daeditor__selected)]
def update_ladder_game_object_by_timer_es(info : UpdateStageInfoAct;
                                          ladder__updateGameObjectTimeSec : float;
                                          transform : float3x4;
                                          ladder__height : float;
                                          ladder__width : float;
                                          ladder__thickness : float;
                                          ladder__sceneIndex : uint;
                                          ladder__numSteps : uint16;
                                          var ladder__updateGameObjectTimerSec : float&)
  ladder__updateGameObjectTimerSec -=  1. / 60.
  if ladder__updateGameObjectTimerSec > 0.
    return
  ladder__updateGameObjectTimerSec = ladder__updateGameObjectTimeSec
  update_ladder_game_object(transform, ladder__height, ladder__width, ladder__thickness, ladder__sceneIndex, ladder__numSteps)


[es(on_event=EventComponentsDisappear, REQUIRE=daeditor__selected)]
def move_ladder_game_object_es(evt : Event;
                               transform : float3x4;
                               ladder__height : float;
                               ladder__width : float;
                               ladder__thickness : float;
                               ladder__numSteps : uint16;
                               ladder__sceneIndex : uint)
  update_ladder_game_object(transform, ladder__height, ladder__width, ladder__thickness, ladder__sceneIndex, ladder__numSteps)
