options no_aot
require ecs
require ecs.extra_set
require app
require game.es.turrets_common
require common_shooter.events_common_shooter
require math.base
require player
require game.es.events
require game.es.vehicle.vehicle_events
require DagorConsole
require game.es.net_console_macro
require enlisted.events_enlisted
require ecs.ecs_template

def create_ai_aircraft(airplaneName : string; posFrom : float3; posTo : float3)
  createEntity(airplaneName + "+ai_aircraft+plane_spawn_in_air+ai_aircraft_crew_ger") <| $(var init : ComponentsInitializer)
    set(init, "startVelDir", float3(1.f, 0.f, 0.f))
    set(init, "startRelativeSpeed", 0.9f)
    set(init, "ai_aircraft__wishSpeed", 90.f)

    set(init, "team", 0)

    set(init, "ai_aircraft__flyPos", posTo)

    var tm = IDENT_TM
    tm[3]  = posFrom
    set(init, "transform", tm)

[console_cmd(name="aircraft.testAIGunners")]
def aircraft_test_ai_gunners_debug(posOffenderX : float;
                                   posOffenderY : float;
                                   posOffenderZ : float;
                                   posVictimX : float;
                                   posVictimY : float;
                                   posVictimZ : float;
                                   flyToPosX : float;
                                   flyToPosY : float;
                                   flyToPosZ : float;
                                   airplaneName : string)
  create_ai_aircraft(airplaneName, float3(posOffenderX, posOffenderY, posOffenderZ) + float3(+0., 0., 0.), float3(flyToPosX, flyToPosY, flyToPosZ) + float3(+0., 0., 0.))
  create_ai_aircraft(airplaneName, float3(posOffenderX, posOffenderY, posOffenderZ) + float3(-30., 0., -30.), float3(flyToPosX, flyToPosY, flyToPosZ) + float3(-30., 0., -30.))
  create_ai_aircraft(airplaneName, float3(posOffenderX, posOffenderY, posOffenderZ) + float3(-30., 0., +30.), float3(flyToPosX, flyToPosY, flyToPosZ) + float3(-30., 0., +30.))
  create_ai_aircraft(airplaneName, float3(posOffenderX, posOffenderY, posOffenderZ) + float3(-60., 0., -60.), float3(flyToPosX, flyToPosY, flyToPosZ) + float3(-60., 0., -60.))
  create_ai_aircraft(airplaneName, float3(posOffenderX, posOffenderY, posOffenderZ) + float3(-60., 0., +60.), float3(flyToPosX, flyToPosY, flyToPosZ) + float3(-60., 0., +60.))

  var playerEid = get_local_player_eid()
  if !playerEid
    find_query() <| $ [es(REQUIRE=player)] (eid : EntityId) { playerEid = eid; return true; }

  query() <| $ [es(REQUIRE=hero)] (eid : EntityId; squad_member__squad : EntityId)
    let finalizeCreation <- @ <| (vehicleEid : EntityId)
      sendEventImmediate(playerEid, [[CmdUseVehicleOnSpawn possessed=eid, squad=squad_member__squad, vehicle=vehicleEid, seatOrderNo=0]])

    createEntity(airplaneName + "+plane_spawn_in_air", finalizeCreation) <| $(var init : ComponentsInitializer)
      set(init, "startVelDir", float3(1.f, 0.f, 0.f))
      set(init, "startRelativeSpeed", 0.9f)
      set(init, "team", 1)

      var tm = IDENT_TM
      tm[3]  = float3(posVictimX, posVictimY, posVictimZ)
      set(init, "transform", tm)

[net_console_cmd(name="aircraft.spawnInAir")]
def aircraft_debug(airplane_template = "il_2_1941"; [[net_player]] player_eid : EntityId)
  let possessed = get_Eid(player_eid, "possessed") ?? INVALID_ENTITY_ID
  query(possessed) <| $ [es] (eid : EntityId; transform : float3x4; squad_member__squad : EntityId)
    let finalizeCreation <- @ <| (vehicleEid : EntityId)
      sendEventImmediate(player_eid, [[CmdUseVehicleOnSpawn possessed=eid, squad=squad_member__squad, vehicle=vehicleEid, seatOrderNo=0]])

    createEntity("{airplane_template}+plane_spawn_in_air", finalizeCreation) <| $(var init : ComponentsInitializer)
      set(init, "startVelDir", float3(1.f, 0.f, 0.f))
      set(init, "startRelativeSpeed", 1.f)

      var tm = IDENT_TM
      tm[3] = transform[3] + float3(0.f, 1000.f, 0.f)
      set(init, "transform", tm)

[console_cmd(name="aircraft.dropBomb")]
def aircraft_dropBomb(bomb_gun_templ : string = "planegun_il_2_1941_fab_50_launcher_01"; start_vel : float = 50.; hero_eid = 0u)
  console_command("gun.shoot {bomb_gun_templ} 0 {start_vel}")

[console_cmd(name="aircraft.dropBombCam")]
def aircraft_dropBombCam(bomb_gun_templ : string = "planegun_il_2_1941_fab_50_launcher_01"; start_vel : float = 50.)
  console_command("gun.shootFromCam {bomb_gun_templ} 0 {start_vel}")

[console_cmd(name="aircraft.dropBombCam250")]
def aircraft_dropBombCam250(bomb_gun_templ : string = "planegun_bf_109g_2_trop_sc_250_launcher_01"; start_vel : float = 50.)
  console_command("gun.shootFromCam {bomb_gun_templ} 0 {start_vel}")

[console_cmd(name="aircraft.bombTanks")]
def aircraft_bombTanks(bomb_gun_templ : string = "planegun_bf_109g_2_trop_sc_250_launcher_01")
  query() <| $ [es(REQUIRE=isTank)] (transform : float3x4)
    console_command("gun.shootFromCam {bomb_gun_templ} 0 0.0 1.0 1.0 1.0 {transform[3][0]} {transform[3][1] + 10.} {transform[3][2]}")

[console_cmd(name="spawn.plane_side")]
def debug_spawn_plane_side(dist : float = 500.0; side_dist : float = 300.0; relative_height : float = 0.0)
  query() <| $ [es] (possessedByPlr : EntityId; transform : float3x4; team : int)
    if !possessedByPlr
      return

    let up = float3(0, 1, 0)
    let pos = transform[3]
    let dir = transform[0]
    let side = transform[2]
    createEntity("bf_109g_6+plane_spawn_in_air+vehicle_with_passenger") <| $(var init : ComponentsInitializer)
      let enemyTeam = (team % 2) + 1
      var tm = IDENT_TM
      tm[3] = pos + dir * dist - side * side_dist + up * relative_height
      tm[0] = transform[2]
      tm[1] = transform[1]
      tm[2] = transform[0]
      set(init, "transform", tm)
      set(init, "team", enemyTeam)
      set(init, "vehicle_with_passenger__humanTemplate", "tutorial_tank_passenger")
      set(init, "vehicle_with_passenger__team", enemyTeam)

[console_cmd(name="spawn.plane")]
def debug_spawn_plane(dist : float = 300.0; same_course = true; relative_height : float = 0.0)
  query() <| $ [es] (possessedByPlr : EntityId; transform : float3x4; team : int)
    if !possessedByPlr
      return

    let up = float3(0, 1, 0)
    let pos = transform[3]
    let dir = transform[0]
    createEntity("bf_109g_6+plane_spawn_in_air+vehicle_with_passenger") <| $(var init : ComponentsInitializer)
      let enemyTeam = (team % 2) + 1
      var tm = IDENT_TM
      tm[3] = pos + dir * dist + up * relative_height
      tm[0] = transform[0] * (same_course ? 1.0 : -1.0)
      tm[1] = transform[1]
      tm[2] = transform[2]
      set(init, "transform", tm)
      set(init, "team", enemyTeam)
      set(init, "startRelativeSpeed", 0.3)
      set(init, "vehicle_with_passenger__humanTemplate", "tutorial_tank_passenger")
      set(init, "vehicle_with_passenger__team", enemyTeam)

[ecs_template]
struct debug_dummy_artillery_player
  artillery__templates : StringList
  team : int
  dummyArtilleryPlayer : Tag

[net_console_cmd(name="ai_bombers.request", hint="<x> <y> <z> <template> <team> Request ai bombers raid at pos")]
def request_debug_ai_bombers(x = 0; y = 0; z = 0; artillery_template : string = "stalingrad_ger_team_aircraft_request"; team : int = TEAM_UNASSIGNED - 1; [[net_player]] player_eid : EntityId)
  let artilleryTeam = team >= TEAM_UNASSIGNED ? team : 1 + ((get_int(player_eid, "team") ?? TEAM_UNASSIGNED)) % 2

  query() <| $ [es(REQUIRE=artillery__targetPos)] (eid : EntityId; artillery__callerEid : EntityId)
    if (get_int(artillery__callerEid, "team") ?? TEAM_UNASSIGNED) == artilleryTeam
      destroyEntity(eid)

  let callback <- @ <| (dummy_player : EntityId)
    let pos = float3(x, y, z)
    sendEvent(dummy_player, [[CmdStartArtilleryStrikeAtPos owner=dummy_player, pos=pos, typeIndex=0, posEnd=pos]])

  createEntity("debug_dummy_artillery_player", callback) <| $(var init)
    init |> set("team", artilleryTeam)

    init |> set("artillery__templates", [{auto artillery_template}])
