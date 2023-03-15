require game.es.events
require game.es.vehicle.vehicle_events
require common_shooter.events_common_shooter
require dm
require vehicle
require ecs
require danetlibs.native_dasevents.main.native_events


def is_in_array(value : int; arr : ecs::IntList) : bool
  for item in arr
    if item == value
      return true
  return false

def process_damage_to_part_impl(partType : string; isDestroyed : bool; vehicleEid : ecs::EntityId)
  sendEvent(vehicleEid, [[EventOnVehiclePartTypeDamaged partType=partType, isDestroyed=isDestroyed]])

def process_damage_to_part(partId : int;
                           hpFixed : int;
                           prevHpFixed : int;
                           barrelAndBreechDmList;
                           horDriveDmList;
                           verDriveDmList;
                           dm_phys_parts__enginePartIds : ecs::IntList;
                           dm_phys_parts__transmissionPartIds : ecs::IntList;
                           dm_phys_parts__tracksPartIds : ecs::IntList;
                           vehicleEid : ecs::EntityId)
  if partId == -1
    return
  let isDestroyed = hpFixed == 0
  if ((isDestroyed && prevHpFixed == 0) || (uint(hpFixed) > uint(MAX_REL_HP_FIXED) / 2u) ||
      (!isDestroyed && uint(prevHpFixed) < uint(MAX_REL_HP_FIXED) / 2u))
    return

  if find_index(barrelAndBreechDmList, partId) >= 0
    process_damage_to_part_impl("turret", isDestroyed, vehicleEid)
  elif find_index(horDriveDmList, partId) >= 0
    process_damage_to_part_impl("turretHorDrive", isDestroyed, vehicleEid)
  elif find_index(verDriveDmList, partId) >= 0
    process_damage_to_part_impl("turretVerDrive", isDestroyed, vehicleEid)
  elif is_in_array(partId, dm_phys_parts__enginePartIds)
    process_damage_to_part_impl("engine", isDestroyed, vehicleEid)
  elif is_in_array(partId, dm_phys_parts__transmissionPartIds)
    process_damage_to_part_impl("transmission", isDestroyed, vehicleEid)
  elif is_in_array(partId, dm_phys_parts__tracksPartIds)
    process_damage_to_part_impl("tracks", isDestroyed, vehicleEid)

[es(tag=server, REQUIRE=damage_model)]
def vehicle_damage_part_type_damaged_es(evt : EventOnVehiclePartTypeDamaged;
                                        vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__isPlayer : bool; seat__ownerEid : EntityId)
      if !seat__isPlayer || has(seat__ownerEid, "deadEntity")
        return
      let msgLocId = evt.isDestroyed ? "{evt.partType}DamageDestroyed" : "{evt.partType}Damage"
      sendEvent(seat__ownerEid, [[CmdHeroLogEvent event="vehicle_part_damaged", text="vehicle/{msgLocId}", ttl=5]])

def gather_part_ids(gunEids; var horDriveDmList, verDriveDmList, barrelAndBreechDmList : array<int>)
  for turretEid in gunEids
    query(turretEid) <| $ [es(REQUIRE=resolvedTurret)] (turret_drive_dm_part__horDriveDm, turret_drive_dm_part__verDriveDm, turret_dm_part__barrelDm, turret_dm_part__breechDm : int)
      push(horDriveDmList, turret_drive_dm_part__horDriveDm)
      push(verDriveDmList, turret_drive_dm_part__verDriveDm)
      push(barrelAndBreechDmList, turret_dm_part__barrelDm)
      push(barrelAndBreechDmList, turret_dm_part__breechDm)

[es(tag=server, REQUIRE=damage_model)]
def vehicle_volumetric_damage_es(evt : EventOnVolumetricDamage;
                                 eid : ecs::EntityId;
                                 turret_control__gunEids : EidList;
                                 dm_phys_parts__enginePartIds : ecs::IntList;
                                 dm_phys_parts__transmissionPartIds : ecs::IntList;
                                 dm_phys_parts__tracksPartIds : ecs::IntList;
                                 fire_damage__isBurn : bool)
  if fire_damage__isBurn
    return

  var horDriveDmList : array<int>
  var verDriveDmList : array<int>
  var barrelAndBreechDmList : array<int>
  gather_part_ids(turret_control__gunEids, horDriveDmList, verDriveDmList, barrelAndBreechDmList)

  for partIt in evt.damagedParts
    let part = get_ecs_object(partIt)
    let partId = get_int(part, "partId") ?? -1
    let hpFixed = get_int(part, "hpFixed") ?? 0
    let prevHpFixed = get_int(part, "prevHpFixed") ?? 0
    process_damage_to_part(
      partId, hpFixed, prevHpFixed,
      barrelAndBreechDmList,
      horDriveDmList,
      verDriveDmList,
      dm_phys_parts__enginePartIds,
      dm_phys_parts__transmissionPartIds,
      dm_phys_parts__tracksPartIds,
      eid)

[es(tag=server, REQUIRE=damage_model)]
def vehicle_damage_part_events_es(evt : EventOnPartDamaged;
                                  eid : ecs::EntityId;
                                  turret_control__gunEids : EidList;
                                  dm_phys_parts__enginePartIds : ecs::IntList;
                                  dm_phys_parts__transmissionPartIds : ecs::IntList;
                                  dm_phys_parts__tracksPartIds : ecs::IntList;
                                  fire_damage__isBurn : bool)
  if fire_damage__isBurn
    return

  var horDriveDmList : array<int>
  var verDriveDmList : array<int>
  var barrelAndBreechDmList : array<int>
  gather_part_ids(turret_control__gunEids, horDriveDmList, verDriveDmList, barrelAndBreechDmList)

  process_damage_to_part(
    evt.partId, int(evt.hpFixed), int(evt.prevHpFixed),
    barrelAndBreechDmList,
    horDriveDmList,
    verDriveDmList,
    dm_phys_parts__enginePartIds,
    dm_phys_parts__transmissionPartIds,
    dm_phys_parts__tracksPartIds,
    eid)
