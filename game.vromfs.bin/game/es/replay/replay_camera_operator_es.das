require ecs
require DagorMath
require DagorMathUtils
require math.base
require Dacoll
require DagorRandom
require DagorSystem

[es(track=(camera__target, camera__active), on_event=ReplaySetOperatorCamera, before=replay_update_operator_view_es)]
def init_operator_view_es(evt : Event;
                          camera__active : bool;
                          camera__target : EntityId;
                          var transform aka camera_transform : float3x4&;
                          var operator__verticalOffset : float3&;
                          var operator__horizontalOffset : float3&;
                          var operator__moveSpeed : float&;
                          var operator__tripodLen : float&;
                          var operator__tripodLenDefault : float&;
                          var operator__tripodLenTarget : float&;
                          operator__verticalOffsetRange : float2 = float2(1, 3);
                          operator__tripodLenRange : float2 = float2(3, 5))
  if !camera__active
    return

  query(camera__target) <| $ [es] (transform : float3x4)
    operator__tripodLenDefault = float(rnd_int(int(operator__tripodLenRange.x), int(operator__tripodLenRange.y)))
    operator__tripodLen = operator__tripodLenDefault
    operator__tripodLenTarget = operator__tripodLenDefault
    operator__moveSpeed *= float(rnd_int(0, 1) * 2 - 1)

    let verOffsetY = float(rnd_int(int(operator__verticalOffsetRange.x), int(operator__verticalOffsetRange.y)))
    operator__verticalOffset = float3(0., verOffsetY, 0.)
    operator__horizontalOffset = angles_to_dir(float2(rnd_float(0., 2. * PI), 0.))
    camera_transform[3] = transform[3] + operator__verticalOffset + operator__horizontalOffset * operator__tripodLen


[es(tag=playingReplay, REQUIRE=replay_camera__operator, after=camera_set_sync, before=before_camera_sync)]
def replay_update_operator_view_es(info : UpdateStageInfoAct;
                                   camera__active : bool;
                                   operator__fixedDeltaTime : float = 1. / 60.;
                                   operator__moveSpeed : float;
                                   var operator__tripodLen : float&;
                                   var operator__tripodLenTarget : float&;
                                   operator__tripodLenDefault : float;
                                   operator__verticalOffset : float3;
                                   camera__target : EntityId;
                                   var transform aka camera_transform : float3x4&;
                                   var operator__horizontalOffset : float3&;
                                   var operator__newPos : float3&;
                                   operator__offsetFromLegs : float3 = float3(0, 1, 0);
                                   operator__tripodLerpCoef : float = 0.005)
  if !camera__active
    return

  query(camera__target) <| $ [es] (transform : float3x4)
    let moveOffset = operator__fixedDeltaTime * operator__moveSpeed
    operator__horizontalOffset = angles_to_dir(dir_to_angles(operator__horizontalOffset) + float2(moveOffset, 0.))
    let tripodOffset = operator__horizontalOffset * operator__tripodLen
    let posWithOffset = transform[3] + operator__verticalOffset

    camera_transform[2] = normalize(transform[3] + operator__offsetFromLegs - camera_transform[3]) // fwd
    camera_transform[0] = normalize(-cross(camera_transform[2], float3(0, 1, 0))) // right
    camera_transform[1] = normalize(cross(camera_transform[2], camera_transform[0])) // up
    operator__newPos = posWithOffset + tripodOffset
    var queryOut = ShapeQueryOutput()
    if sphere_cast(posWithOffset, operator__newPos, 0.1f, queryOut, -1)
      operator__tripodLenTarget = max(0.5, queryOut.t)
    else
      operator__tripodLenTarget = operator__tripodLenDefault

    operator__tripodLen = lerp(operator__tripodLen, operator__tripodLenTarget, operator__tripodLerpCoef)
    camera_transform[3] = operator__newPos
