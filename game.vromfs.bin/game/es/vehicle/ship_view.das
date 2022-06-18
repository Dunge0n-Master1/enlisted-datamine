require ecs
require EnlistedShip
require math.base
require DagorMath
require GamePhys

let
  MSEC_TO_KMH = 3.6f

[es(tag=gameClient, after=net_phys_update_es, REQUIRE=heroVehicle)]
def ship_minimal_view(info : UpdateStageInfoAct;
                      ship_net_phys : ShipActor;
                      transform : float3x4;
                      var vehicle_view__rpm : int&;
                      var vehicle_view__speed : int&;
                      var vehicle_view__fuelPct : float&)
  assume phys = ship_net_phys.phys
  vehicle_view__rpm = roundi(phys.engineRPM)
  let speed = dot(float3(phys.currentState.velocity), transform[0])
  vehicle_view__speed = roundi(speed * MSEC_TO_KMH)
  vehicle_view__fuelPct = safediv(getFuelMassCurrent(phys.mass), getFuelMassMax(phys.mass)) * 100f