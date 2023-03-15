require ecs
require DagorInput

[es(tag=input, no_order, REQUIRE=replayCamera)]
def replay_cam_update_fov_input_es(info : UpdateStageInfoAct;
                                   free_cam_input__zoomIn : uint16;
                                   free_cam_input__zoomOut : uint16;
                                   camera__active : bool;
                                   replay_camera__zoomInertia : float = 0.80;
                                   replay_cam__zoomSpeed : float = 30.;
                                   var replay_camera__zoomLinVel : float&;
                                   var fovSettings : float&)
  if !camera__active
    replay_camera__zoomLinVel = 0.
    return

  var fovDir = 0
  if is_action_active(free_cam_input__zoomIn) && get_digital_action_state(free_cam_input__zoomIn).bState
    fovDir = 1
  elif is_action_active(free_cam_input__zoomOut) && get_digital_action_state(free_cam_input__zoomOut).bState
    fovDir = -1

  assume inertion = replay_camera__zoomInertia
  replay_camera__zoomLinVel = replay_camera__zoomLinVel * inertion + float(fovDir) * (replay_cam__zoomSpeed * (1. - inertion))
  replay_camera__zoomLinVel
  if abs(replay_camera__zoomLinVel) > 1.0E-5
    fovSettings += replay_camera__zoomLinVel * 1. / 60.
    fovSettings = clamp(fovSettings, 10., 130.)
