require ecs
require math.base
require DagorMath
require DagorMathUtils

[es(tag=render, REQUIRE=plane_fps_cam__applyLookAroundOffset, after=shooter_cam_apply_offset_multiplier_es, before=shooter_cam_act_es)]
def airplane_fps_camera_offset(info : UpdateStageInfoAct;
                               var shooter_cam__offset : float3&;
                               camera__target : EntityId;
                               camera__active : bool;
                               transform aka camera_transform : float3x4;
                               isTpsView = false)
  if !camera__active || isTpsView
    return

  query(camera__target) <| $ [es(REQUIRE=(airplane, vehicleWithWatched))] (transform aka target_transform : float3x4;
                                                                           camera__lookAroundOffsetRange : float2)
    let invCamTm = inverse(camera_transform)
    let angle = dir_to_angles(rotate(invCamTm, -target_transform[2])).x
    let offsetX = (angle >= 0.
      ? cvt(angle, 0., HALF_PI, 0., camera__lookAroundOffsetRange.x)
      : -cvt(angle, 0., -HALF_PI, 0., camera__lookAroundOffsetRange.y))
    shooter_cam__offset = rotate(invCamTm, target_transform[2] * offsetX)
