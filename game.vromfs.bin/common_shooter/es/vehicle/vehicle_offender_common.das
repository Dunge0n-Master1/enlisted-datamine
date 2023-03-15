module vehicle_offender_common shared

require ecs
require game.utils.team
require enlisted.game.es.offender_cache_common

def private get_team(eid : EntityId)
  return get_int(eid, "team") ?? TEAM_UNASSIGNED

def private get_offender_team(eid : EntityId)
  return get_int(eid, "team") ?? get_team(get_offender_from_cache(eid).player)

def private can_override_offender(offender_cache : CachedSoldier; last_offender : EntityId; victim_team : int)
  return (!last_offender ||
           is_teams_friendly(get_offender_team(last_offender), victim_team) ||
           (is_valid_cache_soldier(offender_cache) && !is_teams_friendly(get_team(offender_cache.player), victim_team)))

def private should_accept_new_offender(offender : EntityId; offender_cache : CachedSoldier; last_offender : EntityId; victim_team : int)
  return !!offender && can_override_offender(offender_cache, last_offender, victim_team)

def try_set_last_vehicle_offender(offender : EntityId;
                                  gun_props_id : int;
                                  shell_id : int;
                                  victim_team : int;
                                  var lastOffender : EntityId&;
                                  var last_offender__gunPropsId : int&;
                                  var last_offender__shellId : int&)
  let cachedOffender = get_offender_from_cache(offender)
  if should_accept_new_offender(offender, cachedOffender, lastOffender, victim_team)
    lastOffender = offender
    last_offender__gunPropsId = gun_props_id
    last_offender__shellId = shell_id
