require ecs
require vehicle
require game.es.vehicle.vehicle_seats_common

[es(on_appear, on_event=EventOnSeatOwnersChanged)]
def apply_vehicle_driver_skills(evt : Event;
                                eid : EntityId;
                                vehicle_net_phys__brakingTau : float;
                                vehicle_net_phys__gearChangeTime : float;
                                vehicle_net_phys__drivingSpeedThreshold : float;
                                var vehicle_net_phys : VehiclePhysActor)
  var brakingTau            = vehicle_net_phys__brakingTau
  var gearChangeTime        = vehicle_net_phys__gearChangeTime
  var drivingSpeedThreshold = vehicle_net_phys__drivingSpeedThreshold

  query(get_vehicle_driver(eid)) <| $ [es(REQUIRE_NOT=deadEntity)] (driver_skills__brakingTauMult : float;
                                                                    driver_skills__gearChangeTimeMult : float;
                                                                    driver_skills__drivingSpeedThresholdMult : float)
    brakingTau            *= driver_skills__brakingTauMult
    gearChangeTime        *= driver_skills__gearChangeTimeMult
    drivingSpeedThreshold *= driver_skills__drivingSpeedThresholdMult

  vehicle_net_phys.phys.crewBrakingTau            = brakingTau
  vehicle_net_phys.phys.crewGearChangeTime        = gearChangeTime
  vehicle_net_phys.phys.crewDrivingSpeedThreshold = drivingSpeedThreshold