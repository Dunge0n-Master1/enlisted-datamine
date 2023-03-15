require ecs
require math.base
require EnlistedCamera

// seems that sndsys::update_listener_pos is called after game code update, so get_listener_pos() is 1 frame delayed;
// should get listener_position directly from camera for systems where it is important.
// important for systems with sound placed where camera is.
[es(tag=sound, before=before_camera_sync)]
def global_sound_listener_position_update(info : UpdateStageInfoAct)
  let cam = (get_cur_cam_entity() |> get_TMatrix("transform") ?? IDENT_TM)[3]
  query() <| $ [es] (var global_sound_listener_position : float3&)
    global_sound_listener_position = cam
