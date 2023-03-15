require ecs
require ecs.common
require app
require game.es.events
require game.es.spawn_soldier_common
require common_shooter.es.vehicle.vehicle_offender_common
require game.events_game
require game.utils.team
require DagorSystem
require EnlistedPlane

[es(tag=server, on_disappear, REQUIRE=requested_aircraft, before=vehicle_seats_kick_from_destroyed)]
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

      let baseTemplateName = split_template(soldierTemplate)[0]
      let tpl = getTemplateByName(baseTemplateName)
      let soldierEid = createEntity(soldierTemplate) <| $(var init : ComponentsInitializer)
        if tpl == null || !init_soldier_tpl_deps(*tpl, /*out*/ init)
          logerr("Can't create a list of entities for instantiation for '{soldierTemplate}' in aircraft")

        set(init, "team", team)
        set(init, "isAlive", true)
        set(init, "isInVehicle", true)
        set(init, "human_anim__vehicleSelected", eid)
        set(init, "vehicle__lastEid", eid)
        set(init, "vehicle__lastTime", get_sync_time())
        set(init, "killLogName", item__name)
        set(init, "", uint(seat__component), true)
        set(init, "human_vehicle__occupiedSeatEid", seatEid)

      seat__ownerEid  = soldierEid

[es(tag=server, REQUIRE=ai_aircraft)]
def on_ai_aircraft_died(evt : EventEntityDied;
                        vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__ownerEid : EntityId)
      sendEvent(seat__ownerEid, [[CmdKill offender=evt.offender, damageType=uint16(evt.damageType), gunPropsId=evt.gunPropsId, shellId=evt.shellId]])

[es(tag=server, REQUIRE=aiAircraftCrewPilot)]
def on_ai_aircraft_crew_pilot_died(evt : EventEntityDied;
                                   human_anim__vehicleSelected : EntityId)
  query(human_anim__vehicleSelected) <| $ [es] (team : int = TEAM_UNASSIGNED;
                                                var isAlive : bool&;
                                                var lastOffender : EntityId&;
                                                var last_offender__gunPropsId : int&;
                                                var last_offender__shellId : int&)
    isAlive = false
    try_set_last_vehicle_offender(evt.offender, evt.gunPropsId, evt.shellId, team, lastOffender, last_offender__gunPropsId, last_offender__shellId)

[es(tag=server, REQUIRE=ai_aircraft, REQUIRE_NOT=deadEntity)]
def kill_ai_aircraft_that_cannot_fly_normally(evt : CmdPostPhysUpdate;
                                              plane_net_phys : PlaneActor;
                                              var isAlive : bool&)
  if isAlive && plane_net_phys.phys.isReadyToDie
    isAlive = false
