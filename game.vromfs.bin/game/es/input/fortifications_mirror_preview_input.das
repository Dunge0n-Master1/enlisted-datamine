require ecs
require DagorInput
require game.es.input.input_events
require enlisted.events_enlisted

def init(var human_input__fortificationMirrorPreview : int&)
  human_input__fortificationMirrorPreview = int(get_action_handle("Human.RotateBuilding", TYPEGRP_DIGITAL))

def reset(var human_input__fortificationMirrorPreview : int&)
  human_input__fortificationMirrorPreview = int(BAD_ACTION_HANDLE)

[es(tag=input, on_appear)]
def fortifications_mirror_preview_input_on_create(evt : Event; var human_input__fortificationMirrorPreview : int&)
  init(human_input__fortificationMirrorPreview)

[es(tag=input, on_event=(EventEntityDestroyed, EventComponentsDisappear))]
def fortifications_mirror_preview_input_on_destroy(evt : Event; var human_input__fortificationMirrorPreview : int&)
  reset(human_input__fortificationMirrorPreview)

[es(tag=input)]
def fortifications_mirror_preview_on_init(evt : EventDaInputInit; var human_input__fortificationMirrorPreview : int&)
  if evt.init
    init(human_input__fortificationMirrorPreview)
  else
    reset(human_input__fortificationMirrorPreview)

[es(tag=input)]
def fortifications_mirror_preview_on_action(evt : EventDaInputActionTriggered;
                                            input__enabled : bool;
                                            human_input__fortificationMirrorPreview : int)
  if input__enabled && int(evt.action) == human_input__fortificationMirrorPreview
    query() <| $ [es(REQUIRE=builder_preview, REQUIRE_NOT=(builder_server_preview, builder_additive_preview))] (yawRotationSpeed : float;
                                                                                                                var additionalYawRotation : float&)
      additionalYawRotation += yawRotationSpeed
      if additionalYawRotation > 360.0
        additionalYawRotation -= 360.0