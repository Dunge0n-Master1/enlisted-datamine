module artillery_radio_common shared
require ecs
require app
require HumanPhys
require math.base
require game.es.battle_area_common
require DagorSystem

def has_radioman_squadmate_for_order(squad_eid : EntityId; leader_eid : EntityId)
  return find_query() <| $ [es] (eid : ecs::EntityId;
                                 squad_member__squad : ecs::EntityId;
                                 human_weap__radioEid : EntityId;
                                 isAlive : bool;
                                 isDowned : bool = false)
    return squad_eid == squad_member__squad && eid != leader_eid && isAlive && !isDowned && !!human_weap__radioEid

def test_artillery_in_battle_area(pos_start, pos_end : float3; team : int) : bool
  let dist2 = distance_sq(pos_start, pos_end)
  if dist2 < VERY_SMALL_NUMBER
    return has_active_human_battle_area_at(pos_start, team)
  else
    return dist2 < 1e10 && is_segment_in_active_human_battle_area(pos_start, pos_end, team)

def is_artillery_on_cooldown(playerEid : EntityId)
  return get_sync_time() < get_float(playerEid, "artillery__availableAtTime") ?? 0.0

def is_aircraft_request(playerEid : EntityId; typeIndex : int)
  var isAircraftRequest = false
  query(playerEid) <| $ [es] (artillery__templates : StringList)
    let artilleryTemplateName = string(artillery__templates[typeIndex])
    let artilleryTemplate = getTemplateByName(artilleryTemplateName)
    if artilleryTemplate == null
      logerr("Artillery template '{artilleryTemplateName}' not exist!")
      return

    isAircraftRequest = templateHasComponent(*artilleryTemplate, "aircraft_request")

  return isAircraftRequest

def is_aircraft_request_on_cooldown(team : int)
  let curTime = get_sync_time()
  let isInCooldown = find_query() <| $ [es] (team__id : int; team__aircraftRequestAvailableAtTime : float)
    return team__id == team && curTime < team__aircraftRequestAvailableAtTime

  return isInCooldown

def is_artillery_max_limit_reached_by_group(team : int; group : int)
  var available = false
  find_query() <| $ [es] (team__id : int; artillery_limit__max : IntList; artillery_limit__current : IntList)
    if team__id == team
      available = artillery_limit__current[group] < artillery_limit__max[group]
      return true
    return false
  return !available

def is_artillery_max_limit_reached(team : int)
  var available = false
  find_query() <| $ [es] (team__id : int; artillery_limit__max : IntList; artillery_limit__current : IntList)
    if team__id == team
      for current, max in artillery_limit__current, artillery_limit__max
        available ||= current < max
      return true
    return false
  return !available

def artillery_change_limit(team : int; val : int; group : int = 0)
  find_query() <| $ [es] (team__id : int; var artillery_limit__current : IntList&)
    if team__id == team
      artillery_limit__current[group] += val
      return true
    return false

def can_order_artillery_strike(eid, squad_eid : EntityId)
  var res = false
  query(eid) <| $ [es] (isAlive : bool; isDowned : bool; possessedByPlr : EntityId)
    res = isAlive && !isDowned && has_radioman_squadmate_for_order(squad_eid, eid) && !is_artillery_on_cooldown(possessedByPlr)
  return res
