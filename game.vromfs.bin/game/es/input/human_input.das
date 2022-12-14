require app
require ecs
require math.base
require game.es.events
require game.es.input.input_events
require DagorInput
require DagorSystem
require DagorMath
require DagorMathUtils
require HumanPhys
require HumanPhys
require TouchInput
require EnlistedHuman
require game.es.human.human_use_object_common

let MOVE_THRESHOLD = 0.1f


def init(var human_input__aim : int&;
         var human_input__aimDelta : int&;
         var human_input__look : int&;
         var human_input__move : int&;
         var human_input__leanX : int&;
         var human_input__sprint : int&;
         var human_input__holdBreath : int&;
         var human_input__aim1 : int&;
         var human_input__aim2 : int&;
         var human_input__zoom : int&;
         var human_input__sightNext : int&;
         var human_input__sightPrev : int&;
         var human_input__cameraNext : int&;
         var human_input__use : int&)
  human_input__aim = int(get_action_handle("Human.Aim", TYPEGRP_STICK))
  human_input__aimDelta = int(get_action_handle("Human.AimDelta", TYPEGRP_STICK))
  human_input__look = int(get_action_handle("Human.Look", TYPEGRP_STICK))
  human_input__move = int(get_action_handle("Human.Move", TYPEGRP_STICK))
  human_input__leanX = int(get_action_handle("Human.LeanX", TYPEGRP_AXIS))

  human_input__sprint = int(get_action_handle("Human.Sprint", TYPEGRP_DIGITAL));
  human_input__holdBreath = int(get_action_handle("Human.HoldBreath", TYPEGRP_DIGITAL));
  human_input__aim1 = int(get_action_handle("Human.Aim1", TYPEGRP_DIGITAL));
  human_input__aim2 = int(get_action_handle("Human.Aim2", TYPEGRP_DIGITAL));
  human_input__zoom = int(get_action_handle("Human.Zoom", TYPEGRP_DIGITAL));

  human_input__sightNext = int(get_action_handle("Human.SightNext", TYPEGRP_DIGITAL));
  human_input__sightPrev = int(get_action_handle("Human.SightPrev", TYPEGRP_DIGITAL));
  human_input__cameraNext = int(get_action_handle("Human.CameraNext", TYPEGRP_DIGITAL));

  human_input__use = int(get_action_handle("Human.Use", TYPEGRP_DIGITAL))



def reset(var human_input__aim : int&;
          var human_input__aimDelta : int&;
          var human_input__look : int&;
          var human_input__move : int&;
          var human_input__leanX : int&;
          var human_input__sprint : int&;
          var human_input__holdBreath : int&;
          var human_input__aim1 : int&;
          var human_input__aim2 : int&;
          var human_input__zoom : int&;
          var human_input__sightNext : int&;
          var human_input__sightPrev : int&;
          var human_input__cameraNext : int&;
          var human_input__use : int&)
  human_input__aim = int(BAD_ACTION_HANDLE)
  human_input__aimDelta = int(BAD_ACTION_HANDLE)
  human_input__look = int(BAD_ACTION_HANDLE)
  human_input__move = int(BAD_ACTION_HANDLE)
  human_input__leanX = int(BAD_ACTION_HANDLE)
  human_input__sprint = int(BAD_ACTION_HANDLE)
  human_input__holdBreath = int(BAD_ACTION_HANDLE)
  human_input__aim1 = int(BAD_ACTION_HANDLE)
  human_input__aim2 = int(BAD_ACTION_HANDLE)
  human_input__zoom = int(BAD_ACTION_HANDLE)
  human_input__sightNext = int(BAD_ACTION_HANDLE)
  human_input__sightPrev = int(BAD_ACTION_HANDLE)
  human_input__cameraNext = int(BAD_ACTION_HANDLE)
  human_input__use = int(BAD_ACTION_HANDLE)

[es(tag=input, REQUIRE=human_input)]
def human_input_is_singular_es(evt : EventCheckHumanInputIsSingular; eid : EntityId)
  let thisEid = eid
  ecs::query() <| $ [es(REQUIRE=human_input)] (eid : EntityId)
    if eid != thisEid
      logerr("Created > 1 human_input component {int(uint(thisEid))} and {int(uint(eid))}")

[es(tag=input, on_appear, REQUIRE=human_input)]
def human_input_appear_es(evt : Event;
                          eid : EntityId;
                          transform : float3x4 const?;
                          var human_input__aimAngle : float2&;
                          var human_input__aim : int&;
                          var human_input__aimDelta : int&;
                          var human_input__look : int&;
                          var human_input__move : int&;
                          var human_input__leanX : int&;
                          var human_input__sprint : int&;
                          var human_input__holdBreath : int&;
                          var human_input__aim1 : int&;
                          var human_input__aim2 : int&;
                          var human_input__zoom : int&;
                          var human_input__sightNext : int&;
                          var human_input__sightPrev : int&;
                          var human_input__cameraNext : int&;
                          var human_input__use : int&)
  // While entity is just [re]created, there still can be other entities yet in the recreation process still with human_input
  sendEvent(eid, [[EventCheckHumanInputIsSingular]])

  human_input__aimAngle = dir_to_angles((transform ?? IDENT_TM)[0])

  init(human_input__aim, human_input__aimDelta, human_input__look, human_input__move,
       human_input__leanX, human_input__sprint, human_input__holdBreath, human_input__aim1,
       human_input__aim2, human_input__zoom, human_input__sightNext, human_input__sightPrev,
       human_input__cameraNext, human_input__use)


[es(tag=input, on_disappear, REQUIRE=human_input)]
def human_input_destroyed_es(evt : Event;
                             var human_input__aim : int&;
                             var human_input__aimDelta : int&;
                             var human_input__look : int&;
                             var human_input__move : int&;
                             var human_input__leanX : int&;
                             var human_input__sprint : int&;
                             var human_input__holdBreath : int&;
                             var human_input__aim1 : int&;
                             var human_input__aim2 : int&;
                             var human_input__zoom : int&;
                             var human_input__sightNext : int&;
                             var human_input__sightPrev : int&;
                             var human_input__cameraNext : int&;
                             var human_input__use : int&)
  reset(human_input__aim, human_input__aimDelta, human_input__look, human_input__move,
        human_input__leanX, human_input__sprint, human_input__holdBreath, human_input__aim1,
        human_input__aim2, human_input__zoom, human_input__sightNext, human_input__sightPrev,
        human_input__cameraNext, human_input__use)


[es(tag=input, REQUIRE=human_input)]
def human_input_init_es(evt : EventDaInputInit;
                        input__enabled : bool;
                        var human_input__aim : int&;
                        var human_input__aimDelta : int&;
                        var human_input__look : int&;
                        var human_input__move : int&;
                        var human_input__leanX : int&;
                        var human_input__sprint : int&;
                        var human_input__holdBreath : int&;
                        var human_input__aim1 : int&;
                        var human_input__aim2 : int&;
                        var human_input__zoom : int&;
                        var human_input__sightNext : int&;
                        var human_input__sightPrev : int&;
                        var human_input__cameraNext : int&;
                        var human_input__use : int&)
  if !input__enabled
    return
  if evt.init
    init(human_input__aim, human_input__aimDelta, human_input__look, human_input__move,
         human_input__leanX, human_input__sprint, human_input__holdBreath, human_input__aim1,
         human_input__aim2, human_input__zoom, human_input__sightNext, human_input__sightPrev,
         human_input__cameraNext, human_input__use)
  else
    reset(human_input__aim, human_input__aimDelta, human_input__look, human_input__move,
          human_input__leanX, human_input__sprint, human_input__holdBreath, human_input__aim1,
          human_input__aim2, human_input__zoom, human_input__sightNext, human_input__sightPrev,
          human_input__cameraNext, human_input__use)

[es(tag=input, after=human_input_es)]
def human_input_aim_in_crawling_es(info : UpdateStageUpdateInput;
                                   human_input__move : int;
                                   human_input__standState : int;
                                   human_input__aim2 : int;
                                   var human_net_phys : HumanActor&;
                                   var human_input__wishMove : bool&;
                                   var human_input__wishAim : bool&;
                                   var human_input__crawlingReject : bool&)
  if human_input__standState != int(HumanPhysControlType HCT_CRAWL)
    human_input__wishAim = false
    human_input__wishMove = false
    human_input__crawlingReject = false
    return

  let isAim = is_action_active(uint16(human_input__aim2)) ? get_digital_action_state(uint16(human_input__aim2)).bState : false
  let moveState = get_analog_stick_action_state(uint16(human_input__move))
  let isMove = moveState.x > MOVE_THRESHOLD || moveState.x < -MOVE_THRESHOLD || moveState.y > MOVE_THRESHOLD || moveState.y < -MOVE_THRESHOLD

  if isMove && isAim && (human_input__wishMove || human_input__wishAim)
    if human_input__wishAim
      human_input__crawlingReject = true
    elif human_input__wishMove
      human_input__crawlingReject = false
    human_input__wishMove = false
    human_input__wishAim = false

  elif !isMove
    human_input__wishMove = true

  elif !isAim
    human_input__wishAim = true
    human_input__crawlingReject = false

  if isMove && !human_input__crawlingReject && isAim
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit((HumanPhysControlType HCT_ZOOM_VIEW), false)


[es(tag=input, after=human_input_es)]
def human_input_disable_toggle_aim_es(info : UpdateStageUpdateInput;
                                      isInVehicle : bool;
                                      human_input__aim1 : int;
                                      human_input__zoom : int;
                                      human_weap__currentGunEid : EntityId;
                                      human_input__forceAim : bool;
                                      human_anim__vehicleSelected : EntityId;
                                      human_vehicle__isShootingPassenger : bool;
                                      var human_net_phys : HumanActor)
  if get_bool(human_weap__currentGunEid, "gun__disableToggleAim") ?? false
    var vehicleInputZoomToggle : int const? = null
    var vehicleInputZoom : int const? = null
    if isInVehicle
      query(human_anim__vehicleSelected) <| $ [es] (vehicle_input__zoomToggle : int const?; vehicle_input__zoom : int const?)
        vehicleInputZoomToggle = vehicle_input__zoomToggle
        vehicleInputZoom = vehicle_input__zoom

    let inputAim1 = human_vehicle__isShootingPassenger ? vehicleInputZoomToggle ?? human_input__aim1 : human_input__aim1
    let inputZoom = human_vehicle__isShootingPassenger ? vehicleInputZoom ?? human_input__zoom : human_input__zoom

    let isAim1 = is_action_active(uint16(inputAim1)) ? get_digital_action_state(uint16(inputAim1)).bState : false
    let isZoom = is_action_active(uint16(inputZoom)) ? get_digital_action_state(uint16(inputZoom)).bState : false
    human_net_phys.phys.producedCT |> human_control_state_set_control_bit((HumanPhysControlType HCT_ZOOM_VIEW), isAim1 || isZoom || human_input__forceAim)


def find_gunmod_with_toggle_aim_block(current_gun_mod_eids : EidList)
  for modEid in current_gun_mod_eids
    if get_bool(modEid, "gunmod__disableToggleAim") ?? false
      return true
  return false


[es(tag=input, track=human_weap__currentGunModEids)]
def disable_toggle_aim_by_gun_mod_es(evt : Event; human_weap__currentGunEid : EntityId; human_weap__currentGunModEids : EidList)
  var disableToggleAim = getRW_bool(human_weap__currentGunEid, "gun__disableToggleAim")
  if disableToggleAim != null
    *disableToggleAim = find_gunmod_with_toggle_aim_block(human_weap__currentGunModEids)


[es(tag=input, on_appear)]
def scope_create_es(evt : Event; gunmod__disableToggleAim : bool; slot_attach__attachedTo : EntityId)
  var disableToggleAim = getRW_bool(slot_attach__attachedTo, "gun__disableToggleAim")
  if disableToggleAim != null
    *disableToggleAim = *disableToggleAim || gunmod__disableToggleAim

[es(tag=input, on_event=EventHeroChanged, REQUIRE=human_net_phys)]
def human_input_hero_changed_es(evt : Event; human_input__aim1 : int; var human_input__hasValidState : bool&)
  human_input__hasValidState = false
  reset_digital_action_sticky_toggle(uint16(human_input__aim1))


[es(tag=input, on_appear, REQUIRE=deadEntity)]
def human_input_hero_died_es(evt : Event; human_input__aim1 : int; var human_input__hasValidState : bool&)
  human_input__hasValidState = false
  reset_digital_action_sticky_toggle(uint16(human_input__aim1))


[es(tag=input, REQUIRE=hero, track=human_weap__staminaCanAim)]
def reset_aim_input_on_low_stamina(evt : Event;
                                   human_input__aim1 : int;
                                   human_weap__staminaCanAim : bool)
  if !human_weap__staminaCanAim
    reset_digital_action_sticky_toggle(uint16(human_input__aim1))

[es(tag=input, REQUIRE_NOT=deadEntity)]
def human_use_object_input(evt : EventDaInputActionTriggered;
                           input__enabled : bool;
                           human_input__use : int;
                           eid : EntityId;
                           transform : float3x4;
                           isDowned : bool = false;
                           human_use_object__selectedObject : EntityId;
                           human_use_object__thresholdDist : float = 12.f)
  if input__enabled && int(evt.action) == human_input__use && !isDowned
    human_try_use_object(eid, transform[3],
      human_use_object__thresholdDist, human_use_object__selectedObject)


[es(tag=input, REQUIRE=hero, track=human_net_phys__isHoldBreath)]
def human_input_reset_hold_breath_sticky_toggle_on_disable(evt : Event;
                                                           human_input__holdBreath : int;
                                                           human_net_phys__isHoldBreath : bool)
  if !human_net_phys__isHoldBreath
    reset_digital_action_sticky_toggle(uint16(human_input__holdBreath))
