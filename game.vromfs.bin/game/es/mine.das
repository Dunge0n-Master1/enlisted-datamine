require enlisted.events_enlisted
require game.es.events
require ecs
require app
require math
require math.base
require game.utils.team
require GridCollision
require Grid
require DagorMath
require ecs.common
require game.es.mine_common

[es(on_event=EventEntityDestroyed, tag=server, REQUIRE=engeneer_mine)]
def mine_was_destroyed_es(evt : Event;
                          transform : float3x4;
                          mineActivatorTemplate : string;
                          placeable_item__ownerEid : EntityId;
                          var mine__activated : bool&)
  if mine__activated
    detonate_mine(INVALID_ENTITY_ID, mineActivatorTemplate, placeable_item__ownerEid, transform)
    mine__activated = false

[es(on_event=EventEntityDestroyed, tag=server)]
def mine_activator_was_destroyed_es(evt : Event;
                                    activator__weaponEid : EntityId)
  if !!activator__weaponEid
    destroyEntity(activator__weaponEid)

[es(on_event=EventEntityDied, tag=server, REQUIRE=engeneer_mine)]
def mine_exploder_by_hp_es(evt : Event;
                           eid : EntityId;
                           transform : float3x4;
                           mineActivatorTemplate : string;
                           placeable_item__ownerEid : EntityId;
                           var mine__activated : bool&)
  if mine__activated
    detonate_mine(eid, mineActivatorTemplate, placeable_item__ownerEid, transform)
    mine__activated = false

[es(on_appear, before=mine_zone_list_cleaner_es, tag=server, REQUIRE=engeneer_mine, REQUIRE_NOT=menuItemObject)]
def mine_init_start_eid_list_es(evt : Event;
                                eid : EntityId;
                                transform : float3x4;
                                activationRadius : float;
                                mine__installBlockTime : float;
                                var mine_activation_zone__initEids : EidList&;
                                var mine__blockedToTime : float&;
                                var mine__activated : bool&)
  let minePosition = transform[3]
  let mineTriggerRadiusSq = square(activationRadius)
  let mineEid = eid

  mine__blockedToTime = get_sync_time() + mine__installBlockTime
  for_each_entity_in_grid([[uint[] ecs_hash("humans"); ecs_hash("vehicles")]], BSphere3(minePosition, activationRadius), GridEntCheck BOUNDING) <| $(visitorEid : EntityId)
    query(visitorEid) <| $ [es(REQUIRE_NOT=deadEntity)] (zones_visitor__triggerTag : string;
                                                         transform : float3x4)
      let zones_visitor__triggerTagHash = ecs_hash(zones_visitor__triggerTag)
      if has(mineEid, zones_visitor__triggerTag, zones_visitor__triggerTagHash) && (length_sq(transform[3] - minePosition) < mineTriggerRadiusSq)
        push(mine_activation_zone__initEids, visitorEid)
  mine__activated = true

def is_eid_in_activation_radius(visitorEid : EntityId; pos : float3; activationRadius : float)
  var inActivatedZone = false
  query(visitorEid) <| $ [es] (transform : float3x4)
    inActivatedZone = length_sq(transform[3] - pos) < square(activationRadius)
  return inActivatedZone

[es(before=mine_zone_checker, tag=server)]
def mine_zone_list_cleaner_es(info : UpdateStageInfoAct;
                              transform : float3x4;
                              activationRadius : float;
                              nextCheckTriggerAtTime : float;
                              var mine_activation_zone__initEids : EidList)
  if nextCheckTriggerAtTime > info.curTime
    return
  let minePosition = transform[3]
  var idx = length(mine_activation_zone__initEids) - 1
  while idx >= 0
    if !is_eid_in_activation_radius(mine_activation_zone__initEids[idx], minePosition, activationRadius)
      mine_activation_zone__initEids |> erase(idx)
    idx--

[es(before=mine_was_destroyed_es, tag=server)]
def mine_zone_checker(info : UpdateStageInfoAct;
                      eid : EntityId;
                      transform : float3x4;
                      placeable_item__ownerEid : EntityId;
                      activationRadius : float;
                      mineActivatorTemplate : string;
                      checkTriggerInterval : float;
                      mine_activation_zone__initEids : EidList;
                      var nextCheckTriggerAtTime : float&;
                      var mine__blockedToTime : float&;
                      var mine__activated : bool&;
                      mine_activation__delay : float = 0.;
                      team = int(TEAM_UNASSIGNED);
                      placeable_item__ownerTeam = int(TEAM_UNASSIGNED))
  if nextCheckTriggerAtTime > info.curTime
    return
  nextCheckTriggerAtTime = info.curTime + checkTriggerInterval
  if !mine__activated
    return

  if mine__blockedToTime < info.curTime
    mine__blockedToTime = -1.0

  let mineTeam = team != TEAM_UNASSIGNED ? team : placeable_item__ownerTeam
  let minePosition = transform[3]
  let mineTriggerRadiusSq = square(activationRadius)
  let mineEid = eid

  var objectFound = false
  find_entity_in_grid([[uint[] ecs_hash("humans"); ecs_hash("vehicles")]], BSphere3(minePosition, activationRadius), GridEntCheck BOUNDING) <| $(objEid : EntityId)
    if objEid == mineEid
      return false
    query(objEid) <| $ [es(REQUIRE_NOT=deadEntity)] (eid : EntityId;
                                                     transform : float3x4;
                                                     zones_visitor__triggerTag : string;
                                                     team : int)
      let idx = find_index(mine_activation_zone__initEids, eid)
      if idx != -1
        return
      let zones_visitor__triggerTagHash = ecs_hash(zones_visitor__triggerTag)
      objectFound = (((mineTeam == TEAM_UNASSIGNED || !is_teams_friendly(mineTeam, team)) && has(mineEid, zones_visitor__triggerTag, zones_visitor__triggerTagHash)) &&
                     (length_sq(transform[3] - minePosition) < mineTriggerRadiusSq))
    return objectFound
  if objectFound && mine__blockedToTime < 0.f
    detonate_mine(eid, mineActivatorTemplate, placeable_item__ownerEid, transform, mine_activation__delay)
    mine__activated = false