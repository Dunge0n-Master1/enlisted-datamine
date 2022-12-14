require ecs
require ecs.common
require ecs.soa_template
require enlisted.events_enlisted
require EnlistedPlane
require Plane


[soa_template]
struct AircraftStateEngine
  aircraft_state_engine__damageStage : uint8
  aircraft_state_engine__hasFuel : bool
  aircraft_state_engine__hasOil : bool
  aircraft_state_engine__hasWater : bool


[soa_es, es(tag=server, on_appear)]
def aircraft_state_on_appear(evt : Event;
                             plane_net_phys : PlaneActor;
                             var aircraftStateEngine : AircraftStateEngine_SOA&)
  resize(aircraftStateEngine, plane_net_phys.phys.EI.numEngines)


[soa_es, es(tag=server, no_order)]
def aircraft_state_update(info : UpdateStageInfoAct;
                          aircraft_state_engine__damagedTreshold : float;
                          aircraft_state_engine__destroyedTreshold : float;
                          var aircraft__isCapableOfTakeOff : bool&;
                          var aircraftStateEngine : AircraftStateEngine_SOA&;
                          var plane_net_phys : PlaneActor&)
  aircraft__isCapableOfTakeOff = plane_net_phys.phys.isCapableOfTakeOff
  for i, engineState in range(plane_net_phys.phys.EI.numEngines), aircraftStateEngine
    propulsion_get_engine(*plane_net_phys.phys.EI, i) <| $(engine)
      let engineDamage = 1.0 - engine.readyness

      if engineDamage < aircraft_state_engine__damagedTreshold
        engineState.aircraft_state_engine__damageStage = uint8(0)
      elif engineDamage < aircraft_state_engine__destroyedTreshold
        engineState.aircraft_state_engine__damageStage = uint8(1)
      else
        engineState.aircraft_state_engine__damageStage = uint8(2)

      engineState.aircraft_state_engine__hasFuel = engine_hasFuel(engine, plane_net_phys.phys)
      engineState.aircraft_state_engine__hasOil = engine.oilLevel > 0.01
      engineState.aircraft_state_engine__hasWater = engine.waterLevel > 0.01
