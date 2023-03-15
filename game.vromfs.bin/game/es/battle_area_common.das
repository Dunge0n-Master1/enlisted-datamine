module battle_area_common shared
require ecs
require ecs.common
require DagorMath
require zones
require game.utils.team
require math.linear
require math.base

def is_point_in_box_zone(pos : float3; transform : float3x4)
  let zonePos = inverse(transform) * pos
  return IDENT_BBOX & zonePos

[generic, unused_argument(trigger_tag, eid)]
def private check_active_poly_battle_area(pos2 : float2;
                                          team : int;
                                          trigger_tag : auto(TT);
                                          eid : EntityId;
                                          battleAreaPoints : Point2List;
                                          battle_area__team : int)
  if battle_area__team == TEAM_UNASSIGNED || team == TEAM_UNASSIGNED || battle_area__team == team
    static_if typeinfo(is_string type<TT>)
      if !has(eid, trigger_tag, ecs_hash(trigger_tag))
        return false
    if is_point_in_poly(pos2, battleAreaPoints)
      return true
  return false

[generic, unused_argument(trigger_tag, eid)]
def private check_active_box_battle_area(pos : float3;
                                         team : int;
                                         trigger_tag : auto(TT);
                                         eid : EntityId;
                                         transform : float3x4;
                                         battle_area__team : int)
  if battle_area__team == TEAM_UNASSIGNED || team == TEAM_UNASSIGNED || battle_area__team == team
    static_if typeinfo(is_string type<TT>)
      if !has(eid, trigger_tag, ecs_hash(trigger_tag))
        return false
    if is_point_in_box_zone(pos, transform)
      return true
  return false

def query_active_battle_areas(pos : float3; team : int; trigger_tag : string; cb : block<(eid : EntityId) : void>)
  let pos2 = pos.xz
  if trigger_tag == "humanTriggerable" // fast path (without trigger_tag checks)
    ecs::query() <| $ [es(REQUIRE=battle_area, REQUIRE=humanTriggerable)] (eid : EntityId; battleAreaPoints : Point2List;
                                                                           battle_area__team : int; active : bool)
      if active && check_active_poly_battle_area(pos2, team, true, eid, battleAreaPoints, battle_area__team)
        invoke(cb, eid)
    ecs::query() <| $ [es(REQUIRE=battle_area, REQUIRE=box_zone, REQUIRE=humanTriggerable)] (eid : EntityId; transform : float3x4;
                                                                                             battle_area__team : int; active : bool)
      if active && check_active_box_battle_area(pos, team, true, eid, transform, battle_area__team)
        invoke(cb, eid)
  else // generic triggerable tag path
    ecs::query() <| $ [es(REQUIRE=battle_area)] (eid : EntityId; battleAreaPoints : Point2List;
                                                 battle_area__team : int; active : bool)
      if active && check_active_poly_battle_area(pos2, team, trigger_tag, eid, battleAreaPoints, battle_area__team)
        invoke(cb, eid)
    ecs::query() <| $ [es(REQUIRE=battle_area, REQUIRE=box_zone)] (eid : EntityId; transform : float3x4;
                                                                   battle_area__team : int; active : bool)
      if active && check_active_box_battle_area(pos, team, trigger_tag, eid, transform, battle_area__team)
        invoke(cb, eid)

enum FindActiveBattleAreasRes
  not_found
  found
  no_any

def find_active_battle_areas(pos : float3; team : int; trigger_tag : string; cb : block<(eid : EntityId) : bool>)
  return find_battle_areas(pos, team, trigger_tag, true/* with_active */, cb)

def find_battle_areas(pos : float3; team : int; trigger_tag : string; with_active : bool; cb : block<(eid : EntityId) : bool>)
  let pos2 = pos.xz
  var hasAnyBattleAreas = false
  let polyRes = ecs::find_query() <| $ [es(REQUIRE=battle_area)] (eid : EntityId; battleAreaPoints : Point2List;
                                                                  battle_area__team : int; active : bool)
    hasAnyBattleAreas = true
    if active == with_active && check_active_poly_battle_area(pos2, team, trigger_tag, eid, battleAreaPoints, battle_area__team)
      if invoke(cb, eid)
        return true
    return false
  if polyRes
    return FindActiveBattleAreasRes found
  let boxRes = ecs::find_query() <| $ [es(REQUIRE=battle_area, REQUIRE=box_zone)] (eid : EntityId; transform : float3x4;
                                                                                   battle_area__team : int; active : bool)
    hasAnyBattleAreas = true
    if active == with_active && check_active_box_battle_area(pos, team, trigger_tag, eid, transform, battle_area__team)
      if invoke(cb, eid)
        return true
    return false
  if boxRes
    return FindActiveBattleAreasRes found
  return hasAnyBattleAreas ? FindActiveBattleAreasRes not_found : FindActiveBattleAreasRes no_any

def is_segment_in_active_human_battle_area(start, end : float3; team : int = int(TEAM_UNASSIGNED))
  let result = find_active_battle_areas(start, team, "humanTriggerable") <| $(area_eid)
    var res = true
    query(area_eid) <| $ [es(REQUIRE=battle_area)] (battleAreaPoints : Point2List)
      let start2 = start.xz
      let end2 = end.xz
      let pointCount = length(battleAreaPoints)
      if pointCount < 3
        return
      var a = battleAreaPoints[pointCount - 1]
      for b in battleAreaPoints
        if is_2d_lines_crossed(a, b, start2, end2)
          res = false
          return
        a = b
    if !res
      return res
    query(area_eid) <| $ [es(REQUIRE=battle_area, REQUIRE=box_zone)] (transform : float3x4)
      res = is_point_in_box_zone(end, transform)
    return res
  return result != FindActiveBattleAreasRes not_found

def has_active_non_deactivating_human_battle_area_at(pos : float3; team : int = int(TEAM_UNASSIGNED))
  let result = find_active_battle_areas(pos, team, "humanTriggerable") <| $(area_eid)
    return (get_float(area_eid, "battle_area__deactivatedAtTime") ?? 0f) <= 0.
  return result != FindActiveBattleAreasRes not_found

def has_active_human_battle_area_at(pos : float3; team : int = int(TEAM_UNASSIGNED))
  let result = find_active_battle_areas(pos, team, "humanTriggerable") <| $ [unused_argument(area_eid)] (area_eid) => true
  return result != FindActiveBattleAreasRes not_found

def has_active_human_battle_area_at(pos : float3; team : int; exlude_eid : ecs::EntityId)
  let result = find_active_battle_areas(pos, team, "humanTriggerable") <| $(area_eid)
    return area_eid != exlude_eid
  return result != FindActiveBattleAreasRes not_found

def has_any_human_battle_area_at(pos : float3; team : int = int(TEAM_UNASSIGNED))
  for wishActive in [[auto true; false]]
    let result = find_battle_areas(pos, team, "humanTriggerable", wishActive) <| $ [unused_argument(area_eid)] (area_eid) => true
    if result != FindActiveBattleAreasRes not_found
      return true
  return false

def is_tm_outside_battle_area(tm, team)
  let pos = tm[3]
  return !has_active_human_battle_area_at(pos, team)

def is_tm_outside_any_battle_area(tm, team)
  let pos = tm[3]
  return !has_any_human_battle_area_at(pos, team)
