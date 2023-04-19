require ecs
require Plane
require DngPlane
require ecs.soa_template
require enlisted.events_enlisted

let zeroKelvinInCelsium = -273.15f

[soa_template]
struct PlaneViewEngine
  plane_view_engine__engineWarnLevel : int
  plane_view_engine__waterWarnLevel : int
  plane_view_engine__oilWarnLevel : int
  plane_view_engine__isWaterLeaking : bool
  plane_view_engine__isOilLeaking : bool
  plane_view_engine__isWaterLow : bool
  plane_view_engine__isOilLow : bool
  plane_view_engine__isEngineDead : bool
  plane_view_engine__waterTemp : int
  plane_view_engine__oilTemp : int
  plane_view_engine__headTemp : int

[soa_es, es(tag=ui, on_appear, REQUIRE=vehicleWithWatched)]
def aircraft_hud_engines_state_init(event : Event;
                                    plane_net_phys : PlaneActor;
                                    var planeViewEngine : PlaneViewEngine_SOA&)
  assume propulsion = plane_net_phys.phys.EI
  if propulsion != null
    let engineCount = (*propulsion).numEngines
    planeViewEngine |> resize(engineCount)


def get_warn_level(time_to_die : float; points : IntList)
  var res = 0
  for i, warnTime in iter_range(points), points
    if time_to_die < float(warnTime)
      res = i + 1
  return res

[soa_es, es(tag=ui, no_order, REQUIRE=vehicleWithWatched)]
def aircraft_hud_engine_state(info : ParallelUpdateFrameDelayed;
                              plane_view_engine__warnPoints : IntList;
                              plane_view_engine__updateInterval : float;
                              var plane_view_engine__nextUpdate : float&;
                              var plane_net_phys : PlaneActor&;
                              var planeViewEngine : PlaneViewEngine_SOA&)
  if info.curTime < plane_view_engine__nextUpdate
    return
  plane_view_engine__nextUpdate = info.curTime + plane_view_engine__updateInterval
  assume propulsion = plane_net_phys.phys.EI
  if propulsion != null
    let numEngines = (*propulsion).numEngines
    for i, view in range(numEngines), planeViewEngine
      (*propulsion) |> propulsion_get_engine(i) <| $(engine)

        view.plane_view_engine__isWaterLeaking = int(engine.waterLeak) > 0
        view.plane_view_engine__isOilLeaking = int(engine.oilLeak) > 0

        view.plane_view_engine__isWaterLow = engine.waterLevel < 0.1
        view.plane_view_engine__isOilLow = engine.oilLevel < 0.1

        view.plane_view_engine__waterWarnLevel = max(
          (view.plane_view_engine__isWaterLeaking || view.plane_view_engine__isWaterLow) ? 1 : 0,
          get_warn_level(engine |> engine_getWaterOverheatTimeToDie(0.), plane_view_engine__warnPoints)
        )

        view.plane_view_engine__oilWarnLevel = max(
          (view.plane_view_engine__isOilLeaking || view.plane_view_engine__isOilLow) ? 1 : 0,
          get_warn_level(engine |> engine_getOilOverheatTimeToDie(0.), plane_view_engine__warnPoints)
        )

        view.plane_view_engine__isEngineDead = engine.stage == (EStage E_STAGE_DEAD)
        view.plane_view_engine__engineWarnLevel = max(
          view.plane_view_engine__isEngineDead ? 2 : 0,
          get_warn_level(engine |> engine_getHeadOverheatTimeToDie(0.), plane_view_engine__warnPoints)
        )

        if view.plane_view_engine__waterWarnLevel > 0
          view.plane_view_engine__waterTemp = int(engine.waterTemp + zeroKelvinInCelsium + 0.5)
        if view.plane_view_engine__oilWarnLevel > 0
          view.plane_view_engine__oilTemp = int(engine.oilTemp + zeroKelvinInCelsium + 0.5)
        if view.plane_view_engine__engineWarnLevel > 0
          view.plane_view_engine__headTemp = int(engine.headTemp + zeroKelvinInCelsium + 0.5)


[es(tag=ui, after=plane_phys_es, REQUIRE=vehicleWithWatched)]
def plane_minimal_view_air_brakes(info : ParallelUpdateFrameDelayed;
                                  plane_net_phys : PlaneActor;
                                  var plane_view__hasAirBrakes : bool&;
                                  var plane_view__isAirBrakesActive : bool&)
  assume phys = plane_net_phys.phys
  plane_view__hasAirBrakes = phys.bHasAirBrakeControl;
  plane_view__isAirBrakesActive = phys.AirBrakeControl > 0.5
