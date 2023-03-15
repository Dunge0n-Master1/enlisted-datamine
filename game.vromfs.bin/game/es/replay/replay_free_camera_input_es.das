require ecs
require game.es.input.input_events

[es(tag=input, before=free_cam_es, REQUIRE=replay_camera__tpsFree)]
def replay_free_cam_input_action_es(evt : EventDaInputActionTriggered;
                                    free_cam_input__speedUp : uint16;
                                    free_cam_input__speedDown : uint16;
                                    free_cam_input__speedReset : uint16;
                                    free_cam__moveSpeedDefault : float;
                                    var free_cam__move_speed : float&;
                                    free_cam__moveSpeedChangeFactor = 1.03)
  if evt.action == free_cam_input__speedUp
    free_cam__move_speed *= free_cam__moveSpeedChangeFactor
  elif evt.action == free_cam_input__speedDown
    free_cam__move_speed /= free_cam__moveSpeedChangeFactor
  elif evt.action == free_cam_input__speedReset
    free_cam__move_speed = free_cam__moveSpeedDefault

[es(after=replay_free_cam_input_action_es, REQUIRE=replay_camera__tpsFree)]
def replay_free_cam_movement_update_es(info : UpdateStageInfoAct;
                                       var free_cam__move : float2&;
                                       camera__active : bool;
                                       free_cam__move_speed : float;
                                       replay_camera__stopInertia : float;
                                       replay_camera__moveInertia : float;
                                       var replay_camera__freeLinVel : float3&;
                                       var transform : float3x4&)
  if !camera__active
    replay_camera__freeLinVel = float3()
    free_cam__move = float2()
    return

  let inertion = length_sq(free_cam__move) == 0. ? replay_camera__stopInertia : replay_camera__moveInertia
  let mov = (transform[2] * free_cam__move.y + transform[0] * free_cam__move.x)
  replay_camera__freeLinVel = replay_camera__freeLinVel * inertion + mov * (free_cam__move_speed * (1. - inertion))
  if length_sq(replay_camera__freeLinVel) > 1.0E-5
    transform[3] = transform[3] + replay_camera__freeLinVel * (1. / 60.)
  free_cam__move = float2()
