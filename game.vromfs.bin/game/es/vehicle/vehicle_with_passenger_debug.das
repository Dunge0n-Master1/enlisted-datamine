options no_aot
require ecs
require player
require game.es.vehicle.vehicle_events
require game.es.net_console_macro
require DngNet
require DagorConsole

[console_cmd(name="vehicle.spawn_crew")]
def debug_vehicle_spawn_crew(team : int = TEAM_UNASSIGNED;
                             crew_template : string = "dev_soldier";
                             player_template : string = "bot_player";
                             vehicle_eid : uint = 0u)
  var vehicle = EntityId(vehicle_eid)
  if !vehicle
    query() <| $ [es(REQUIRE=daeditor__selected)] (eid : EntityId)
      vehicle = eid

  if !is_server()
    exec_server_cmd("vehicle.spawn_crew {team} {crew_template} {player_template} {vehicle}")
    return

  query(vehicle) <| $ [es] (eid aka vehicle_eid : EntityId;
                            vehicle_seats__seatEids : EidList)
    var seats : array<int>
    for seat in vehicle_seats__seatEids
      query(seat) <| $ [es] (seat__ownerEid : EntityId; seat__id : int)
        let hasOwner = query(seat__ownerEid) <| $ [es(REQUIRE_NOT=deadEntity)] () {}
        if !hasOwner
          seats |> push(seat__id)
    visual_log("spawn crew {length(seats)} for {getEntityTemplateName(vehicle_eid)}")
    if !empty(seats)
      let playerEid = createEntity(player_template) <| $(var init)
        set(init, "canBeLocal", false)
        set(init, "team", team)
      for seatId in seats
        let finalize <- @ <| (crewEid : EntityId)
          query(crewEid) <| $ [es] (use_vehicle_on_spawn__vehicle : EntityId; use_vehicle_on_spawn__seatNo : int)
            sendEvent(playerEid, [[CmdUseVehicleOnSpawn vehicle=use_vehicle_on_spawn__vehicle, seatOrderNo=use_vehicle_on_spawn__seatNo, squad=INVALID_ENTITY_ID, possessed=crewEid]])
        createEntity("{crew_template}+use_vehicle_on_spawn", finalize) <| $(var init)
          set(init, "use_vehicle_on_spawn__vehicle", vehicle_eid)
          set(init, "use_vehicle_on_spawn__seatNo", seatId)
          set(init, "squad_member__playerEid", playerEid)
          set(init, "team", team)
