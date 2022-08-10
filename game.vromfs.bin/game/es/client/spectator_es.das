require ecs
require DagorInput
require DagorMathUtils
require game.es.player_common
require game.es.input.input_events
require game.es.client.spectator_common


[es(on_appear)]
def spectator_appear_es(evt : Event; eid : EntityId; var spectator__target : EntityId&; spectator__teamId : int)
  if spectator__target != INVALID_ENTITY_ID
    set_spectated(eid, spectator__target, spectator__target, /*initial*/ true)
  else
    set_spectated(eid, spectator__target, find_next_spec_target(spectator__teamId, INVALID_ENTITY_ID, +1), /*initial*/ true)

[es(REQUIRE=spectator, on_disappear)]
def spectator_disappear_es(evt : Event; spectator__target : EntityId)
  if spectator__target != INVALID_ENTITY_ID && doesEntityExist(spectator__target)
    removeSubTemplate(spectator__target, "observed_local")

[es(tag=input, REQUIRE=fov)]
def spectator_bhv_es(evt : UpdateStageInfoAct;
                     spectator_input__aim : int;
                     var shooter_cam__alternative_settings : bool&;
                     camera__target : EntityId;
                     var spectator__ang : float2&;
                     var spectator__dir : float3&) : void
  shooter_cam__alternative_settings = true

  query(camera__target) <| $ [es] (var camera__lookDir : float3&)
    camera__lookDir = spectator__dir

  let aim = get_analog_stick_action_state(uint16(spectator_input__aim))
  if !aim.bActive
    return
  spectator__ang += float2(aim.x * PI, aim.y * PI)
  spectator__ang.y = clamp(spectator__ang.y, -PI / 2. + 1e-3f, PI / 2. - 1e-3f)
  spectator__dir = angles_to_dir(spectator__ang)

[es(tag=input)]
def spectator_bhv_on_action_triggered_es(evt : EventDaInputActionTriggered;
                                         eid : EntityId;
                                         spectator_input__prev : int;
                                         spectator_input__next : int;
                                         spectator__teamId : int;
                                         var spectator__target : EntityId&) : void
  if int(evt.action) == spectator_input__next
    let nextTarget : EntityId = find_next_spec_target(spectator__teamId, spectator__target, +1)
    set_spectated(eid, spectator__target, nextTarget)
  elif int(evt.action) == spectator_input__prev
    let nextTarget : EntityId = find_next_spec_target(spectator__teamId, spectator__target, -1)
    set_spectated(eid, spectator__target, nextTarget)

[es(on_appear, tag=input, before=spectator_appear_es)]
def spectator_init_es(evt : Event; team : int; var spectator__teamId : int&)
  spectator__teamId = team
