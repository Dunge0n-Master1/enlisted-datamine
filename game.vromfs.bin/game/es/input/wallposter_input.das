require ecs
require ecs.common
require DagorInput
require game.es.input.input_events
require enlisted.events_enlisted
require player


def initActions(var wallposter_input__place, wallposter_input__cancel : int&)
  wallposter_input__place = int(get_action_handle("Wallposter.Place", TYPEGRP_DIGITAL))
  wallposter_input__cancel = int(get_action_handle("Wallposter.Cancel", TYPEGRP_DIGITAL))


def resetActions(var wallposter_input__place, wallposter_input__cancel : int&)
  wallposter_input__place = int(BAD_ACTION_HANDLE)
  wallposter_input__cancel = int(BAD_ACTION_HANDLE)

[es(tag=input)]
def wallposter_input_setup_es(evt : EventDaInputInit; var wallposter_input__place, wallposter_input__cancel : int&)
  if evt.init
    initActions(wallposter_input__place, wallposter_input__cancel)
  else
    resetActions(wallposter_input__place, wallposter_input__cancel)

[es(tag=input, on_appear)]
def wallposter_input_appear_es(evt : Event; var wallposter_input__place, wallposter_input__cancel : int&)
  initActions(wallposter_input__place, wallposter_input__cancel)

[es(tag=input, on_event=(EventComponentsDisappear, EventEntityDestroyed))]
def wallposter_input_disappear_es(evt : Event; var wallposter_input__place, wallposter_input__cancel : int&)
  resetActions(wallposter_input__place, wallposter_input__cancel)

[es(tag=input)]
def wallposter_input_es(evt : EventDaInputActionTriggered;
                        input__enabled : bool;
                        wallposter_input__place, wallposter_input__cancel : int)
  if !input__enabled
    return
  let playerEid = get_local_player_eid()
  if int(evt.action) == wallposter_input__place
    sendEvent(playerEid, [[CmdWallposterPlace]])
  elif int(evt.action) == wallposter_input__cancel
    sendEvent(playerEid, [[CmdWallposterPreview enable=false, wallPosterId=0]])
