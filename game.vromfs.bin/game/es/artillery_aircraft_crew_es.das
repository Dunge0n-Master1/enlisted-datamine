require ecs
require app
require game.es.events
require game.events_game

[es(tag=server, on_disappear, REQUIRE=requested_aircraft)]
def aircraft_with_ai_crew_on_disappear(evt : Event;
                                       vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId)
      destroyEntity(seat__ownerEid)

[es(tag=server, after=create_vehicle_seats, on_appear)]
def aircraft_with_ai_crew_on_appear(evt : Event;
                                    eid : EntityId;
                                    team : int;
                                    vehicle_seats__seatEids : EidList;
                                    item__name : string;
                                    ai_aircraft_crew__soldier_template : string)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__component : int;
                              var seat__ownerEid : EntityId&)
      var soldierTemplate = ai_aircraft_crew__soldier_template
      if seat__component == int(ecs_hash("isDriver"))
        soldierTemplate += "+ai_aircraft_crew_pilot"

      let soldierEid = createEntity(soldierTemplate) <| $(var init : ComponentsInitializer)
        set(init, "team", team)
        set(init, "isAlive", true)
        set(init, "isInVehicle", true)
        set(init, "human_anim__vehicleSelected", eid)
        set(init, "vehicle__lastEid", eid)
        set(init, "vehicle__lastTime", get_sync_time())
        set(init, "killLogName", item__name)
        set(init, "", uint(seat__component), true)

      seat__ownerEid  = soldierEid

[es(tag=server, REQUIRE=ai_aircraft)]
def on_ai_aircraft_died(evt : EventEntityDied;
                        vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId)
      sendEvent(seat__ownerEid, [[CmdKill offender=evt.offender, damageType=uint16(evt.damageType)]])

[es(tag=server, REQUIRE=aiAircraftCrewPilot)]
def on_ai_aircraft_crew_pilot_died(evt : EventEntityDied;
                                   human_anim__vehicleSelected : EntityId)
  query(human_anim__vehicleSelected) <| $ [es] (var isAlive : bool&;
                                                var lastOffender : EntityId&)
    isAlive = false
    lastOffender = evt.offender