require ecs
require ecs.common
require game.es.input.input_events
require DagorInput
require EnlistedInputControls
require common_shooter.es.input.turret_input_common

enum PlaneTrigger : int
  MACHINE_GUNS
  CANNONS
  BOMBS
  ROCKETS
  ADDITIONAL_GUNS



def init(var plane_input__bomb : int&;
         var plane_input__rocket : int&;
         var plane_input__aim : int&;
         var plane_input__zoomToggle : int&;
         var plane_input__shoot : int&;
         var plane_input__shootCannons : int&;
         var plane_input__shootAdditionalGuns : int&)
  plane_input__bomb                = int(get_action_handle("Plane.Bomb", TYPEGRP_DIGITAL))
  plane_input__rocket              = int(get_action_handle("Plane.Rocket", TYPEGRP_DIGITAL))
  plane_input__aim                 = int(get_action_handle("Plane.Aim", TYPEGRP_STICK))
  plane_input__zoomToggle          = int(get_action_handle("Plane.ZoomToggle", TYPEGRP_DIGITAL))
  plane_input__shoot               = int(get_action_handle("Plane.Shoot", TYPEGRP_DIGITAL))
  plane_input__shootCannons        = int(get_action_handle("Plane.ShootCannons", TYPEGRP_DIGITAL))
  plane_input__shootAdditionalGuns = int(get_action_handle("Plane.ShootAdditionalGuns", TYPEGRP_DIGITAL))



def reset(var plane_input__bomb : int&;
          var plane_input__rocket : int&;
          var plane_input__aim : int&;
          var plane_input__zoomToggle : int&;
          var plane_input__shoot : int&;
          var plane_input__shootCannons : int&;
          var plane_input__shootAdditionalGuns : int&)
  plane_input__bomb                = int(BAD_ACTION_HANDLE)
  plane_input__rocket              = int(BAD_ACTION_HANDLE)
  plane_input__aim                 = int(BAD_ACTION_HANDLE)
  plane_input__zoomToggle          = int(BAD_ACTION_HANDLE)
  plane_input__shoot               = int(BAD_ACTION_HANDLE)
  plane_input__shootCannons        = int(BAD_ACTION_HANDLE)
  plane_input__shootAdditionalGuns = int(BAD_ACTION_HANDLE)


def stop_weapons(turret_control__gunEids : EidList; trigger : PlaneTrigger)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_input__turretTriggers : int; var turret_input__shootFlag : bool&)
      if turret_input__turretTriggers == int(trigger)
        turret_input__shootFlag = false


def release_weapon(turret_control__gunEids : EidList; action : int; trigger : PlaneTrigger; salvo_size : int)
  let triggerState = get_digital_action_state(uint16(action)).bState

  var firedNum = 0
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_input__turretTriggers : int; gun__ammo : int; var turret_input__shootFlag : bool&)
      if turret_input__turretTriggers == int(trigger)
        turret_input__shootFlag = triggerState
        if turret_input__shootFlag && gun__ammo > 0
          ++firedNum
    if firedNum >= salvo_size
      break


[es(tag=input, on_appear)]
def plane_turret_input_appear(evt : Event;
                              var plane_input__bomb : int&;
                              var plane_input__rocket : int&;
                              var plane_input__aim : int&;
                              var plane_input__zoomToggle : int&;
                              var plane_input__shoot : int&;
                              var plane_input__shootCannons : int&;
                              var plane_input__shootAdditionalGuns : int&)
  init(plane_input__bomb, plane_input__rocket, plane_input__aim, plane_input__zoomToggle,
       plane_input__shoot, plane_input__shootCannons, plane_input__shootAdditionalGuns)

[es(tag=input, on_disappear)]
def plane_turret_input_disappear(evt : Event;
                                 var plane_input__bomb : int&;
                                 var plane_input__rocket : int&;
                                 var plane_input__aim : int&;
                                 var plane_input__zoomToggle : int&;
                                 var plane_input__shoot : int&;
                                 var plane_input__shootCannons : int&;
                                 var plane_input__shootAdditionalGuns : int&)
  reset(plane_input__bomb, plane_input__rocket, plane_input__aim, plane_input__zoomToggle,
        plane_input__shoot, plane_input__shootCannons, plane_input__shootAdditionalGuns)

[es(tag=input)]
def plane_turret_input_init_reset(evt : EventDaInputInit;
                                  var plane_input__bomb : int&;
                                  var plane_input__rocket : int&;
                                  var plane_input__aim : int&;
                                  var plane_input__zoomToggle : int&;
                                  var plane_input__shoot : int&;
                                  var plane_input__shootCannons : int&;
                                  var plane_input__shootAdditionalGuns : int&)
  if evt.init
    init(plane_input__bomb, plane_input__rocket, plane_input__aim, plane_input__zoomToggle,
         plane_input__shoot, plane_input__shootCannons, plane_input__shootAdditionalGuns)
  else
    reset(plane_input__bomb, plane_input__rocket, plane_input__aim, plane_input__zoomToggle,
          plane_input__shoot, plane_input__shootCannons, plane_input__shootAdditionalGuns)


[es(on_appear, REQUIRE=resolvedTurret)]
def plane_turret_init_triggers(evt : Event;
                               turret__owner : EntityId;
                               turret__id : int;
                               var turret_input__turretTriggers : int&)
  query(turret__owner) <| $ [es] ([[shared_comp]] turret_control__turretInfo : Array)
    let obj = get_ecs_object(turret_control__turretInfo[turret__id])
    let trigger = get_string(obj, "trigger", "")
    turret_input__turretTriggers = int(
      trigger == "additional_guns" ? PlaneTrigger ADDITIONAL_GUNS :
      trigger == "cannons" ? PlaneTrigger CANNONS :
      trigger == "bombs" ? PlaneTrigger BOMBS :
      trigger == "rockets" ? PlaneTrigger ROCKETS :
      PlaneTrigger MACHINE_GUNS
    )

[es(tag=input)]
def plane_input_gunner_es(info : UpdateStageInfoAct;
                          input__enabled : bool;
                          plane_input__shoot : int;
                          plane_input__shootCannons : int;
                          plane_input__shootAdditionalGuns : int;
                          turret_control__gunEids : EidList)
  if !input__enabled
    return
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_input__turretTriggers : int; var turret_input__shootFlag : bool&)
      var shootAction = int(BAD_ACTION_HANDLE)
      if turret_input__turretTriggers == int(PlaneTrigger MACHINE_GUNS)
        shootAction = plane_input__shoot
      elif turret_input__turretTriggers == int(PlaneTrigger CANNONS)
        shootAction = plane_input__shootCannons
      elif turret_input__turretTriggers == int(PlaneTrigger ADDITIONAL_GUNS)
        shootAction = plane_input__shootAdditionalGuns

      if shootAction != int(BAD_ACTION_HANDLE) && get_digital_action_state(uint16(shootAction)).bActive
        turret_input__shootFlag = get_digital_action_state(uint16(shootAction)).bState

[es(tag=input, after=plane_input_gunner_es)]
def plane_input_gunner_aim(info : UpdateStageInfoAct;
                           input__enabled : bool;
                           turret_control__gunEids : EidList;
                           plane_input__aim : int;
                           plane_input__zoomToggle : int;
                           var disableTurretCam : bool&)
  if !input__enabled
    return
  var aAim = get_analog_stick_action_state(uint16(plane_input__aim))
  assume sens_scale = get_sens_scale()
  aAim.x *= sens_scale.vehicleCam
  aAim.y *= sens_scale.vehicleCam

  disableTurretCam = !aAim.bActive;

  let zoomToggle = get_digital_action_state(uint16(plane_input__zoomToggle))
  apply_turret_input(turret_control__gunEids, aAim, zoomToggle, zoomToggle)

[es(tag=input)]
def plane_input_bomb_input_triggered(evt : EventDaInputActionTriggered;
                                     input__enabled : bool;
                                     plane_input__bomb : int;
                                     turret_control__gunEids : EidList;
                                     turret_control__bombsSalvoSize : int)
  if input__enabled && int(evt.action) == plane_input__bomb
    release_weapon(turret_control__gunEids, plane_input__bomb, PlaneTrigger BOMBS, turret_control__bombsSalvoSize)

[es(tag=input)]
def plane_input_bomb_input_terminate(evt : EventDaInputActionTerminated;
                                     input__enabled : bool;
                                     plane_input__bomb : int;
                                     turret_control__gunEids : EidList)
  if input__enabled && int(evt.action) == plane_input__bomb
    stop_weapons(turret_control__gunEids, PlaneTrigger BOMBS)

[es(tag=input)]
def plane_input_rocket_input_triggered(evt : EventDaInputActionTriggered;
                                       input__enabled : bool;
                                       plane_input__rocket : int;
                                       turret_control__gunEids : EidList;
                                       turret_control__rocketsSalvoSize : int)
  if input__enabled && int(evt.action) == plane_input__rocket
    release_weapon(turret_control__gunEids, plane_input__rocket, PlaneTrigger ROCKETS, turret_control__rocketsSalvoSize)

[es(tag=input)]
def plane_input_rocket_input_terminate(evt : EventDaInputActionTerminated;
                                       input__enabled : bool;
                                       plane_input__rocket : int;
                                       turret_control__gunEids : EidList)
  if input__enabled && int(evt.action) == plane_input__rocket
    stop_weapons(turret_control__gunEids, PlaneTrigger ROCKETS)