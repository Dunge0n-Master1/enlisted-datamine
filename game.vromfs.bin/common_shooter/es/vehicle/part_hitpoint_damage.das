require ecs
require math.base
require dm
require DngDm
require game.es.vehicle.vehicle_seats_common
require game.es.vehicle.vehicle_events
require game.utils.team
require DagorMath
require DagorSystem
require common_shooter.events_common_shooter

def convert_damage_type(damage_type_id : int)
  if damage_type_id == find_damage_type_id_by_name("explosion")
    return DamageType DM_EXPLOSION
  elif damage_type_id == find_damage_type_id_by_name("fire")
    return DamageType DM_FIRE
  return DamageType DM_PROJECTILE

def transfer_damage_to_hitpoints_by_dm_part(damaged_part_id : int;
                                            damage_type : DamageType;
                                            hp_fixed : uint16;
                                            prev_hp_fixed : uint16;
                                            offender : EntityId;
                                            vehicle_seats__seatEids : EidList;
                                            vehicle_seats_receive_damage_from_dm_part : IntList;
                                            burn_increment : float;
                                            hit_pos : float3 = float3();
                                            hit_dir : float3 = float3();
                                            shell_id : int = -1;
                                            gun_props_id : int = -1)
  for seatNo, seatEid in iter_range(vehicle_seats__seatEids), vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    if damaged_part_id == vehicle_seats_receive_damage_from_dm_part[seatNo] && !!ownerEid
      let maxHp = get_float(ownerEid, "hitpoints__maxHp") ?? -1.0
      if maxHp <= 0.0
        continue
      let damage = maxHp * (int(hp_fixed) == 0 ? 1.0 : rel_hp_fixed_to_float(uint16(max(0, int(prev_hp_fixed) - int(hp_fixed)))))
      let dd = DamageDesc(damage_type, damage, hit_pos, hit_dir, float3(), shell_id, gun_props_id, -1, 0.0)
      apply_damage(ownerEid, offender, dd)
      if damage_type == DamageType DM_FIRE
        query(ownerEid) <| $ [es] (var burning__isBurning : bool&;
                                   var burning__offender : EntityId&;
                                   var burning__offenderGunPropsId : int&;
                                   var burning__offenderShellId : int&;
                                   var burning__tickIncrement : float&)
          burning__isBurning = true
          burning__offender = offender
          burning__offenderGunPropsId = gun_props_id
          burning__offenderShellId = shell_id
          burning__tickIncrement = max(burning__tickIncrement, burn_increment)
      break

def transfer_damage_to_hitpoints(part_id : int; damage : float; offender : EntityId; eid : EntityId; damage_model : DamageModel;
                                 hit_pos : float3 = float3(); hit_dir : float3 = float3(); shell_id : int = -1; gun_props_id : int = -1)
  let dd = DamageDesc(DamageType DM_PROJECTILE, damage, hit_pos, hit_dir, float3(), shell_id, gun_props_id, get_collision_node_id(damage_model.dmData, part_id), 0.0)
  apply_damage(eid, offender, dd)


[es(tag=server, on_event=EventOnSeatOwnersChanged)]
def transfer_hitpoints_to_part_hp_on_seat_change(evt : Event;
                                                 vehicle_seats__seatEids : EidList;
                                                 vehicle_seats_receive_damage_from_dm_part : IntList;
                                                 var damage_model : DamageModel&)
  for seatNo, seatEid in iter_range(vehicle_seats__seatEids), vehicle_seats__seatEids
    let partId = vehicle_seats_receive_damage_from_dm_part[seatNo]
    if !is_valid_part_id(damage_model, partId)
      continue
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    query(ownerEid) <| $ [es] (hitpoints__maxHp : float; hitpoints__hp : float)
      damage_model.dmData.parts[partId].state = DamagePartState DP_STATE_NORMAL
      damage_model.dmData.parts[partId].relHpFixed = rel_hp_float_to_fixed_ceil(safediv(max(hitpoints__hp, 0.0), hitpoints__maxHp))

[es(tag=server, track=hitpoints__hp, after=transfer_damage_to_hitpoints_by_dm_part_es, before=xray_effect_update_es)]
def transfer_hitpoints_to_part_hp_on_hp_change(evt : Event;
                                               eid : EntityId;
                                               human_anim__vehicleSelected : EntityId;
                                               hitpoints__hp : float;
                                               hitpoints__maxHp : float)
  query(human_anim__vehicleSelected) <| $ [es] (vehicle_seats__seatEids : EidList;
                                                vehicle_seats_receive_damage_from_dm_part : IntList;
                                                var damage_model : DamageModel&)
    let seatNo = find_seat_with_owner(eid, vehicle_seats__seatEids)
    if seatNo < 0
      return
    let partId = vehicle_seats_receive_damage_from_dm_part[seatNo]
    if !is_valid_part_id(damage_model, partId)
      return
    damage_model.dmData.parts[partId].state = DamagePartState DP_STATE_NORMAL
    damage_model.dmData.parts[partId].relHpFixed = rel_hp_float_to_fixed_ceil(safediv(max(hitpoints__hp, 0.0), hitpoints__maxHp))

[es(tag=server)]
def transfer_damage_to_hitpoints_by_dm_part_on_part_damage(evt : EventOnPartDamaged;
                                                           vehicle_seats__seatEids : EidList;
                                                           vehicle_seats_receive_damage_from_dm_part : IntList;
                                                           fire_damage__burnIncrement : float = 0.0;
                                                           eid : EntityId;
                                                           team : int = TEAM_UNASSIGNED)
  let damageTypeId = evt.damageTypeId
  let hpFixed = evt.hpFixed
  let prevHpFixed = evt.prevHpFixed
  assume hitData = evt.hitData

  let offenderVehicle = get_Eid(hitData.offender, "human_anim__vehicleSelected") ?? INVALID_ENTITY_ID
  let selfInflicted = eid == offenderVehicle
  let offenderTeam = get_int(hitData.offender, "team") ?? TEAM_UNASSIGNED
  if !selfInflicted && !is_friendly_fire_allowed() && is_teams_friendly(team, offenderTeam)
    return

  transfer_damage_to_hitpoints_by_dm_part(evt.partId, convert_damage_type(damageTypeId), hpFixed, prevHpFixed, hitData.offender,
    vehicle_seats__seatEids, vehicle_seats_receive_damage_from_dm_part, fire_damage__burnIncrement, hitData.pos, hitData.dir, int(hitData.shellId), int(hitData.gunPropsId))

[es(tag=server)]
def transfer_damage_to_hitpoints_by_dm_part_on_volumetric_damage(evt : EventOnVolumetricDamage;
                                                                 vehicle_seats__seatEids : EidList;
                                                                 vehicle_seats_receive_damage_from_dm_part : IntList;
                                                                 fire_damage__burnIncrement : float = 0.0;
                                                                 fire_damage__gunPropsId : int = -1;
                                                                 fire_damage__shellId : int = -1;
                                                                 eid : EntityId;
                                                                 team : int = TEAM_UNASSIGNED)
  let damageTypeId = evt.damageTypeId

  let offenderVehicle = get_Eid(evt.offender, "human_anim__vehicleSelected") ?? INVALID_ENTITY_ID
  let selfInflicted = eid == offenderVehicle
  let offenderTeam = get_int(evt.offender, "team") ?? TEAM_UNASSIGNED
  if !selfInflicted && !is_friendly_fire_allowed() && is_teams_friendly(team, offenderTeam)
    return

  for item in evt.damagedParts
    let part = get_ecs_object(item)
    if part == null
      logerr("Received EventOnVolumetricDamage with null in damagedParts")
      continue
    let partId = get_int(part, "partId")
    let hpFixed = get_uint16(part, "hpFixed")
    let prevHpFixed = get_uint16(part, "prevHpFixed")
    if partId == null || hpFixed == null || prevHpFixed == null
      logerr("Received EventOnVolumetricDamage with broken object in damagedParts (partId: {partId}, hpFixed: {hpFixed}, prevHpFixed: {prevHpFixed})")
      continue

    let damageType = convert_damage_type(damageTypeId)
    var gunPropsId = -1
    var shellId = -1
    if damageType == DamageType DM_FIRE
      gunPropsId = fire_damage__gunPropsId
      shellId = fire_damage__shellId
    transfer_damage_to_hitpoints_by_dm_part(*partId, damageType, *hpFixed, *prevHpFixed, evt.offender,
      vehicle_seats__seatEids, vehicle_seats_receive_damage_from_dm_part, fire_damage__burnIncrement,
      /*hit_pos*/float3(), /*hit_dir*/float3(), shellId, gunPropsId)

[es(tag=server, after=(transfer_damage_to_hitpoints_by_dm_part_on_part_damage, transfer_damage_to_hitpoints_by_dm_part_on_volumetric_damage))]
def crew_hp_after_damage_es(evt : EventOnPartDamaged;
                            vehicle_seats__seatEids : EidList;
                            var crew_hp_after_hit : IntList&)
  for seatNo, seatEid in iter_range(vehicle_seats__seatEids), vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    query(ownerEid) <| $ [es] (hitpoints__maxHp : float; hitpoints__hp : float)
      crew_hp_after_hit[seatNo] = int(rel_hp_float_to_fixed_ceil(safediv(max(hitpoints__hp, 0.0), hitpoints__maxHp)))

[es(tag=server, REQUIRE=hitpoints)]
def transfer_damage_to_hitpoints_on_part_damage(evt : EventOnPartDamaged;
                                                eid : EntityId;
                                                damage_model : DamageModel;
                                                isInVehicleHidden : bool;
                                                team : int = TEAM_UNASSIGNED)
  if isInVehicleHidden
    return
  let partId = evt.partId
  let damage = evt.damage
  assume hitData = evt.hitData
  let offenderTeam = get_int(hitData.offender, "team") ?? TEAM_UNASSIGNED
  if !is_friendly_fire_allowed() && hitData.offender != eid && is_teams_friendly(team, offenderTeam)
    return

  transfer_damage_to_hitpoints(partId, damage, hitData.offender, eid, damage_model, hitData.pos, hitData.dir, int(hitData.shellId), int(hitData.gunPropsId))

[es(tag=server, REQUIRE=hitpoints)]
def transfer_damage_to_hitpoints_on_volumetric_damage(evt : EventOnVolumetricDamage;
                                                      eid : EntityId;
                                                      damage_model : DamageModel;
                                                      isInVehicleHidden : bool;
                                                      team : int = TEAM_UNASSIGNED)
  if isInVehicleHidden
    return

  let offenderTeam = get_int(evt.offender, "team") ?? TEAM_UNASSIGNED
  if !is_friendly_fire_allowed() && evt.offender != eid && is_teams_friendly(team, offenderTeam)
    return

  for item in evt.damagedParts
    let part = get_ecs_object(item)
    if part == null
      logerr("Received EventOnVolumetricDamage with null in damagedParts")
      continue
    let partId = get_int(part, "partId")
    let damage = get_float(part, "damage")
    if partId == null || damage == null
      logerr("Received EventOnVolumetricDamage with broken object in damagedParts (partId: {partId}, damage: {damage})")
      continue

    transfer_damage_to_hitpoints(*partId, *damage, evt.offender, eid, damage_model);