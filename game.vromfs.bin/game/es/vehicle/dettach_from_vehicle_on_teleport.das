require ecs
require EnlistedNet
require game.es.events
require game.events_game
require game.es.vehicle.vehicle_events

// Teleportation is not possible for a soldier inside a vehicle
// So, kick the hero off the vehicle
[es(tag=netClient, REQUIRE=hero, on_event=EventOnEntityTeleported)]
def dettach_from_vehicle_on_teleport(evt : Event;
                                     eid : EntityId;
                                     var isInVehicle : bool&;
                                     var isInVehicleHidden : bool&;
                                     var human_anim__vehicleSelected : EntityId&;
                                     var isDriver : bool&;
                                     var isGunner : bool&;
                                     var isPassenger : bool&)
  isInVehicle = false
  isInVehicleHidden = false
  isDriver = false
  isGunner = false
  isPassenger = false

  if human_anim__vehicleSelected != INVALID_ENTITY_ID
    send_net_event(human_anim__vehicleSelected, [[RequestKickFromVehicle requester=eid]])
    sendEvent(eid, [[GainVehicleVelocity vehicleEid=human_anim__vehicleSelected]])
    human_anim__vehicleSelected = INVALID_ENTITY_ID

[es(tag=server, on_event=EventOnEntityTeleported, REQUIRE_NOT=aiAircraftCrewSoldier)]
def dettach_from_vehicle_on_teleport_server(evt : Event; eid : EntityId; human_anim__vehicleSelected : EntityId)
  sendEventImmediate(human_anim__vehicleSelected, [[CmdKickFromVehicle eid=eid]])