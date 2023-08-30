require ecs
require DagorMath
require gameObject
require math.base
require DagorSystem
require game.es.ladder_entities_common

def private init_ladder(transform : float3x4;
                        ladder__numSteps : uint16;
                        ladder__height : float;
                        ladder__width : float;
                        ladder__thickness : float;
                        var ladder__sceneIndex : uint&;
                        var game_objects : GameObjects&)
  if ladder__sceneIndex != uint(-1)
    return

  if game_objects.ladders == null
    create_ladder_scene(game_objects)

  if game_objects.ladders == null
    logerr("Failed to create ladders scene. Out of memory")
    return

  let orient = quat(transform)
  var bboxTm = make_ladder_tm(ladder__height, ladder__width, ladder__thickness, transform)
  bboxTm[3] += (quat_get_left(orient) * ladder__width + quat_get_up(orient) * ladder__height + quat_get_forward(orient) * ladder__thickness) * 0.5f
  ladder__sceneIndex = allocate(*game_objects.ladders, mat44f(bboxTm), /*pool*/uint16(0), /*flags*/ladder__numSteps)


[es(on_appear)]
def init_ladder_es(evt : Event;
                   transform : float3x4;
                   ladder__numSteps : uint16;
                   ladder__height : float;
                   ladder__width : float;
                   ladder__thickness : float;
                   var ladder__sceneIndex : uint&)
  query() <| $ [es] (var game_objects : GameObjects&)
    init_ladder(transform, ladder__numSteps, ladder__height, ladder__width, ladder__thickness, ladder__sceneIndex, game_objects)


[es(on_appear)]
def init_ladder_on_game_objects_created_es(evt : Event; var game_objects : GameObjects&)
  query() <| $ [es] (transform : float3x4;
                     ladder__numSteps : uint16;
                     ladder__height : float;
                     ladder__width : float;
                     ladder__thickness : float;
                     var ladder__sceneIndex : uint&)
    init_ladder(transform, ladder__numSteps, ladder__height, ladder__width, ladder__thickness, ladder__sceneIndex, game_objects)


[es(on_disappear)]
def destroy_ladder_es(evt : Event; ladder__sceneIndex : uint)
  query() <| $ [es] (var game_objects : GameObjects&)
    if game_objects.ladders != null && ladder__sceneIndex != uint(-1)
      destroy(*game_objects.ladders, ladder__sceneIndex)
