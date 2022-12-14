require game.es.events
require game.events_game
require common_shooter.events_common_shooter
require common_shooter.es.hitpoints_common
require game.es.vehicle.vehicle_events
require game.es.vehicle.vehicle_seats_common
require enlisted.game.es.offender_cache_common
require game.utils.team
require app
require dm
require EnlistedDm
require vehicle
require BallisticsProps
require DagorSystem
require ecs

def is_vehicle_has_crew(vehicle_seats; exclude_eid = INVALID_ENTITY_ID)
  for seatEid in vehicle_seats
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    if ownerEid != exclude_eid && ownerEid != ecs::INVALID_ENTITY_ID && (get_bool(ownerEid, "isAlive") ?? false)
      return true
  return false

[es(tag=server, REQUIRE_NOT=deadEntity, REQUIRE=destroyOnDamageWithoutCrew, after=vehicle_damage_part_last_offender_weapon)]
def check_damaged_vehicle_without_crew(evt : EventOnPartDamaged;
                                       isExploded : bool;
                                       vehicle_seats__seatEids : EidList;
                                       eid : EntityId;
                                       ownedBySquad : EntityId;
                                       transform : float3x4;
                                       damage_model : DamageModel;
                                       lastOffender : EntityId;
                                       last_offender__gunPropsId : int;
                                       last_offender__shellId : int;
                                       damage_model__explosionDamageType : int;
                                       destroy_without_crew__minCaliberToDestroyOnDamage : float;
                                       destroyTimerCheckDistance : float = 10.f;
                                       var vehicle__isDestroyedWithoutCrew : bool&)
  let shellId = int(evt.hitData.shellId)
  if (shellId < 0 || isExploded ||
      vehicle__isDestroyedWithoutCrew ||
      is_vehicle_has_crew(vehicle_seats__seatEids) ||
      vehicle_has_owner_around(transform[3], ownedBySquad, destroyTimerCheckDistance))
    return
  projectile_get_props(shellId) <| $(ballisticsProps : ProjectileProps)
    let isLargeCaliber = ballisticsProps.caliber > destroy_without_crew__minCaliberToDestroyOnDamage
    let isExplosion = damage_model__explosionDamageType >= 0 && evt.damageTypeId == damage_model__explosionDamageType
    assume parts = damage_model.dmData.parts
    let isInnerPart = uint(evt.partId) < uint(length(parts)) && (parts[evt.partId] |> damagePart_getProps).isInner

    if isInnerPart && (isLargeCaliber || isExplosion)
      vehicle__isDestroyedWithoutCrew = true
      sendEvent(eid, [[CmdExplosionFatal offender=lastOffender, gunPropsId=last_offender__gunPropsId, shellId=last_offender__shellId]])

[es(tag=server, REQUIRE=damage_model)]
def vehicle_fatal_fire_kill_es(evtData : EventFireFatal;
                               vehicle_seats__seatEids : EidList)
  for seatEid in vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    sendEvent(ownerEid, [[CmdKill offender=evtData.offender, damageType=uint16(int(DamageType DM_FIRE)), gunPropsId=evtData.gunPropsId, shellId=evtData.shellId]])

[es(tag=server)]
def vehicle_crew_dead_es(evtData : EventEntityDied; eid : EntityId; human_anim__vehicleSelected : EntityId)
  let crewOwner = eid
  ecs::query(human_anim__vehicleSelected) <| $ [es] (eid : EntityId;
                                                     vehicle_seats__seatEids : EidList;
                                                     isExploded : bool;
                                                     var isAlive : bool&;
                                                     var lastOffender : EntityId&;
                                                     var last_offender__shellId : int&;
                                                     var last_offender__gunPropsId : int&;
                                                     destroyIfNoCrewLeft : bool = false;
                                                     fire_damage__isFatal : bool = false)
    if fire_damage__isFatal
      return
    let hasCrew = is_vehicle_has_crew(vehicle_seats__seatEids, crewOwner)
    if !hasCrew
      let isSuicide = evtData.victim == evtData.offender
      let hasLastOffender = !!lastOffender
      if (!isSuicide || !hasLastOffender) && lastOffender != evtData.offender
        lastOffender = evtData.offender
        last_offender__shellId = evtData.shellId
        last_offender__gunPropsId = evtData.gunPropsId
      if !isExploded && destroyIfNoCrewLeft
        sendEvent(eid, [[CmdExplosionFatal offender=lastOffender, gunPropsId=last_offender__gunPropsId, shellId=last_offender__shellId]])
      if has(eid, "deadIfNoCrewLeft")
        isAlive = false

[es(on_event=EventOnSeatOwnersChanged)]
def vehicle_seats_dm_parts_es(evt : Event;
                              vehicle_seats__seatEids : EidList;
                              vehicle_seats_receive_damage_from_dm_part : ecs::IntList;
                              var damage_model : DamageModel)
  for seatNo, seatEid in iter_range(vehicle_seats__seatEids), vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    if vehicle_seats_receive_damage_from_dm_part[seatNo] >= 0
      let enabled = (ownerEid != ecs::INVALID_ENTITY_ID) || (get_bool(ownerEid, "isAlive") ?? false)
      damage_model.dmData.parts[vehicle_seats_receive_damage_from_dm_part[seatNo]].enabled = enabled

[es(tag=server, REQUIRE_NOT=deadEntity, REQUIRE=(vehicle_seats__transferVehicleOffenderToSeats))]
def vehicle_seats_transfer_offender_on_damage(evt : EventOnPartDamaged;
                                              vehicle_seats__seatEids : EidList;
                                              damage_model__explosionDamageType : int = -1;
                                              damage_model__fireDamageType : int = -1)
  let offenderEid = evt.hitData.offender
  let offenderPlayer = get_Eid(offenderEid, "possessedByPlr") ?? INVALID_ENTITY_ID
  let cachedOffender = get_offender_from_cache(offenderEid)
  let offenderSquadPlayer = cachedOffender.player
  let offenderTeam = get_int(offenderSquadPlayer, "team") ?? TEAM_UNASSIGNED
  if offenderTeam == TEAM_UNASSIGNED
    return
  for seatEid in vehicle_seats__seatEids
    let ownerEid = get_Eid(seatEid, "seat__ownerEid") ?? INVALID_ENTITY_ID
    var damageType = -1
    if evt.damageTypeId == damage_model__explosionDamageType && damage_model__explosionDamageType >= 0
      damageType = int(DamageType DM_EXPLOSION)
    elif evt.damageTypeId == damage_model__fireDamageType && damage_model__fireDamageType >= 0
      damageType = int(DamageType DM_FIRE)
    ownerEid |> try_set_last_offender(offenderEid, offenderTeam, offenderPlayer, offenderSquadPlayer,
                                      damageType, int(evt.hitData.gunPropsId), int(evt.hitData.shellId), -1, false)

[es(tag=server, before=request_vehicle_seat_es, REQUIRE=vehicle_seats__transferVehicleOffenderToSeats)]
def vehicle_seats_reset_last_offender_timer_on_exit(evt : CmdKickFromVehicle; vehicle_seats__seatEids : EidList)
  let kickedEntity = evt.eid
  if find_seat_with_owner(kickedEntity, vehicle_seats__seatEids) < 0
    return // sanity check, entity is in vehicle
  query(kickedEntity) <| $ [es] (var hitpoints__lastOffenderTime : float&)
    hitpoints__lastOffenderTime = get_sync_time()
