require ecs
require math.base
require Plane
require player
require DagorInput
require EnlistedPlane
require game.es.events
require game.es.input.input_events
require enlisted.tutorial.tutorial_common
require common_shooter.events_common_shooter

let YAW_LIMIT   = float2(0.32f, 0.37f)
let PITCH_LIMIT = float2(-0.02f, 0.02f)

[es(on_event=EventEntityCreated)]
def tutorial_axies_input_init_es(evt : Event; tutor_stage__triggerAxisInput : string; var tutor_stage__axisInput : int&)
  tutor_stage__axisInput = int(get_action_handle(tutor_stage__triggerAxisInput, TYPEGRP_AXIS))

[es(no_order)]
def tutorial_axies_input_es(info : UpdateStageInfoAct; eid : EntityId; tutor_stage__axisInput : int)
  let axis = get_analog_axis_action_state(uint16(tutor_stage__axisInput))
  if axis.bActive && axis.x != 0.5f
    destroyEntity(eid)

[es(on_event=EventEntityCreated)]
def tutorial_action_spawn_aircraft_es(evt : Event; tutor_action__spawnAircraftTarget : string)
  query() <| $ [es(REQUIRE=hero)] (transform : float3x4)
    createEntity(tutor_action__spawnAircraftTarget) <| $(var init : ComponentsInitializer)
      set(init, "startVelDir", float3(1.f, 0.f, 0.f))
      set(init, "startRelativeSpeed", 1f)

      var tm = IDENT_TM
      tm[3] = transform[3] + float3(20f, 50.f, 0.f)
      set(init, "transform", tm)
      set(init, "team", 2)

[es(on_event=EventEntityCreated, REQUIRE=tutor_action__destroyAircraftTarget)]
def tutor_action_destroy_aircraft_target(evt : Event)
  query() <| $ [es(REQUIRE=aircraft_autopilot__elevatorCoef)] (eid : EntityId)
    destroyEntity(eid) // TODO: Expl effect

[es(after=after_net_phys_sync)]
def tutorial_aircraft_autopilot_es(info : UpdateStageInfoAct;
                                   var plane_net_phys : PlaneActor&;
                                   transform : float3x4;
                                   var aircraft_autopilot__elevatorCoef : float&;
                                   var aircraft_autopilot__rudderCoef : float&)
  let yaw = transform[2][1]
  if yaw >= YAW_LIMIT[1]
    aircraft_autopilot__elevatorCoef = -0.1f
  elif yaw <= YAW_LIMIT[0]
    aircraft_autopilot__rudderCoef = 0.1f

  let pitch = transform[0][1]
  if pitch >= PITCH_LIMIT[1]
    aircraft_autopilot__elevatorCoef = -0.1f
  elif pitch <= PITCH_LIMIT[0]
    aircraft_autopilot__rudderCoef = 0.1f

  plane_net_phys.phys |> flight_model_setElevatorControl(aircraft_autopilot__elevatorCoef)
  plane_net_phys.phys |> flight_model_setRudderControl(aircraft_autopilot__rudderCoef)

[es(on_event=CmdResupplyVehicle, REQUIRE=heroVehicle)]
def tutorial_vehicle_resupply_es(evt : Event)
  query() <| $ [es(REQUIRE=tutor_condition__resupplyVehicle)] (eid : EntityId)
    destroyEntity(eid)

def private tutorial_aircraft_out_of_bomb(condition_eid : EntityId; ui_turrets_state__ammo : Object)
  let bombTurrets = ui_turrets_state__ammo["bomb_turrets"]
  if bombTurrets == null
    return

  let bombTurretsObj = get_ecs_object(bombTurrets)
  let groupAmmo = get_int(bombTurretsObj, "groupAmmo") ?? 0
  let firstLoadedGunInGroup = get_Eid(bombTurretsObj, "firstLoadedGunInGroup") ?? INVALID_ENTITY_ID
  if groupAmmo <= 0 && !firstLoadedGunInGroup
    destroyEntity(condition_eid)

[es(track=ui_turrets_state__ammo, REQUIRE=heroVehicle)]
def tutorial_aircraft_out_of_bomb_es(evt : Event; ui_turrets_state__ammo : Object)
  query() <| $ [es(REQUIRE=tutor_condition__outOfBombs)] (eid : EntityId)
    tutorial_aircraft_out_of_bomb(eid, ui_turrets_state__ammo)

[es(on_appear, REQUIRE=tutor_condition__outOfBombs)]
def tutorial_aircraft_out_of_bomb_init_es(evt : Event; eid : EntityId)
  query() <| $ [es(REQUIRE=heroVehicle)] (ui_turrets_state__ammo : Object)
    tutorial_aircraft_out_of_bomb(eid, ui_turrets_state__ammo)

[es(REQUIRE=(hero, isAlive), track=isAlive)]
def tutorial_aircraft_respawn_squad_es(evt : Event; isAlive : bool)
  if !isAlive
    spawn_squad_immediate()

[es(tag=gameClient, on_appear, after=(plane_turret_input_appear, plane_turret_input_init_reset))]
def tutorial_aircraft_disable_drop_bomb_es(evt : Event; var plane_input__bomb : int&)
  find_query() <| $ [es(REQUIRE=tutorial_aircraft__disableDropBomb)] ()
    plane_input__bomb = int(BAD_ACTION_HANDLE)
    return true

[es(tag=gameClient, on_disappear, REQUIRE=tutorial_aircraft__disableDropBomb)]
def tutorial_aircraft_enable_drop_bomb_es(evt : Event)
  query() <| $ [es] (var plane_input__bomb : int&)
    plane_input__bomb = int(get_action_handle("Plane.Bomb", TYPEGRP_DIGITAL))

[es(track=parachute__deployed)]
def tutorial_parachute_deploy_action_es(evt : Event; parachute__deployed : bool; item__ownerEid : EntityId)
  if !parachute__deployed
    return
  query(item__ownerEid) <| $ [es(REQUIRE=hero)] ()
    query() <| $ [es(REQUIRE=tutor_condition__parachuteOpen)] (eid : EntityId)
      destroyEntity(eid)

[es(REQUIRE=tutor_condition__parachuteOpen, on_appear)]
def tutorial_condition_parachute_open(evt : Event; eid : EntityId)
  query() <| $ [es(REQUIRE=hero)] (human_parachute__eid : EntityId)
    query(human_parachute__eid) <| $ [es] (parachute__deployed : bool)
      if parachute__deployed
        destroyEntity(eid)

[es(on_appear, REQUIRE=turret_input__aimPos)]
def hero_disable_turret_input_plane_es(evt : Event; eid : EntityId)
  query() <| $ [es(REQUIRE=tutorial_aircraft__disableTurret)] ()
    removeSubTemplate(eid, "turret_input")

[es(on_appear, REQUIRE=tutorial_aircraft__disableTurret)]
def hero_disable_turret_input_es(evt : Event)
  query() <| $ [es(REQUIRE=turret_input__aimPos)] (eid : EntityId)
    removeSubTemplate(eid, "turret_input")

[es(on_disappear, REQUIRE=tutorial_aircraft__disableTurret)]
def hero_vehicle_restore_turret_input_es(evt : Event)
  query() <| $ [es(REQUIRE=heroVehicle)] (eid : EntityId)
    sendEvent(eid, [[EventOnGunCreated]])
