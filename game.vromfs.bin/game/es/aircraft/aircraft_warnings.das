require ecs
require math
require math.base
require DagorMath
require Plane
require DngPlane
require GamePhys
require enlisted.events_enlisted

[es(tag=ui, no_order, REQUIRE=vehicleWithWatched)]
def plane_critical_overload_warning(info : ParallelUpdateFrameDelayed;
                                    plane_net_phys : PlaneActor;
                                    plane__maxSpeedIncrease : float = 15.0f;
                                    plane__speedIncreaseMultiplier : float = 3.0f;
                                    plane__flapsWarningThreshold : float = 0.05f;
                                    plane__flapsPresenceThreshold : float = 0.01f;
                                    plane__machWarningThreshold : float = -0.025f;
                                    var plane__overloadCritical : bool&;
                                    var plane__flapsCritical : bool&)
  assume phys = plane_net_phys.phys

  plane__flapsCritical = false
  plane__overloadCritical = false

  let forward = float3(1f, 0f, 0f)
  let forwardDir = phys.visualLocation.O.quat * forward
  let speedIncrease = min(dot(float3(phys.currentState.acceleration), forwardDir) * plane__speedIncreaseMultiplier, plane__maxSpeedIncrease)

  if phys.bHasFlapsControl && phys.currentState.squareFlapsLRel + phys.currentState.squareFlapsRRel > plane__flapsPresenceThreshold
    let flapsDestructionIndSpeedDiff = (phys.appliedCT.flaps > plane__flapsWarningThreshold ?
                                        phys.indSpeed - phys.flapsDestructionIndSpeeds |> interpolate_tab_float_interpolate(phys.appliedCT.flaps) :
                                        -abs(speedIncrease) - 1.0f);
    plane__flapsCritical = max(flapsDestructionIndSpeedDiff, flapsDestructionIndSpeedDiff + speedIncrease) > 0.0f

  let machOverspeed = phys.Mach - phys.wingProps.machNeverExceed
  plane__overloadCritical = machOverspeed > plane__machWarningThreshold
  if !plane__overloadCritical
    let indSpeedAllowed = phys.wingProps.velNeverExceed
    let wingOverspeed = phys.indSpeed - indSpeedAllowed
    plane__overloadCritical = max(wingOverspeed, wingOverspeed + speedIncrease) > 0.0f
