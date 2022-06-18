require ecs
require vehicle
require math.base
require DagorMath
require GamePhys

let
  MSEC_TO_KMH = 3.6f

[es(tag=gameClient, after=net_phys_update_es, REQUIRE=heroVehicle)]
def vehicle_minimal_view(info : UpdateStageInfoAct;
                         vehicle_net_phys : VehiclePhysActor;
                         transform : float3x4;
                         var vehicle_view__gear : int&;
                         var vehicle_view__neutralGear : int&;
                         var vehicle_view__rpm : int&;
                         var vehicle_view__speed : int&;
                         var vehicle_view__cruiseControl : int&;
                         var vehicle_view__fuelPct : float&;
                         var vehicle_view__isHandBraking : bool&;
                         var vehicle_view__isAutomaticTransmission : bool&)
  assume phys = vehicle_net_phys.phys
  vehicle_view__gear = int(phys.currentState.currentGear)
  vehicle_view__neutralGear = int(phys.neutralGearIndex)

  let rpm = roundi(phys.engineRPM)
  vehicle_view__rpm = rpm - rpm % 100

  let speed = dot(float3(phys.currentState.velocity), transform[0])
  vehicle_view__speed = roundi(speed * MSEC_TO_KMH)

  vehicle_view__cruiseControl = int(phys.currentState.cruiseControl)
  vehicle_view__fuelPct = safediv(getFuelMassCurrent(phys.mass), getFuelMassMax(phys.mass)) * 100f
  vehicle_view__isHandBraking = ground_control_state_getAxisValue(phys.appliedCT, EGroundControlAxis GCA_HAND_BRAKE) > 0.5f
  vehicle_view__isAutomaticTransmission = phys.appliedCT.isTransmissionAuto