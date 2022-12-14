require ecs

[es(tag=render, after=before_camera_sync, before=shooter_cam_act_es)]
def shooter_cam_apply_offset_multiplier_es(info : UpdateStageInfoAct;
                                           var shooter_cam__offset : float3&;
                                           var shooter_cam__offset_multiplier : float&;
                                           camera__target : ecs::EntityId;
                                           camera__active : bool;
                                           isTpsView = false)
  if !camera__active
    return

  var offsetMult = 1.0f
  var offset = float3(0.f, 0.f, 0.f)

  query(camera__target) <| $ [es] (isInVehicle : bool; vehicle__lastEid : EntityId)
    if !isInVehicle
      return
    query(vehicle__lastEid) <| $ [es] (camera__unit_offset_multiplier : float const?; camera__firstPersonOffset : float3 const?)
      if isTpsView
        offsetMult = camera__unit_offset_multiplier ?? shooter_cam__offset_multiplier
      else
        offset = camera__firstPersonOffset ?? shooter_cam__offset

  shooter_cam__offset_multiplier = offsetMult
  shooter_cam__offset = offset