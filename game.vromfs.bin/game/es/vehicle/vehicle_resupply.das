require ecs
require ecs.safe
require Gun
require ecs.common
require DngNet
require app
require enlisted.events_enlisted
require game.utils.team
require DngWeapon
require math
require math.base
require DngPlane
require GamePhys
require strings

[es(tag=server, on_event=CmdResupplyVehicle)]
def resupply_vehicle_on_server(evt : Event; turret_control__gunEids : EidList)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (gun__maxAmmo : int;
                             var gun : Gun;
                             var gun__ammo : int&;
                             var gun__totalAmmo : int&;
                             currentBulletId : int = 0;
                             turret__isCut : bool = false;
                             gun__shellsAmmo : Array;
                             var gun__ammo_by_shell : IntList&;
                             gun__ammoToRessuply : int = -1)
      if turret__isCut
        return
      for ammoByShell, shellsAmmo in gun__ammo_by_shell, gun__shellsAmmo
        let shellsAmmoCount = get_int(shellsAmmo) ?? 0
        ammoByShell = gun__ammoToRessuply > 0 ? min(shellsAmmoCount, ammoByShell + gun__ammoToRessuply) : shellsAmmoCount
      let currentTypeAmmo = gun__ammo_by_shell?[currentBulletId] ?? gun__maxAmmo
      if gun__ammoToRessuply > 0
        let ammoBeforeRessuply = gun__ammo
        gun__ammo = min(gun__maxAmmo, gun__ammo + gun__ammoToRessuply)
        let ressupliedAmmo = gun__ammo - ammoBeforeRessuply
        let needToAddToTotalAmmo = gun__ammoToRessuply - ressupliedAmmo
        gun__totalAmmo = max(0, min(currentTypeAmmo - gun__ammo, gun__totalAmmo + needToAddToTotalAmmo))
      else
        gun__ammo = min(currentTypeAmmo, gun__maxAmmo)
        gun__totalAmmo = max(0, currentTypeAmmo - gun__ammo)
      gun.curState.loaded = (gun__ammo > 0)

[es(tag=netClient, on_event=CmdResupplyVehicle)]
def resupply_vehicle_on_client(evt : Event; turret_control__gunEids : EidList)
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (gun__maxAmmo : int;
                             var gun__ammo : int&;
                             currentBulletId : int = 0;
                             turret__isCut : bool = false;
                             gun__shellsAmmo : Array;
                             gun__ammoToRessuply : int = -1)
      if currentBulletId < length(gun__shellsAmmo) && currentBulletId >= 0 && !turret__isCut
        let ammoByShellId = get_int(gun__shellsAmmo[currentBulletId]) ?? 0
        if gun__ammoToRessuply > 0
          gun__ammo = min(gun__maxAmmo, gun__ammo + gun__ammoToRessuply)
        else
          gun__ammo = min(ammoByShellId, gun__maxAmmo)


def resupply_fuel(vehicleEid : EntityId)
  query(vehicleEid) <| $ [es(REQUIRE=airplane)] (var plane_net_phys : PlaneActor&)
    assume mass = plane_net_phys.phys.M
    for i in range(0, MAX_FUEL_SYSTEMS)
      let amount = getFuelMassMax(mass, i)
      if amount > 0.f
        mass |> setFuel(amount, i, /*limit*/true)

def need_resupply(turret_control__gunEids : EidList)
  var needResupply = false
  for gunEid in turret_control__gunEids
    query(gunEid) <| $ [es] (gun__shellsAmmo : Array; gun__ammo_by_shell : IntList)
      for ammoByShell, shellsAmmo in gun__ammo_by_shell, gun__shellsAmmo
        if ammoByShell < get_int(shellsAmmo) ?? 0
          needResupply = true
          return
    if needResupply
      break
  return needResupply

def is_applied_for_zone(zone_pos : float3; zone_radius_sq : float; zone_team : int; visitor_pos : float3; visitor_team : int; zone_subtype : string; vehicle_subtype : string)
  return ((empty(zone_subtype) || zone_subtype == vehicle_subtype) &&
          (zone_team == TEAM_UNASSIGNED || zone_team == visitor_team) &&
          distance_sq(zone_pos, visitor_pos) < zone_radius_sq)

def zone_timer(at_time : float; resupply_zone__updateInterval : float; var resupply_zone__nextUpdateAtTime : float&)
  if at_time < resupply_zone__nextUpdateAtTime
    return false
  resupply_zone__nextUpdateAtTime = at_time + resupply_zone__updateInterval
  return true

def apply_zone(at_time : float;
               zone_pos : float3;
               zone_radius_sq : float;
               zone_team : int;
               resupply_zone__cooldown : float;
               resupply_zone__duration : float;
               visitor_eid : EntityId;
               visitor_pos : float3;
               visitor_team : int;
               turret_control__gunEids : EidList;
               resupplyFuel : bool;
               zone_subtype : string;
               vehicle_subtype : string;
               var resupplyAtTime : float&;
               var resupplyStarted : bool&;
               var resupplyPassengersAtTime : float&;
               var resupplyPassengersStarted : bool&)
  if !is_applied_for_zone(zone_pos, zone_radius_sq, zone_team, visitor_pos, visitor_team, zone_subtype, vehicle_subtype)
    return
  if resupplyFuel
    resupply_fuel(visitor_eid)
  let cooldownEndTime = resupplyAtTime > 0. ? resupplyAtTime + resupply_zone__cooldown : 0.
  if !resupplyStarted && at_time > cooldownEndTime && need_resupply(turret_control__gunEids)
    resupplyAtTime = at_time + resupply_zone__duration
    resupplyStarted = true
  if !resupplyPassengersStarted && at_time > cooldownEndTime
    resupplyPassengersAtTime = at_time + resupply_zone__duration
    resupplyPassengersStarted = true


[es(no_order, tag=server, REQUIRE=planeResupply)]
def resupply_in_air_zone_timer(info : UpdateStageInfoAct;
                               active : bool;
                               transform : float3x4;
                               resupply_zone__team : int;
                               sphere_zone__radius : float;
                               resupply_zone__cooldown : float;
                               resupply_zone__duration : float;
                               resupply_zone__updateInterval : float;
                               resupply_zone__resupplyFuel : bool;
                               resupply_zone__type : string = "";
                               var resupply_zone__nextUpdateAtTime : float&)
  if !active || !zone_timer(info.curTime, resupply_zone__updateInterval, resupply_zone__nextUpdateAtTime)
    return
  let zonePos = transform[3]
  let zoneRadiusSq = square(sphere_zone__radius)
  query() <| $ [es(REQUIRE=airplane, REQUIRE_NOT=disableVehicleResupply)] (eid : EntityId;
                                                                           team : int;
                                                                           transform : float3x4;
                                                                           turret_control__gunEids : EidList;
                                                                           vehicle_resupply__type : string = "";
                                                                           var resupplyAtTime : float&;
                                                                           var resupplyStarted : bool&;
                                                                           var resupplyPassengersAtTime : float&;
                                                                           var resupplyPassengersStarted : bool&)
    apply_zone(info.curTime, zonePos, zoneRadiusSq, resupply_zone__team, resupply_zone__cooldown, resupply_zone__duration, eid, transform[3],
               team, turret_control__gunEids, resupply_zone__resupplyFuel, resupply_zone__type, vehicle_resupply__type,
               resupplyAtTime, resupplyStarted, resupplyPassengersAtTime, resupplyPassengersStarted)

[es(no_order, tag=server, REQUIRE=groundVehicleResupply)]
def resupply_on_ground_zone_timer(info : UpdateStageInfoAct;
                                  active : bool;
                                  transform : float3x4;
                                  resupply_zone__team : int;
                                  sphere_zone__radius : float;
                                  resupply_zone__cooldown : float;
                                  resupply_zone__duration : float;
                                  resupply_zone__updateInterval : float;
                                  resupply_zone__resupplyFuel : bool;
                                  resupply_zone__type : string = "";
                                  var resupply_zone__nextUpdateAtTime : float&)
  if !active || !zone_timer(info.curTime, resupply_zone__updateInterval, resupply_zone__nextUpdateAtTime)
    return
  let zonePos = transform[3]
  let zoneRadiusSq = square(sphere_zone__radius)
  query() <| $ [es(REQUIRE=vehicle, REQUIRE_NOT=(disableVehicleResupply, airplane))] (eid : EntityId;
                                                                                      team : int;
                                                                                      transform : float3x4;
                                                                                      turret_control__gunEids : EidList;
                                                                                      resupply__cooldownOverride : float = -1.f;
                                                                                      vehicle_resupply__type : string = "";
                                                                                      var resupplyAtTime : float&;
                                                                                      var resupplyStarted : bool&;
                                                                                      var resupplyPassengersAtTime : float&;
                                                                                      var resupplyPassengersStarted : bool&)
    let coolDownTime = resupply__cooldownOverride > 0.f ? resupply__cooldownOverride : resupply_zone__cooldown
    apply_zone(info.curTime, zonePos, zoneRadiusSq, resupply_zone__team, coolDownTime, resupply_zone__duration, eid, transform[3],
               team, turret_control__gunEids, resupply_zone__resupplyFuel, resupply_zone__type, vehicle_resupply__type,
               resupplyAtTime, resupplyStarted, resupplyPassengersAtTime, resupplyPassengersStarted)

[es(no_order, tag=server)]
def resupply_vehicle_timer(info : UpdateStageInfoAct;
                           eid : EntityId;
                           resupplyAtTime : float;
                           resupplyPassengersAtTime : float;
                           var resupplyStarted : bool&;
                           var resupplyPassengersStarted : bool&)
  if resupplyStarted && info.curTime > resupplyAtTime
    resupplyStarted = false
    send_net_event(eid, [[CmdResupplyVehicle]])
  if resupplyPassengersStarted && info.curTime > resupplyPassengersAtTime
    resupplyPassengersStarted = false
    sendEvent(eid, [[CmdResupplyPassengers]])
