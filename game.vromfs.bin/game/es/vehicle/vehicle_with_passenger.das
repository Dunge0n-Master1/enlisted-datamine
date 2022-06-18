require ecs
require player
require game.es.vehicle.vehicle_events
require DagorSystem

[es(tag=server, on_appear)]
def vehicle_with_passenger_player_init_es(evt : Event;
                                          vehicle_with_passenger__playerTemplate : string;
                                          vehicle_with_passenger__team : int;
                                          var vehicle_with_passenger__playerEid : EntityId&)
  if !!vehicle_with_passenger__playerEid
    return

  let eid = createEntity(vehicle_with_passenger__playerTemplate) <| $(var init)
    set(init, "canBeLocal", false)
    set(init, "team", vehicle_with_passenger__team)
  vehicle_with_passenger__playerEid = eid

[es(tag=server, on_appear)]
def vehicle_with_passenger_init_es(evt : Event;
                                   seat__id : int;
                                   seat__vehicleEid : EntityId)
  query(seat__vehicleEid) <| $ [es] (vehicle_with_passenger__humanTemplate : string;
                                     vehicle_with_passenger__team : int;
                                     vehicle_with_passenger__playerEid : EntityId)
    if vehicle_with_passenger__humanTemplate == ""
      logerr("Empty human template on entity <{seat__vehicleEid}> with template: {getEntityTemplateName(seat__vehicleEid)}!")
      return

    createEntity("{vehicle_with_passenger__humanTemplate}+use_vehicle_on_spawn") <| $(var init)
      set(init, "use_vehicle_on_spawn__vehicle", seat__vehicleEid)
      set(init, "use_vehicle_on_spawn__seatNo", seat__id)
      set(init, "squad_member__playerEid", vehicle_with_passenger__playerEid)
      set(init, "team", vehicle_with_passenger__team)

[es(tag=server, on_appear)]
def use_vehicle_on_spawn_es(evt : Event;
                            eid : EntityId;
                            use_vehicle_on_spawn__vehicle : EntityId;
                            use_vehicle_on_spawn__seatNo : int)
  let vehicle = use_vehicle_on_spawn__vehicle
  let seatNo = use_vehicle_on_spawn__seatNo
  query(vehicle) <| $ [es] (vehicle_with_passenger__playerEid : EntityId)
    let playerEid = vehicle_with_passenger__playerEid
    sendEventImmediate(playerEid, [[CmdUseVehicleOnSpawn vehicle=vehicle, seatOrderNo=seatNo, squad=INVALID_ENTITY_ID, possessed=eid]])
