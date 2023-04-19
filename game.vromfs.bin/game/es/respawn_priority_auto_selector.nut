import "%dngscripts/ecs.nut" as ecs
let rndInstance = require("%sqstd/rand.nut")()
let {FLT_MAX} = require("math")

let { check_exists_navmesh_path_from_respawn_to_capzone, is_respawn_at_team_side } = require("das.respawn")

let groupRespawnGroupsQuery = ecs.SqQuery("groupRespawnGroupsQuery", {comps_ro=["selectedGroup", "transform", "respawnIconType", "team"], comps_rq=["autoRespawnSelector"]})
let groupCustomRespawnGroupsQuery = ecs.SqQuery("groupCustomRespawnGroupsQuery", {comps_ro=["selectedGroup", "transform", "respawnIconType", "team", "respawn_point__respawnersQueue"], comps_no=["autoRespawnSelector"]})
let teamAutoSpawnQuery = ecs.SqQuery("teamAutoSpawnQuery", {comps_ro=["team__id"], comps_rw=[["team__lastAutoSpawnCapZoneEid", ecs.TYPE_EID], ["team__prevAutoSpawnCapZoneEid", ecs.TYPE_EID]]})
let capzoneQuery = ecs.SqQuery("capzoneQuery", {comps_ro=["active", "transform"], comps_rq=["capzone"]})
let forceRespawnGroupsQuery = ecs.SqQuery("forceRespawnGroupsQuery", {comps_ro=["respawnBaseGroup", "team", "active", "respawnbaseType"], comps_rq=["forceRespawnBasePriority"]})

const MIN_NUM_OF_POINTS = 2 // minimum number of points from which select random spawn

let function acceptRandomRespawnGroup(respawns, team) {
  local lastEid = ecs.INVALID_ENTITY_ID
  local prevEid = ecs.INVALID_ENTITY_ID
  teamAutoSpawnQuery.perform(function(_eid, comps) {
    if (comps.team__id == team) {
      lastEid = comps.team__lastAutoSpawnCapZoneEid
      prevEid = comps.team__prevAutoSpawnCapZoneEid
    }
  })

  let groups = []
  foreach (respawn in respawns) {
    let zoneEid = respawn?.zoneEid ?? ecs.INVALID_ENTITY_ID
    let group = respawn?.group
    if (group != null)
      groups.append({group, zoneEid})
  }
  if (groups.len() == 0)
    return -1

  let oneZoneEid = groups[0].zoneEid
  local oneZoneOnly = true
  foreach (group in groups)
    if (group.zoneEid != oneZoneEid)
      oneZoneOnly = false

  if (!oneZoneOnly) {
    if (lastEid != ecs.INVALID_ENTITY_ID && groups.len() > 1) {
      foreach (idx, group in groups) {
        if (lastEid == group.zoneEid) {
          groups.remove(idx)
          break
        }
      }
    }
    if (prevEid != ecs.INVALID_ENTITY_ID && groups.len() > 1) {
      foreach (idx, group in groups) {
        if (prevEid == group.zoneEid) {
          groups.remove(idx)
          break
        }
      }
    }
  }

  let ridx = (groups.len() == 1) ? 0 : rndInstance.rint(0, groups.len() - 1)
  let selectedGroup = groups[ridx].group
  let selectedZoneEid = groups[ridx].zoneEid

  teamAutoSpawnQuery.perform(function(_eid, comps) {
    if (comps.team__id == team) {
      comps.team__prevAutoSpawnCapZoneEid = comps.team__lastAutoSpawnCapZoneEid
      comps.team__lastAutoSpawnCapZoneEid = selectedZoneEid
    }
  })

  return selectedGroup
}

let function findNearestRespawnGroup(target, groups) {
  local minDistance = FLT_MAX
  local nearestIdx = null
  foreach (idx, group in groups) {
    let distance = (target - group.point).lengthSq()
    if (distance < minDistance) {
      minDistance = distance
      nearestIdx = idx
    }
  }
  return [nearestIdx, minDistance]
}

let function findNearestRespawnGroups(capzones, respawnGroups, customRespawnGroups, team) {
  let resultRespawnGroups = {}
  foreach (capzone in capzones) {
    let zonePos = capzone.zonePos
    let nearest1 = findNearestRespawnGroup(zonePos, respawnGroups)
    let nearest2 = findNearestRespawnGroup(zonePos, customRespawnGroups)

    local selectedGroup = nearest1[0] ?? -1

    let customGroup = nearest2[0]
    if (customGroup != null && nearest2[1] < nearest1[1]) {
      let customResp = customRespawnGroups[customGroup]
      let spawnPos = customResp.point
      if (is_respawn_at_team_side(spawnPos, zonePos, team))
        if (check_exists_navmesh_path_from_respawn_to_capzone(customResp.pointEid, spawnPos, zonePos))
          selectedGroup = customGroup
    }

    if (resultRespawnGroups?[selectedGroup] == null)
      resultRespawnGroups[selectedGroup] <- {group = selectedGroup, zoneEid = capzone.zoneEid}
  }
  return resultRespawnGroups
}

let function findNearestCapZone(target, capzones) {
  local minDistance = FLT_MAX
  local zoneEid = ecs.INVALID_ENTITY_ID
  foreach (capzone in capzones) {
    let point = capzone.zonePos
    let distance = (target - point).lengthSq()
    if (distance < minDistance) {
      minDistance = distance
      zoneEid = capzone.zoneEid
    }
  }
  return [zoneEid, minDistance]
}

let function sortRespawnGroupsByDistance(capzones, respawnGroups, customRespawnGroups) {
  let respawnGroupsByDistance = []
  foreach (respawnGroup in respawnGroups){
    let nearest = findNearestCapZone(respawnGroup.point, capzones)
    respawnGroupsByDistance.append({group = respawnGroup.group, zoneEid = nearest[0], distance = nearest[1]})
  }
  foreach (respawnGroup in customRespawnGroups){
    let nearest = findNearestCapZone(respawnGroup.point, capzones)
    respawnGroupsByDistance.append({group = respawnGroup.group, zoneEid = nearest[0], distance = nearest[1]})
  }
  respawnGroupsByDistance.sort(@(a, b) a.distance <=> b.distance)
  return respawnGroupsByDistance
}

let function getAdditionalForSpawnTab(spawnTab, capzones, respawnGroups, customRespawnGroups){
  let additionalTab = {}
  let allSpawnsByDistance = sortRespawnGroupsByDistance(capzones, respawnGroups, customRespawnGroups)
  local needAddCount = MIN_NUM_OF_POINTS - spawnTab.len()
  for (local i = 0; i < allSpawnsByDistance.len() && needAddCount != 0; i++) {
    let spawn = allSpawnsByDistance[i]
    let group = spawn.group
    if (spawnTab?[group] == null) {
      additionalTab[group] <- {group, zoneEid = spawn.zoneEid}
      needAddCount--
    }
  }
  return additionalTab
}

let function getRespawnGroups(canUseRespawnbaseType, forTeam) {
  let respawnGroups = {}
  groupRespawnGroupsQuery(function(eid, comps) {
    if (comps.respawnIconType == canUseRespawnbaseType && comps.team == forTeam)
      respawnGroups[comps.selectedGroup] <- {point = comps.transform[3], pointEid = eid, group = comps.selectedGroup, zoneEid = ecs.INVALID_ENTITY_ID}
  })
  return respawnGroups
}

let function getCustomRespawnGroups(canUseRespawnbaseType, forTeam) {
  let respawnGroups = {}
  groupCustomRespawnGroupsQuery(function(eid, comps) {
    if (comps.respawnIconType == canUseRespawnbaseType && comps.team == forTeam && comps.respawn_point__respawnersQueue.len() == 0)
      respawnGroups[comps.selectedGroup] <- {point = comps.transform[3], pointEid = eid, group = comps.selectedGroup, zoneEid = ecs.INVALID_ENTITY_ID}
  })
  return respawnGroups
}

let function getTargetCapzones(_team) {
  let capzones = []
  capzoneQuery.perform(function(eid, comps) {
    if (comps.active)
      capzones.append({zoneEid = eid, zonePos = comps.transform[3]})
  })
  return capzones
}

let function findForceRespawnBaseGroup(team, respawnType) {
  local respawnGroup = -1
  forceRespawnGroupsQuery.perform(function(_eid, comps) {
    if (comps.active && comps.team == team && respawnType == comps.respawnbaseType)
      respawnGroup = comps.respawnBaseGroup
  })
  return respawnGroup
}

let function getRespawnGroup(canUseRespawnbaseType, team, for_bot) {
  let forceRespawnGroup = findForceRespawnBaseGroup(team, canUseRespawnbaseType)
  if (forceRespawnGroup >= 0)
    return forceRespawnGroup

  let respawnGroups = getRespawnGroups(canUseRespawnbaseType, team)

  let capZones = getTargetCapzones(team)
  if (capZones.len() == 0)
    return acceptRandomRespawnGroup(respawnGroups, team)

  let customRespawnGroups = for_bot ? getCustomRespawnGroups(canUseRespawnbaseType, team) : {}

  let hasChoice = respawnGroups.len() >= MIN_NUM_OF_POINTS || customRespawnGroups.len() > 0
  if (!hasChoice)
    return acceptRandomRespawnGroup(respawnGroups, team)

  let prioritySpawnList = findNearestRespawnGroups(capZones, respawnGroups, customRespawnGroups, team)
  let hasEnoughSpawnGroups = prioritySpawnList.len() >= MIN_NUM_OF_POINTS
  if (!hasEnoughSpawnGroups)
    prioritySpawnList.__update(getAdditionalForSpawnTab(prioritySpawnList, capZones, respawnGroups, customRespawnGroups))

  return acceptRandomRespawnGroup(prioritySpawnList, team)
}

return getRespawnGroup
