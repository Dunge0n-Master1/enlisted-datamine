require ecs
require ecs.safe
require ecs.common
require strings
require app
require game.utils.team
require game.es.vehicle.vehicle_events
require game.es.awards_common
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

def should_apply_penalty_for_damage_type(damage_type : int)
  return damage_type == int(DamageType DM_PROJECTILE) || damage_type == int(DamageType DM_BACKSTAB) || damage_type == int(DamageType DM_MELEE)

[es(tag=server)]  // broadcast
def check_friendly_fire_on_human_hit(evt : EventOnEntityHit)
  if !should_apply_penalty_for_damage_type(evt.damageType)
    return
  query(evt.victim) <| $ [es(REQUIRE=human, REQUIRE_NOT=deadEntity)] (team : int;
                                                                      squad_member__playerEid : EntityId;
                                                                      friendly_fire__penaltyCooldown : float;
                                                                      var friendly_fire__lastPenaltyTime : Object&)
    let offender_info = get_offender_from_cache(evt.offender)
    on_friendly_fire(evt.victim, evt.offender, offender_info, team, squad_member__playerEid,
                     evt.gunPropsId,
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

def get_squad_owner_player(squad_eid : EntityId)
  return get_Eid(squad_eid, "squad__ownerPlayer") ?? INVALID_ENTITY_ID

def write_forgivable_stat(var obj : Object#; offender : CachedSoldier; stat : string)
  obj |> set("player", offender.player)
  obj |> set("guid", offender.guid)
  obj |> set("stat", stat)
  obj |> set("amount", -1.0)

def set_forgivable_stats(offender : CachedSoldier; stat : string; victim_player : EntityId)
  query(victim_player) <| $ [es] (var friendly_fire__forgivableStats : Object&)
    let offenderKey = "{offender.player}"
    var oldStats = friendly_fire__forgivableStats[offenderKey] ?as Array
    if oldStats != null
      push_to_array(*oldStats) <| $(var obj : Object#)
        obj |> write_forgivable_stat(offender, stat)
    else
      push_to_object(friendly_fire__forgivableStats, offenderKey) <| $(var arr : Array#)
        push_to_array(arr) <| $(var obj : Object#)
          obj |> write_forgivable_stat(offender, stat)

def add_soldier_stat(offender : CachedSoldier; stat : string; victim_player : EntityId; victim_name : string; gun_props_id : int)
  query() <| $ [es(REQUIRE=gamemodeFriendlyFire)] ()
    send_award_stat(offender.player, offender.guid, stat)
    set_forgivable_stats(offender, stat, victim_player)
    let offenderPlayerName = get_string(offender.player, "name", "")
    let victimPlayerName = get_string(victim_player, "name", "")
    let gunTplName = get_gun_template_by_props_id(gun_props_id)
    let gunName = split_template(gunTplName)[0]
    print("[FriendlyFire] {offenderPlayerName}[{offender.player}] got penalty {stat} with weapon: {gunName}. Victim: {victim_name} of player {victimPlayerName}[{victim_player}]")

def increase_same_player_kill_count(offender_player, victim_player : EntityId)
  var res = 1
  query(offender_player) <| $ [es] (var friendly_fire__playerKillCount : Object&)
    let victimKey = "{victim_player}"
    res = (friendly_fire__playerKillCount[victimKey] ?? 0) + 1
    friendly_fire__playerKillCount |> set(victimKey, res)
  return res

[es(tag=server, REQUIRE=human)]
def apply_team_kill_penalty_human(evt : OnTeamKill;
                                  [[shared_comp]] friendly_fire__samePlayerKillStats : StringList;
                                  guid : string = "";
                                  squad_member__playerEid : EntityId = INVALID_ENTITY_ID;
                                  possessedByPlr : EntityId = INVALID_ENTITY_ID)
  let offender = get_offender_from_cache(evt.offender)
  let victimPlayer = squad_member__playerEid
  add_soldier_stat(offender, "friendlyKills", victimPlayer, guid, evt.gunPropsId)
  if !possessedByPlr
    return
  let samePlayerKills = increase_same_player_kill_count(offender.player, victimPlayer)
  let statIndex = clamp(samePlayerKills - 1, 0, length(friendly_fire__samePlayerKillStats) - 1)
  let samePlayerKillStat = string(friendly_fire__samePlayerKillStats[statIndex])
  if !empty(samePlayerKillStat)
    add_soldier_stat(offender, samePlayerKillStat, victimPlayer, guid, evt.gunPropsId)

[es(tag=server, REQUIRE=airplane)]
def apply_team_kill_penalty_plane(evt : OnTeamKill; killLogName : string = ""; ownedBySquad : EntityId = INVALID_ENTITY_ID)
  add_soldier_stat(get_offender_from_cache(evt.offender), "friendlyPlaneKills", get_squad_owner_player(ownedBySquad), killLogName, evt.gunPropsId)

[es(tag=server, REQUIRE=isTank)]
def apply_team_kill_penalty_tank(evt : OnTeamKill; killLogName : string = ""; ownedBySquad : EntityId = INVALID_ENTITY_ID)
  add_soldier_stat(get_offender_from_cache(evt.offender), "friendlyTankKills", get_squad_owner_player(ownedBySquad), killLogName, evt.gunPropsId)

[es(tag=server, REQUIRE=human)]
def apply_friendly_fire_penalty_on_human_hit(evt : OnFriendlyFire; guid : string = ""; squad_member__playerEid : EntityId = INVALID_ENTITY_ID)
  add_soldier_stat(get_offender_from_cache(evt.offender), "friendlyHits", squad_member__playerEid, guid, evt.gunPropsId)

[es(tag=server, REQUIRE=airplane)]
def apply_friendly_fire_penalty_on_plane_damage(evt : OnFriendlyFire; killLogName : string = ""; ownedBySquad : EntityId = INVALID_ENTITY_ID)
  add_soldier_stat(get_offender_from_cache(evt.offender), "friendlyPlaneHits", get_squad_owner_player(ownedBySquad), killLogName, evt.gunPropsId)

[es(tag=server, REQUIRE=isTank)]
def apply_friendly_fire_penalty_on_tank_damage(evt : OnFriendlyFire; killLogName : string = ""; ownedBySquad : EntityId = INVALID_ENTITY_ID)
  add_soldier_stat(get_offender_from_cache(evt.offender), "friendlyTankHits", get_squad_owner_player(ownedBySquad), killLogName, evt.gunPropsId)

[es(tag=server, track=scoring_player__friendlyFirePenalty)]
def log_current_friendly_fire_penalty(evt : Event; eid : EntityId; squads__spawnCount : int; name : string; scoring_player__friendlyFirePenalty : int)
  print("[FriendlyFire] {name}[{eid}] current penalty {scoring_player__friendlyFirePenalty}. Spawn count: {squads__spawnCount}")
