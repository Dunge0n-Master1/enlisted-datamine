require ecs
require DagorInput
require game.es.input.input_events
require game.es.input.input_common
require DagorSystem
require game.events_game
require EnlistedCamera
require enlisted.events_enlisted
require danetlibs.renderer.includes.render_events

def initActions(var replay_input__next : int&;
                var replay_input__prev : int&;
                var replay_input__pause : int&;
                var replay_input__speedUp : int&;
                var replay_input__speedDown : int&;
                var replay_input__toggleCamera : int&)
  let replaySetHandle = get_action_set_handle("Replay")
  if int(replaySetHandle) != int(BAD_ACTION_HANDLE)
    activate_action_set(replaySetHandle, true)
  replay_input__next = int(get_action_handle("Replay.Next", TYPEGRP_DIGITAL))
  replay_input__prev = int(get_action_handle("Replay.Prev", TYPEGRP_DIGITAL))
  replay_input__pause = int(get_action_handle("Replay.Pause", TYPEGRP_DIGITAL))
  replay_input__speedUp = int(get_action_handle("Replay.SpeedUp", TYPEGRP_DIGITAL))
  replay_input__speedDown = int(get_action_handle("Replay.SpeedDown", TYPEGRP_DIGITAL))
  replay_input__toggleCamera = int(get_action_handle("Replay.ToggleCamera", TYPEGRP_DIGITAL))


def resetActions(var replay_input__next : int&;
                 var replay_input__prev : int&;
                 var replay_input__pause : int&;
                 var replay_input__speedUp : int&;
                 var replay_input__speedDown : int&;
                 var replay_input__toggleCamera : int&)
  let replaySetHandle = get_action_set_handle("Replay")
  if int(replaySetHandle) != int(BAD_ACTION_HANDLE)
    activate_action_set(replaySetHandle, false)
  replay_input__next = int(BAD_ACTION_HANDLE)
  replay_input__prev = int(BAD_ACTION_HANDLE)
  replay_input__pause = int(BAD_ACTION_HANDLE)
  replay_input__speedUp = int(BAD_ACTION_HANDLE)
  replay_input__speedDown = int(BAD_ACTION_HANDLE)
  replay_input__toggleCamera = int(BAD_ACTION_HANDLE)

[es(tag=(playingReplay, input))]
def camera_replay_input_setup(evt : EventDaInputInit;
                              var replay_input__next : int&;
                              var replay_input__prev : int&;
                              var replay_input__pause : int&;
                              var replay_input__speedUp : int&;
                              var replay_input__speedDown : int&;
                              var replay_input__toggleCamera : int&)
  if evt.init
    initActions(replay_input__next, replay_input__prev,
      replay_input__pause, replay_input__speedUp, replay_input__speedDown, replay_input__toggleCamera)
  else
    resetActions(replay_input__next, replay_input__prev,
      replay_input__pause, replay_input__speedUp, replay_input__speedDown, replay_input__toggleCamera)

[es(tag=(playingReplay, input), on_appear)]
def camera_replay_input_appear(evt : Event;
                               var replay_input__next : int&;
                               var replay_input__prev : int&;
                               var replay_input__pause : int&;
                               var replay_input__speedUp : int&;
                               var replay_input__speedDown : int&;
                               var replay_input__toggleCamera : int&)
  initActions(replay_input__next, replay_input__prev,
    replay_input__pause, replay_input__speedUp, replay_input__speedDown, replay_input__toggleCamera)

[es(tag=(playingReplay, input), on_event=(EventComponentsDisappear, EventEntityDestroyed))]
def camera_replay_input_disappear(evt : Event;
                                  var replay_input__next : int&;
                                  var replay_input__prev : int&;
                                  var replay_input__pause : int&;
                                  var replay_input__speedUp : int&;
                                  var replay_input__speedDown : int&;
                                  var replay_input__toggleCamera : int&)
  resetActions(replay_input__next, replay_input__prev,
      replay_input__pause, replay_input__speedUp, replay_input__speedDown, replay_input__toggleCamera)

[es(tag=(playingReplay, input))]
def replay_speed_change_es(evt : EventDaInputActionTriggered;
                           replay_input__pause : int;
                           replay_input__speedUp : int;
                           replay_input__speedDown : int)
  find_query() <| $ [es] (var replay__speed : float&)
    if int(evt.action) == replay_input__pause
      replay__speed = replay__speed == 0f ? 1f : 0f
    elif int(evt.action) == replay_input__speedUp
      replay__speed = min(4f, replay__speed + 0.5f)
    elif int(evt.action) == replay_input__speedDown
      replay__speed = max(0f, replay__speed - 0.5f)
    return true

[es(tag=(playingReplay, input))]
def camera_replay_change(evt : EventDaInputActionTriggered&;
                         replay_input__next : int;
                         replay_input__prev : int)
  var delta : int
  if int(evt.action) == replay_input__next
    delta = 1
  elif int(evt.action) == replay_input__prev
    delta = -1
  else
    return

  sendEvent(get_cur_cam_entity(), [[NextReplayTarget delta=delta]])

[es(tag=(playingReplay, input))]
def replay_toggle_camera(evt : EventDaInputActionTriggered&; replay_input__toggleCamera : int)
  if int(evt.action) != replay_input__toggleCamera
    return
  broadcastEvent([[ReplayToggleFreeCamera]])

[es(tag=input, before=free_cam_es, after=free_cam_input_es)]
def free_cam_update_position_for_gamepad_es(info : UpdateStageInfoBeforeRender;
                                            camera__input_enabled : bool;
                                            camera__active : bool;
                                            var free_cam_input__moveUI : float2&;
                                            var free_cam__move : float2&)
  if is_gamepad_input()
    if camera__active && camera__input_enabled
      free_cam__move = free_cam_input__moveUI
    else
      free_cam__move = float2()
  free_cam_input__moveUI = float2()

[es(tag=playingReplay, on_event=ReplayToggleFreeCamera, REQUIRE=replayCamera)]
def toggle_replay_free_camera_es(evt : Event;
                                 camera__active : bool;
                                 camera__inputActionSet : string;
                                 var camera__input_enabled : bool&)
  if !camera__active
    return

  camera__input_enabled = !camera__input_enabled
  let replaySetHandle = get_action_set_handle(camera__inputActionSet)
  if int(replaySetHandle) != int(BAD_ACTION_HANDLE)
    activate_action_set(replaySetHandle, camera__input_enabled)
  return

[es(tag=(playingReplay, input), track=camera__active, REQUIRE=replayCamera)]
def replay_disable_camera_input_es(evt : Event;
                                   camera__active : bool;
                                   camera__inputActionSet : string;
                                   var camera__input_enabled : bool&)
  if camera__active
    return
  camera__input_enabled = false
  let replaySetHandle = get_action_set_handle(camera__inputActionSet)
  if int(replaySetHandle) != int(BAD_ACTION_HANDLE)
    activate_action_set(replaySetHandle, false)
