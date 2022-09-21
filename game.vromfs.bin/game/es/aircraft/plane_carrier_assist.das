require ecs
require math.base
require DagorMath
require Plane
require EnlistedPlane
require EnlistedActor
require game.es.events
require game.events_game

def is_near_carrier(plane_pos : float3)
  return find_query() <| $ [es(REQUIRE=aircraft_carrier__takeOffAssistZone)] (transform aka zone_transform : float3x4; sphere_zone__radius : float)
    return distance_sq(plane_pos, zone_transform[3]) < square(sphere_zone__radius)

def on_take_off(plane_eid : EntityId; plane_net_phys : PlaneActor)
  assume phys = plane_net_phys.phys
  if phys.bHasGearControl && phys.GearControl > 0.0 && !phys.Gears.onGround && !phys.Gears.onWater
    query() <| $ [es(REQUIRE=hero, REQUIRE_NOT=deadEntity)] (human_anim__vehicleSelected : EntityId)
      if human_anim__vehicleSelected == plane_eid
        broadcastEvent([[CmdShowHint event="take_off_gear_reminder", text ="tips/take_off_gear", ttl=8.0, hotkey="Plane.ToggleGear", unique="take_off_gear_reminder"]])

[es(tag=input, REQUIRE=heroVehicle, track=plane_view__gear_position)]
def hide_plane_take_off_gear_reminder(evt : Event; plane_view__gear_position : bool)
  if !plane_view__gear_position
    broadcastEvent([[CmdShowHint event="take_off_gear_reminder", text ="", ttl=0.0, hotkey="", unique="take_off_gear_reminder"]])

[es]
def plane_carrier_assist_take_off(evt : CmdPostPhysUpdate;
                                  eid : EntityId;
                                  transform aka aircraft_transform : float3x4;
                                  plane_carrier_assist__forwardForce : float;
                                  plane_carrier_assist__windForce : float;
                                  plane_carrier_assist__fakeWindTime : float;
                                  plane_carrier_assist__requiredPowerLevel : float;
                                  plane_carrier_assist__showReminderAfterTakeOffTime : float;
                                  var plane_carrier_assist__isOnCarrier : bool&;
                                  var plane_carrier_assist__timeAfterTakeOff : float&;
                                  var plane_net_phys : PlaneActor&)
  var wind : float3
  assume propulsion = plane_net_phys.phys.EI
  let power = propulsion != null ? (*propulsion).powerOutput : 0.0
  let isPowerOn = power > plane_carrier_assist__requiredPowerLevel
  let isOnGround = plane_net_phys.phys.Gears.onGround && !plane_net_phys.phys.Gears.isWaterGear
  plane_carrier_assist__isOnCarrier = isOnGround && is_near_carrier(aircraft_transform[3])
  if plane_carrier_assist__isOnCarrier
    plane_carrier_assist__timeAfterTakeOff = 0.0
    let powerMult = cvt(power, plane_carrier_assist__requiredPowerLevel, 1.0, 0.0, 1.0)
    let localForcePos : float3
    let force = plane_carrier_assist__forwardForce * plane_net_phys.phys.M.mass * powerMult
    let localForce = float3(force, 0.0, 0.0)
    plane_net_phys.phys |> flight_model_addForceImmediately(localForcePos, localForce)
  elif plane_carrier_assist__timeAfterTakeOff >= 0.0 && plane_carrier_assist__timeAfterTakeOff < plane_carrier_assist__fakeWindTime
    plane_carrier_assist__timeAfterTakeOff += evt.dt
    if plane_carrier_assist__timeAfterTakeOff > plane_carrier_assist__showReminderAfterTakeOffTime && plane_carrier_assist__timeAfterTakeOff - evt.dt < plane_carrier_assist__showReminderAfterTakeOffTime
      on_take_off(eid, plane_net_phys)

  let isBeforeTakeOffTimeout = plane_carrier_assist__timeAfterTakeOff >= 0.0 && plane_carrier_assist__timeAfterTakeOff < plane_carrier_assist__fakeWindTime

  if isPowerOn && isBeforeTakeOffTimeout && plane_carrier_assist__fakeWindTime > 0.
    wind = -aircraft_transform[0]
    wind[1] = 0.0
    let windForce = lerp(plane_carrier_assist__windForce, 0., saturate(plane_carrier_assist__timeAfterTakeOff / plane_carrier_assist__fakeWindTime))
    wind *= windForce

  plane_net_phys.phys.VfakeWind = DPoint3(wind)
