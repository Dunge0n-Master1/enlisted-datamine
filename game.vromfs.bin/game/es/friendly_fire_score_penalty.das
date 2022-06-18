require ecs
require app
require game.utils.team
require game.es.vehicle.vehicle_events
require enlisted.events_enlisted
require enlisted.game.es.offender_cache_common
require enlisted.game.es.enlisted_squad_common
require game.es.events
require game.events_game
require common_shooter.events_common_shooter
require EnlistedDm

def is_offender_player_in_vehicle(player_eid : EntityId; vehicle_seats__seatEids : EidList)
  var found = false
  for seatEid in vehicle_seats__seatEids
    query(seatEid) <| $ [es] (seat__isPlayer : bool; seat__playerEid : EntityId)
      found = seat__isPlayer && seat__playerEid == player_eid
    if found
      break
  return found

def is_valid_friendly_offender(victim_eid, offender_eid : EntityId; offender_info : CachedSoldier; victim_team : int; victim_owner_player : EntityId)
  if victim_eid == offender_eid || !is_valid_cache_soldier(offender_info) || offender_info.player == victim_owner_player
    return false
  var offenderTeam = TEAM_UNASSIGNED
  query(offender_info.player) <| $ [es] (team : int)
    offenderTeam = team
  return is_teams_friendly(offenderTeam, victim_team)

def on_friendly_fire(victim_eid : EntityId;
                     offender_eid : EntityId;
                     offender_info : CachedSoldier;
                     victim_team : int;
                     victim_owner_player : EntityId;
                     gun_props_id : int;
                     friendly_fire__penaltyCooldown : float;
                     var friendly_fire__lastPenaltyTime : Object&)
  if is_valid_friendly_offender(victim_eid, offender_eid, offender_info, victim_team, victim_owner_player)
    let time = get_sync_time()
    let offenderKey = "{offender_eid}"
    let lastPenaltyTime = get_float(friendly_fire__lastPenaltyTime, offenderKey) ?? 0.0
    if time - lastPenaltyTime > friendly_fire__penaltyCooldown
      friendly_fire__lastPenaltyTime |> set(offenderKey, time)
      sendEvent(victim_eid, [[OnFriendlyFire offender=offender_eid, gunPropsId=gun_props_id]])


[es(tag=server, REQUIRE_NOT=deadEntity)]
def check_friendly_fire_on_part_damage(evt : EventOnPartDamaged;
                                       eid : EntityId;
                                       team : int;
                                       ownedBySquad : EntityId;
                                       vehicle_seats__seatEids : EidList;
                                       friendly_fire__damageThreshold : float = 0.0;
                                       friendly_fire__penaltyCooldown : float;
                                       var friendly_fire__lastPenaltyTime : Object&)
  let offender_info = get_offender_from_cache(evt.hitData.offender)
  let isOffenderInVehicle = is_offender_player_in_vehicle(offender_info.player, vehicle_seats__seatEids)
  if !isOffenderInVehicle && evt.damage > friendly_fire__damageThreshold
    on_friendly_fire(eid, evt.hitData.offender, offender_info, team, get_squad_owner(ownedBySquad),
                     int(evt.hitData.gunPropsId),
                     friendly_fire__penaltyCooldown, friendly_fire__lastPenaltyTime)

def should_apply_penalty_for_damage_type(damage_type)
  return damage_type == DamageType DM_PROJECTILE || damage_type == DamageType DM_BACKSTAB || damage_type == DamageType DM_MELEE

[es(tag=server)]  // broadcast
def check_friendly_fire_on_human_hit(evt : EventOnEntityHit)
  if !should_apply_penalty_for_damage_type(evt.damageDesc.damageType)
    return
  query(evt.victim) <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (team : int;
                                                                      squad_member__playerEid : EntityId;
                                                                      friendly_fire__penaltyCooldown : float;
                                                                      var friendly_fire__lastPenaltyTime : Object&)
    let offender_info = get_offender_from_cache(evt.offender)
    on_friendly_fire(evt.victim, evt.offender, offender_info, team, squad_member__playerEid,
                     int(evt.damageDesc.gunPropsId),
                     friendly_fire__penaltyCooldown, friendly_fire__lastPenaltyTime)

[es(tag=server, REQUIRE=human, REQUIRE_NOT=deadEntity)]
def check_friendly_fire_on_human_hit_with_flamethrower(evt : OnFlamethrowerFriendlyFire;
                                                       eid : EntityId;
                                                       team : int;
                                                       squad_member__playerEid : EntityId;
                                                       friendly_fire__penaltyCooldown : float;
                                                       var friendly_fire__lastPenaltyTime : Object&)
  let offender_info = get_offender_from_cache(evt.offender)
  on_friendly_fire(eid, evt.offender, offender_info, team, squad_member__playerEid,
                   evt.gunPropsId, friendly_fire__penaltyCooldown, friendly_fire__lastPenaltyTime)

[es(tag=server, REQUIRE=human)]
def check_friendly_fire_human_kill(evt : EventEntityDied; eid : EntityId; team : int; squad_member__playerEid : EntityId)
  let offender_info = get_offender_from_cache(evt.offender)
  if is_valid_friendly_offender(eid, evt.offender, offender_info, team, squad_member__playerEid)
    sendEvent(eid, [[OnTeamKill offender=evt.offender, gunPropsId=evt.gunPropsId]])

[es(tag=server)]
def check_friendly_fire_vehicle_kill(evt : EventEntityDied; eid : EntityId; team : int; ownedBySquad : EntityId; vehicle_seats__seatEids : EidList)
  let offender_info = get_offender_from_cache(evt.offender)
  let isOffenderInVehicle = is_offender_player_in_vehicle(offender_info.player, vehicle_seats__seatEids)
  if !isOffenderInVehicle && is_valid_friendly_offender(eid, evt.offender, offender_info, team, get_squad_owner(ownedBySquad))
    sendEvent(eid, [[OnTeamKill offender=evt.offender, gunPropsId=evt.gunPropsId]])
