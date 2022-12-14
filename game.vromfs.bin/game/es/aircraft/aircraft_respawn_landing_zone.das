require ecs
require ecs.common
require ecs.safe
require math.base
require DagorMath
require Plane
require EnlistedPlane
require EnlistedActor
require EnlistedDm
require dm
require game.utils.team
require game.es.events
require EnlistedNet
require enlisted.events_enlisted
require game.es.vehicle.vehicle_events
require game.es.aircraft.aircraft_common
require common_shooter.events_common_shooter
require game.es.vehicle.vehicle_seats_common
require vehicle
require app
require CollRes

let ALL_ENGINES = -1

def setup_engines(var phys : FlightModel&)
  phys |> flight_model_forcePower(0.0, ALL_ENGINES)
  phys |> flight_model_setPowerControlAll(0.0)
  phys |> flight_model_stopEngines()
  phys |> flight_model_forceLeftAndRightBrakeControls(1.0)

  assume propulsion = *phys.EI
  propulsion |> propulsion_setEnginesStops()
  propulsion |> propulsion_setEnginesOmega(0.0)
  propulsion |> propulsion_setEnginesTurboChargerOmega(0.0)

  phys |> flight_model_setVelocityRough(float3())

def setup_on_water(var plane_net_phys : PlaneActor&)
  assume phys = plane_net_phys.phys
  setup_engines(phys)
  phys |> flight_model_forceFlaps(0.0)
  phys |> flight_model_forceAirBrake(0.0)
  phys |> flight_model_forceGear(0.0)

def setup_on_ground(var plane_net_phys : PlaneActor&)
  assume phys = plane_net_phys.phys
  setup_engines(phys)
  phys |> flight_model_forceFlaps(0.0)
  phys |> flight_model_forceAirBrake(0.0)
  phys |> flight_model_forceGear(1.0)

def respawn_plane(plane_eid : EntityId; transform : float3x4; is_water_spawn : bool)
  var tm : float3x4
  tm := transform
  orthonormalize(tm)

  send_net_event(plane_eid, [[CmdResupplyVehicle]])
  send_net_event(plane_eid, [[CmdResetupVehicle setupOnWater=is_water_spawn, tm=tm, speed=0.0]])

def is_valid_respawn(subtype : string; valid_subtypes : StringList const?)
  return valid_subtypes == null || length(*valid_subtypes) == 0 || find_index(*valid_subtypes, subtype) >= 0

def is_alive_player_driver(seat_eid : EntityId)
  var res = false
  query(seat_eid) <| $ [es] (seat__availableControls : VehicleControlsState; seat__isOwnerAlive : bool; seat__isPlayer : bool)
    res = seat__availableControls.canControlVehicle && seat__isOwnerAlive && seat__isPlayer
  return res

def has_alive_player_driver(seats : EidList)
  return (find_index_if(each(seats)) <| $(seatEid : EntityId) => is_alive_player_driver(seatEid)) >= 0

[es(tag=server, REQUIRE_NOT=deadEntity)]
def plane_landing_need_repair_check_on_part_damaged_es(evt : EventOnPartDamaged; var plane_landing__canUseRespawn : bool&)
  if int(evt.hpFixed) == 0
    plane_landing__canUseRespawn = true

[es(tag=server, REQUIRE_NOT=deadEntity)]
def plane_landing_need_repair_check_on_volumetric_damaged_es(evt : EventOnVolumetricDamage; var plane_landing__canUseRespawn : bool&)
  for part in evt.damagedParts
    if ((part as Object)?.hpFixed ?? -1) == 0
      plane_landing__canUseRespawn = true
      break

[es(tag=server, REQUIRE_NOT=deadEntity)]
def plane_landing_need_repair_check_on_meta_part_damage_es(evt : EventOnMetaPartDamage; var plane_landing__canUseRespawn : bool&)
  if evt.damage > 0.0
    plane_landing__canUseRespawn = true

[es(tag=server, REQUIRE_NOT=deadEntity, on_event=EventCutPart)]
def plane_landing_need_repair_check_on_collision(evt : Event; var plane_landing__canUseRespawn : bool&)
  plane_landing__canUseRespawn = true

[es(tag=server)]
def plane_landing_check_engines(evt : CmdPostPhysUpdate; plane_net_phys : PlaneActor; var plane_landing__canUseRespawn : bool&)
  plane_landing__canUseRespawn ||= plane_net_phys.phys.isAnyInoperable

[es(tag=server)]
def plane_landing_reset_repair_required_at_height(evt : CmdPostPhysUpdate;
                                                  plane_net_phys : PlaneActor;
                                                  plane_landing__resetCanRepairAtHeight : float = 10.0;
                                                  var plane_landing__canUseRespawn : bool&)
  plane_landing__canUseRespawn ||= !plane_net_phys.phys.Gears.onSurface && plane_net_phys.phys.currentAlt > plane_landing__resetCanRepairAtHeight

[es(tag=server, REQUIRE_NOT=deadEntity)]
def plane_landing_check_if_landed(evt : CmdPostPhysUpdate;
                                  eid aka plane_eid : EntityId;
                                  team aka plane_team : int;
                                  transform aka plane_transform : float3x4;
                                  canUseRespawnbaseSubtypes : StringList const?;
                                  plane_landing__canUseRespawn : bool;
                                  plane_net_phys : PlaneActor;
                                  vehicle_seats__seatEids : EidList;
                                  var plane_landing__repairTime : float&;
                                  var plane_landing__repairAtTime : float&;
                                  var plane_landing__respawnInProgress : bool&;
                                  var plane_landing__timeAfterLanding : float&)
  let isOnWater = plane_net_phys.phys.Gears.onWater
  let isOnGround = plane_net_phys.phys.Gears.onGround

  if plane_landing__respawnInProgress
    return

  if !plane_landing__canUseRespawn || (!isOnGround && !isOnWater) || !has_alive_player_driver(vehicle_seats__seatEids)
    plane_landing__timeAfterLanding = 0.0
    plane_landing__repairAtTime = -1.0
    return

  let found = find_query() <| $ [es(REQUIRE=landingZone)] (transform aka zone_transform : float3x4;
                                                           respawnbaseSubtype : string;
                                                           sphere_zone__radius : float;
                                                           landing_zone__maxSpeed : float = 10.0;
                                                           landing_zone__respawnAfterTime : float = 10.0;
                                                           landing_zone__isWater : Tag const?;
                                                           team : int = TEAM_UNASSIGNED)
    let isSpeedLow = plane_net_phys.phys.speed < landing_zone__maxSpeed
    let isFriendly = (team == TEAM_UNASSIGNED || is_teams_friendly(team, plane_team))
    let isWaterRespawn = landing_zone__isWater != null
    if (isSpeedLow &&
        isFriendly &&
        (isWaterRespawn ? isOnWater : isOnGround) &&
        distance_sq(plane_transform[3], zone_transform[3]) < square(sphere_zone__radius) &&
        is_valid_respawn(respawnbaseSubtype, canUseRespawnbaseSubtypes))
      plane_landing__timeAfterLanding += evt.dt
      if plane_landing__repairAtTime < 0.0 || plane_landing__repairTime != landing_zone__respawnAfterTime
        plane_landing__repairTime = landing_zone__respawnAfterTime
        plane_landing__repairAtTime = get_sync_time() + max(0., landing_zone__respawnAfterTime - plane_landing__timeAfterLanding)
      if plane_landing__timeAfterLanding > landing_zone__respawnAfterTime
        plane_landing__timeAfterLanding = 0.0
        plane_landing__respawnInProgress = true
        respawn_plane(plane_eid, zone_transform, isWaterRespawn)
      return true
    return false

  if !found
    plane_landing__timeAfterLanding = 0.0
    plane_landing__repairAtTime = -1.0

[es]
def plane_resetup_teleport(evt : CmdResetupVehicle;
                           eid : EntityId;
                           collres : CollisionResource;
                           var plane_net_phys : PlaneActor&;
                           var damage_model : DamageModel&;
                           var fire_protection : FireProtection&;
                           var meta_parts_state : MetaPartsState&)
  repair_plane(eid, plane_net_phys, damage_model, fire_protection, meta_parts_state)
  teleport_plane(evt.tm, collres, plane_net_phys)

[es(tag=input, after=plane_resetup_teleport)]
def plane_landing_reset_look_dir(evt : CmdResetupVehicle;
                                 var camera__lookDir : float3&;
                                 var flight_angles : float2&;
                                 var plane_input : PlaneInput&)
  let dir = normalize_default(evt.tm[0], float3(1, 0, 0))
  camera__lookDir = dir
  var tmpBank = 0.0
  let dirQuat = dir_to_quat(dir)
  quat_to_euler(dirQuat, flight_angles.x, flight_angles.y, tmpBank)
  plane_input.mouseAimAng = flight_angles
  plane_input.resetLookDirection = true

[es(tag=input)]
def plane_langing_resetup_input(evt : CmdResetupVehicle; var plane_input : PlaneInput; var flaps_position : int&)
  plane_input.currFlapsPosIndex = uint8(0)
  flaps_position = length(plane_input.flapsIndices) > 0 ? int(plane_input.flapsIndices[0]) : 0

[es(tag=server, on_event=CmdResetupVehicle)]
def plane_landing_set_status_after_repair(evt : Event;
                                          var plane_landing__canUseRespawn : bool&;
                                          var plane_landing__respawnInProgress : bool&)
  plane_landing__canUseRespawn = false
  plane_landing__respawnInProgress = false

[es(tag=gameClient, on_event=CmdResetupVehicle)]
def plane_landing_set_respawn_time(evt : Event; var plane_landing__respawnedAtTime : float&)
  plane_landing__respawnedAtTime = get_sync_time()

[es]
def plane_landing_resetup_after_repair(evt : CmdResetupVehicle; var plane_net_phys : PlaneActor&)
  if evt.setupOnWater
    setup_on_water(plane_net_phys)
  else
    setup_on_ground(plane_net_phys)

def update_zones_available_status(plane_team : int; canUseRespawnbaseSubtypes : StringList const?)
  query() <| $ [es] (respawnbaseSubtype : string; team : int = TEAM_UNASSIGNED; var landing_zone__isAvailable : bool&)
    let isFriendly = (team == TEAM_UNASSIGNED || is_teams_friendly(team, plane_team))
    landing_zone__isAvailable = isFriendly && is_valid_respawn(respawnbaseSubtype, canUseRespawnbaseSubtypes)

[es(tag=ui, REQUIRE=(airplane, vehicleWithWatched), on_appear)]
def aircraft_respawn_landing_zone_is_available_on_watched_plane_appear(evt : Event;
                                                                       team : int;
                                                                       canUseRespawnbaseSubtypes : StringList const?)
  update_zones_available_status(team, canUseRespawnbaseSubtypes)

[es(tag=ui, REQUIRE=(airplane, vehicleWithWatched), on_disappear)]
def aircraft_respawn_landing_zone_is_available_on_watched_plane_disapper(evt : Event; eid aka disappeared_eid : EntityId)
  let foundAnother = find_query() <| $ [es(REQUIRE=vehicleWithWatched)] (eid : EntityId;
                                                                         team : int;
                                                                         canUseRespawnbaseSubtypes : StringList const?)
    if eid == disappeared_eid
      return false
    update_zones_available_status(team, canUseRespawnbaseSubtypes)
    return true
  if !foundAnother
    query() <| $ [es] (var landing_zone__isAvailable : bool&)
      landing_zone__isAvailable = false
