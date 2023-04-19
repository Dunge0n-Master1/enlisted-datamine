require ecs
require ecs.common
require math
require math.base
require DagorMath
require DagorRandom
require Grid
require DngDm
require DngWalkerai
require common_shooter.events_common_shooter

let
  IGNORE_CHANCE_ARTILLERY = 0.0
  IGNORE_CHANCE_GRENADE_SHELL = 0.1
  DANGER_WEIGHT_CENTER = 10000.0
  DANGER_WEIGHT_SIDE = 1000.0
  AWARE_UPDATE_DIST = 1.0


[es(tag=server, on_appear, REQUIRE=shell__explTime)]
def dangers_aware_on_projectile_shell_appear(evt : Event;
                                             eid aka danger_eid : EntityId;
                                             transform aka shell_transform : float3x4;
                                             var danger__awareEids : EidList&;
                                             var danger__awareUpdateDistSq : float&;
                                             var danger__awareLastPos : float3&;
                                             var danger__awareSize : float2&;
                                             danger__awareRadiusCoef : float;
                                             shell__owner : EntityId;
                                             shell__shell_id__shell_id : int;
                                             shell__shell_id__damage_id : int;
                                             shell__shell_id__ballistics_id : int)
  let damageRadius = get_shell_max_radius(shell__shell_id__shell_id, shell__shell_id__damage_id, shell__shell_id__ballistics_id)
  let awareRadius = damageRadius * danger__awareRadiusCoef
  if awareRadius <= 0.5
    return

  var shell_owner_team = -1
  query(shell__owner) <| $ [es] (squad_member__playerEid : EntityId)
    query(squad_member__playerEid) <| $ [es] (team : int)
      shell_owner_team = team
  if shell_owner_team < 0
    return

  danger__awareUpdateDistSq = square(AWARE_UPDATE_DIST)
  danger__awareLastPos = shell_transform[3]
  danger__awareSize = float2(damageRadius + 0.5, damageRadius)

  var walkerAgentsAreaId = -1
  let awareRadiusSq = square(awareRadius)
  for_each_entity_in_grid(ecs_hash("humans"), BSphere3(danger__awareLastPos, awareRadius), GridEntCheck BOUNDING) <| $(human_eid : EntityId)
    query(human_eid) <| $ [es(REQUIRE_NOT=deadEntity)] (isAlive : bool;
                                                        transform aka human_transform : float3x4;
                                                        squad_member__playerEid : EntityId;
                                                        isInVehicleHidden : bool = false)
      if !isAlive || isInVehicleHidden
        return

      if rnd_float(0.0, 1.0) < IGNORE_CHANCE_GRENADE_SHELL
        return

      var human_team = -1
      query(squad_member__playerEid) <| $ [es] (team : int)
        human_team = team
      if human_team != shell_owner_team
        return

      query(human_eid) <| $ [es] (var aware__dangersEids : EidList&; var aware__dangersData : IntList&; aware__maxDangers : int; var walker_agent : EntityAgent)
        if distance_sq(danger__awareLastPos, human_transform[3]) <= awareRadiusSq && length(aware__dangersEids) < aware__maxDangers
          if walkerAgentsAreaId < 0
            walkerAgentsAreaId = walker_agent_nav_allocAreaId()
          walker_agent_nav_areaUpdateCylinder(walker_agent, walkerAgentsAreaId, danger__awareLastPos, danger__awareSize,
                                              DANGER_WEIGHT_CENTER, DANGER_WEIGHT_SIDE, false)
          push(aware__dangersData, walkerAgentsAreaId)
          push(aware__dangersEids, danger_eid)
          push(danger__awareEids, human_eid)


[es(tag=server, on_appear, REQUIRE=dmgzone__damage)]
def dangers_aware_on_dmgzone_artillery_warning_appear(evt : Event;
                                                      eid aka warning_eid : EntityId;
                                                      artillery__targetPos : float3;
                                                      sphere_zone__radius : float;
                                                      artillery_zone__showOnMinimap : bool = true;
                                                      dmgzone__dangerWarning : bool;
                                                      dmgzone__dangerForBotSquadsOnly : bool = true;
                                                      var transform aka warning_transform : float3x4&;
                                                      var danger__awareEids : EidList&;
                                                      var danger__awareUpdateDistSq : float&;
                                                      var danger__awareLastPos : float3&;
                                                      var danger__awareSize : float2&;
                                                      danger__awareRadiusCoef : float)
  if !dmgzone__dangerWarning || !artillery_zone__showOnMinimap
    return

  let damageRadius = sphere_zone__radius
  let awareRadius = damageRadius * danger__awareRadiusCoef
  if awareRadius <= 0.5
    return

  danger__awareUpdateDistSq = square(AWARE_UPDATE_DIST)
  danger__awareLastPos = artillery__targetPos
  danger__awareSize = float2(damageRadius + 0.5, 1000.0)

  warning_transform[3] = artillery__targetPos;

  var walkerAgentsAreaId = -1
  let awareRadiusSq = square(awareRadius)
  for_each_entity_in_grid(ecs_hash("humans"), BSphere3(danger__awareLastPos, awareRadius), GridEntCheck BOUNDING) <| $(human_eid : EntityId)
    query(human_eid) <| $ [es(REQUIRE_NOT=deadEntity)] (isAlive : bool;
                                                        transform aka human_transform : float3x4;
                                                        squad_member__playerEid : EntityId = INVALID_ENTITY_ID;
                                                        isInVehicleHidden : bool = false)
      if !isAlive || isInVehicleHidden
        return

      if dmgzone__dangerForBotSquadsOnly && !!squad_member__playerEid && !has(squad_member__playerEid, "playerIsBot")
        return

      if rnd_float(0.0, 1.0) < IGNORE_CHANCE_ARTILLERY
        return

      query(human_eid) <| $ [es] (var aware__dangersEids : EidList&; var aware__dangersData : IntList&; aware__maxDangers : int; var walker_agent : EntityAgent)
        if distance_sq(danger__awareLastPos, human_transform[3]) <= awareRadiusSq && length(aware__dangersEids) < aware__maxDangers
          if walkerAgentsAreaId < 0
            walkerAgentsAreaId = walker_agent_nav_allocAreaId()
          walker_agent_nav_areaUpdateCylinder(walker_agent, walkerAgentsAreaId, danger__awareLastPos, danger__awareSize,
                                              DANGER_WEIGHT_CENTER, DANGER_WEIGHT_SIDE, false)
          push(aware__dangersData, walkerAgentsAreaId)
          push(aware__dangersEids, warning_eid)
          push(danger__awareEids, human_eid)


[es(tag=server, no_order)]
def dangers_aware_on_danger_update(info : UpdateStageInfoAct;
                                   eid aka danger_eid : EntityId;
                                   transform : float3x4;
                                   danger__awareEids : EidList;
                                   danger__awareUpdateDistSq : float;
                                   danger__awareSize : float2;
                                   var danger__awareLastPos : float3&)
  if empty(danger__awareEids)
    return
  if distance_sq(transform[3], danger__awareLastPos) < danger__awareUpdateDistSq
    return

  danger__awareLastPos = transform[3]

  for awareEid in danger__awareEids
    query(awareEid) <| $ [es] (aware__dangersEids : EidList; aware__dangersData : IntList; var walker_agent : EntityAgent)
      let dangerIdx = find_index(aware__dangersEids, danger_eid)
      if dangerIdx >= 0
        let areaId = aware__dangersData[dangerIdx]
        walker_agent_nav_areaUpdateCylinder(walker_agent, areaId, danger__awareLastPos, danger__awareSize,
                                            DANGER_WEIGHT_CENTER, DANGER_WEIGHT_SIDE, false)


[es(tag=server, on_event=EventShellExplodedServer, on_disappear)]
def dangers_aware_on_danger_disappear(evt : Event;
                                      eid aka danger_eid : EntityId;
                                      var danger__awareEids : EidList&)
  for awareEid in danger__awareEids
    query(awareEid) <| $ [es] (var aware__dangersEids : EidList&; var aware__dangersData : IntList&; var walker_agent : EntityAgent)
      let dangerIdx = find_index(aware__dangersEids, danger_eid)
      if dangerIdx >= 0
        let areaId = aware__dangersData[dangerIdx]
        walker_agent_nav_areaRemove(walker_agent, areaId)
        erase(aware__dangersEids, dangerIdx)
        erase(aware__dangersData, dangerIdx)

  clear(danger__awareEids)


[es(tag=server, on_disappear)]
def dangers_aware_on_walker_agent_disappear(evt : Event;
                                            eid aka aware_eid : EntityId;
                                            var aware__dangersEids : EidList&;
                                            var aware__dangersData : IntList&;
                                            var walker_agent : EntityAgent)
  for dangerIdx in iter_range(aware__dangersEids)
    let areaId = aware__dangersData[dangerIdx]
    walker_agent_nav_areaRemove(walker_agent, areaId)
    query(aware__dangersEids[dangerIdx]) <| $ [es] (var danger__awareEids : EidList&)
      let awareIdx = find_index(danger__awareEids, aware_eid)
      if awareIdx >= 0
        erase(danger__awareEids, awareIdx)

  clear(aware__dangersEids)
  clear(aware__dangersData)
