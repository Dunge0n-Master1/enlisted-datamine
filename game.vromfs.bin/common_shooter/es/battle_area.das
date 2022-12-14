require app
require ecs
require ecs.common
require ecs.safe
require DagorMath
require math.base
require math.linear
require zones
require enlisted.events_enlisted
require game.events_game
require game.utils.team
require DagorSystem
require game.es.battle_area_common
require EnlistedNet
require EnlistedDm


def find_index_in_kill_list(killList : ecs::Array; visitor : EntityId)
  return find_index_if(each(killList)) <| $(elem) : bool
    let elemObj = get_ecs_object(elem)
    return elemObj != null && visitor == get_Eid(elemObj, "eid") ?? ecs::INVALID_ENTITY_ID


def is_in_next_active_battle_area(zonesIn : EidList; team : int)
  var found = false
  let curTime = get_sync_time()
  for zoneEid in zonesIn
    ecs::query(zoneEid) <| $ [es(REQUIRE=battle_area)] (battle_area__deactivatedAtTime : float = -1.0;
                                                        battle_area__timeToWarn : float = 0.0;
                                                        battle_area__team : int = TEAM_UNASSIGNED)
      if battle_area__team != TEAM_UNASSIGNED && team != battle_area__team
        return
      if battle_area__deactivatedAtTime < 0.0 || curTime < battle_area__deactivatedAtTime + battle_area__timeToWarn
        found = true
    if found
      break
  return found


def get_vehicle_time_to_damage(vehicleEid : EntityId; timeByType : Object const?; defTime : float) : float
  var vehicleTime : float const?
  if timeByType == null
    return defTime
  ecs::query(vehicleEid) <| $ [es] (battle_area__timeToDamageType : string)
    vehicleTime = get_float(*timeByType, battle_area__timeToDamageType)
  return vehicleTime ?? defTime

def get_time_to_damage(timeType : das_string const?; timeByType : Object const?; defTime : float) : float
  if timeType == null || timeByType == null
    return defTime
  return get_float(*timeByType, string(*timeType)) ?? defTime

def is_distance_to_poly_border_is_less_than(pos : float2; points : Point2List; value : float)
  let pointsCount = length(points)
  if pointsCount < 3
    return false
  let valueSq = square(value)
  var a = points[pointsCount - 1]
  for b in points
    if distance_sq_to_seg(pos, a, b) < valueSq
      return true
    a = b
  return false

def extend_zone_by(transform : float3x4; value : float; var out_tm : float3x4&)
  let valueTwice = 2.0 * value
  out_tm[0] = transform[0] * (1.0 + safediv(valueTwice, length(transform[0])))
  out_tm[1] = transform[1] * (1.0 + safediv(valueTwice, length(transform[1])))
  out_tm[2] = transform[2] * (1.0 + safediv(valueTwice, length(transform[2])))
  out_tm[3] = transform[3]

def is_entity_outside_warning_border(victim_eid, zone_eid : EntityId; border_width : float)
  let victimTm = get_TMatrix(victim_eid, "transform")
  if victimTm == null || border_width <= 0.0
    return true
  let victimPos = (*victimTm)[3]
  var isOutside = true
  query(zone_eid) <| $ [es] (battleAreaPoints : Point2List) // assuming that point is outside poly
    isOutside = !is_distance_to_poly_border_is_less_than(victimPos.xz, battleAreaPoints, border_width)
  query(zone_eid) <| $ [es(REQUIRE=box_zone)] (transform : float3x4)
    var transformWithBorder : float3x4
    extend_zone_by(transform, border_width, transformWithBorder)
    isOutside = !is_point_in_box_zone(victimPos, transformWithBorder)
  return isOutside

def get_vehicle_battle_area_border_width_or(eid : EntityId; default_value : float)
  return get_float(eid, "battle_areas_visitor__noDamageBorderWidth") ?? default_value

[es(tag=server, REQUIRE=battle_area)]
def battle_area_zone_about_to_deactivate_es(evt : EventEntityAboutToDeactivate;
                                            deactivationDelay : float;
                                            var battle_area__deactivatedAtTime : float&;
                                            var battle_area__deactivateEndTime : float&)
  battle_area__deactivatedAtTime = get_sync_time()
  battle_area__deactivateEndTime = battle_area__deactivatedAtTime + deactivationDelay

[es(tag=server, no_order, REQUIRE=battle_area)]
def battle_area_deactivation_timer(info : UpdateStageInfoAct; eid : EntityId; var battle_area__deactivateEndTime : float&)
  if battle_area__deactivateEndTime > 0. && info.curTime > battle_area__deactivateEndTime
    sendEvent(eid, [[EventEntityActivate activate=false]])
    battle_area__deactivateEndTime = -1.

[es(tag=server, REQUIRE=battle_area)]
def battle_area_zone_reset_time_on_active_changed(evt : EventEntityActivate;
                                                  var battle_area__deactivatedAtTime : float&;
                                                  var battle_area__deactivateEndTime : float&)
  battle_area__deactivatedAtTime = -1.
  battle_area__deactivateEndTime = -1.

[es(tag=server, REQUIRE=battle_area)]
def battle_area_zone_deactivate_es(evt : EventEntityActivate; var zone__keepDead : bool&)
  let activate = evt.activate
  if activate == false
    zone__keepDead = false


[es(tag=server, no_order)]
def old_battle_area_warning_es(info : UpdateStageInfoAct; battle_area__deactivatedAtTime : float; battle_area__timeToWarn : float)
  if battle_area__deactivatedAtTime >= 0.0
    let timeFromWarnStart = info.curTime - (battle_area__deactivatedAtTime + battle_area__timeToWarn)
    if timeFromWarnStart >= 0.0 && timeFromWarnStart <= info.dt
      ecs::query() <| $ [es] (battle_areas_visitor__zonesIn : EidList; team : int; var isInDeactivatingBattleArea : bool&)
        isInDeactivatingBattleArea = !is_in_next_active_battle_area(battle_areas_visitor__zonesIn, team)

[es(tag=server, after=after_net_phys_sync, REQUIRE_NOT=notTakeDamageFromBattleArea)]
def battle_areas_visitor_update_es(info : UpdateStageInfoAct;
                                   eid : EntityId;
                                   transform : float3x4;
                                   var battle_areas_visitor__zonesIn : EidList;
                                   battle_areas_visitor__updateInterval : float;
                                   var battle_areas_visitor__nextUpdateAt : float&;
                                   var isOutsideBattleArea : bool&;
                                   zones_visitor__triggerTag : string;
                                   team : int = TEAM_UNASSIGNED;
                                   beh_tree__enabled : bool = false;
                                   battle_area__timeToDamageType : das_string const?;
                                   human_anim__vehicleSelected : ecs::EntityId = INVALID_ENTITY_ID)
  if info.curTime < battle_areas_visitor__nextUpdateAt
    return
  let updateTimeOveflow = info.curTime - battle_areas_visitor__nextUpdateAt
  if updateTimeOveflow < battle_areas_visitor__updateInterval
    battle_areas_visitor__nextUpdateAt += battle_areas_visitor__updateInterval
  else // either initial update, huge dt or small interval
    battle_areas_visitor__nextUpdateAt = info.curTime + battle_areas_visitor__updateInterval * eid_frnd(eid)

  let anyZoneWasIn = battle_areas_visitor__zonesIn?[0] ?? INVALID_ENTITY_ID

  clear(battle_areas_visitor__zonesIn)
  query_active_battle_areas(transform[3], team, zones_visitor__triggerTag) <| $(area_eid)
    push(battle_areas_visitor__zonesIn, area_eid)
  let zonesInLen = length(battle_areas_visitor__zonesIn)
  if isOutsideBattleArea && zonesInLen > 0 // return to battle area
    isOutsideBattleArea = false
    find_query() <| $ [es] (var battle_area__killList : Array) // remove from kill list
      let idx = find_index_in_kill_list(battle_area__killList, eid)
      if idx >= 0
        erase(battle_area__killList, idx)
        return true // found
      else
        return false
  elif !!anyZoneWasIn && !isOutsideBattleArea && zonesInLen == 0 // go outside of battle areas
    print("Entity left the battle area eid={eid} pos={transform[3]} beh_tree={beh_tree__enabled}")
    isOutsideBattleArea = true
    query(anyZoneWasIn) <| $ [es] (var battle_area__killList : Array; // put to kill list
                                   battle_area__timeToDamage : float;
                                   battle_area__timeToDamageByType : Object const?)
      let defaultTime = battle_area__timeToDamage
      let timeByType  = battle_area__timeToDamageByType
      let visitorType = battle_area__timeToDamageType
      var timeToDamage = get_time_to_damage(visitorType, timeByType, defaultTime)
      timeToDamage     = get_vehicle_time_to_damage(human_anim__vehicleSelected, timeByType, timeToDamage)
      push_to_array(battle_area__killList) <| $(var obj : Object#)
        set(obj, "eid", eid)
        set(obj, "timer", timeToDamage)

[es(tag=server, track=battle_areas_visitor__zonesIn)]
def battle_areas_visitor_check_deactivating(evt : Event;
                                            team : int;
                                            battle_areas_visitor__zonesIn : EidList;
                                            var isInDeactivatingBattleArea : bool&)
  isInDeactivatingBattleArea = !is_in_next_active_battle_area(battle_areas_visitor__zonesIn, team)

[es(tag=server, no_order)]
def battle_area_damage_es(info : UpdateStageInfoAct;
                          eid : EntityId;
                          var battle_area__lastDamageAtTime : float&;
                          var battle_area__killList : ecs::Array;
                          battle_area__damage : float;
                          battle_area__damageInterval : float = 1.0;
                          battle_area__noDamageBorderWidth : float = 0.0;
                          transform : float3x4)
  let dt = info.curTime - battle_area__lastDamageAtTime
  if dt < battle_area__damageInterval
    return
  battle_area__lastDamageAtTime += battle_area__damageInterval

  for elem in battle_area__killList
    var elemObj = getRW_ecs_object(elem)
    if elemObj != null
      var victimTimer = getRW_float(*elemObj, "timer")
      if victimTimer != null
        *victimTimer -= dt
        if *victimTimer > 0.0
          continue
        let victimEid = get_Eid(*elemObj, "eid") ?? ecs::INVALID_ENTITY_ID
        let vehicleEid = get_Eid(victimEid, "human_anim__vehicleSelected") ?? INVALID_ENTITY_ID
        let borderWidth = get_vehicle_battle_area_border_width_or(vehicleEid, battle_area__noDamageBorderWidth)
        let isAlive = get_bool(victimEid, "isAlive") ?? false
        if isAlive && is_entity_outside_warning_border(victimEid, eid, borderWidth)
          let damageDesc = DamageDesc(DamageType DM_ZONE, battle_area__damage, transform[3])
          damage_entity(victimEid, eid, damageDesc)

[es(tag=server, on_event=EventLevelLoaded, REQUIRE=battle_area, REQUIRE=humanTriggerable)]
def human_battle_area_check_es(evt : Event; eid : EntityId)
  var bad = false
  find_query() <| $ [es] (level__fixedBattleAreas : bool; level__navAreas : EidList)
    if level__fixedBattleAreas
      bad = true;
      for navAreaEid in level__navAreas
        if navAreaEid == eid
          bad = false
          break
      return bad
    return false
  if bad
    logerr("This level is using fixed human battle areas, entity {eid} should be created before level entity in {get_current_scene()}")
