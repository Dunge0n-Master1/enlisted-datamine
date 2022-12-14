import "%dngscripts/ecs.nut" as ecs
let rndInstance = require("%sqstd/rand.nut")()
let {FLT_MAX} = require("math")

let { check_exists_navmesh_path_from_respawn_to_capzone, is_respawn_at_team_side } = require("das.respawn")

let groupRespawnGroupsQuery = ecs.SqQuery("groupRespawnGroupsQuery", {comps_ro=["selectedGroup", "transform", "respawnIconType", "team"], comps_rq=["autoRespawnSelector"]})
let groupCustomRespawnGroupsQuery = ecs.SqQuery("groupCustomRespawnGroupsQuery", {comps_ro=["selectedGroup", "transform", "respawnIconType", "team", "respawn_point__respawnersQueue"], comps_no=["autoRespawnSelector"]})
let capzoneQuery = ecs.SqQuery("capzoneQuery", {comps_ro=["active", "transform", "capzone__capTeam"], comps_rq=["capzone"]})
let forceRespawnGroupsQuery = ecs.SqQuery("forceRespawnGroupsQuery", {comps_ro=["respawnBaseGroup", "team", "active", "respawnbaseType"], comps_rq=["forceRespawnBasePriority"]})

const MIN_NUM_OF_POINTS = 2 // minimum number of points from which select random spawn

let function getRandomRespawnGroup(respawns) {
  let respawnsArray = respawns.topairs()
  if (respawnsArray.len() == 0)
    return -1
  let randId = rndInstance.rint(0, respawnsArray.len() - 1)
  let randElem = respawnsArray[randId]
  return randElem?[0] ?? -1
}

let function findNearestPoint(target, points) {
  local minDistance = FLT_MAX
  local nearestKey = null
  foreach (key, point in points) {
    let distance = (target - point).lengthSq()
    if (distance < minDistance) {
      minDistance = distance
      nearestKey = key
    }
  }
  return [nearestKey, minDistance]
}

let function findNearestRespawnGroups(capZonesPositions, respawnGroups, customRespawnGroups, respawnPointsEids, team) {
  let respawnGroupsMap = {}
  foreach (zonePos in capZonesPositions) {
    let resultGroup = findNearestPoint(zonePos, respawnGroups)
    let resultCustomGroup = findNearestPoint(zonePos, customRespawnGroups)

    local selectedGroup = resultGroup[0]
    let customGroup = resultCustomGroup[0]
    if (customGroup != null && resultCustomGroup[1] < resultGroup[1]) {
      let pointEid = respawnPointsEids[customGroup]
      let spawnPos = customRespawnGroups[customGroup]
      if (is_respawn_at_team_side(spawnPos, zonePos, team))
        if (check_exists_navmesh_path_from_respawn_to_capzone(pointEid, spawnPos, zonePos))
          selectedGroup = customGroup
    }

    if (respawnGroupsMap?[selectedGroup] == null)
      respawnGroupsMap[selectedGroup] <- selectedGroup
  }
  return respawnGroupsMap
}

let function sortRespawnGroupsByDistance(capZonesPositions, respawnGroups, customRespawnGroups) {
  let respawnGroupsDistance = []
  foreach (respawnGroup, respawnPos in respawnGroups){
    let minDistance = findNearestPoint(respawnPos, capZonesPositions)[1]
    respawnGroupsDistance.append({group = respawnGroup, distance = minDistance})
  }
  foreach (respawnGroup, respawnPos in customRespawnGroups){
    let minDistance = findNearestPoint(respawnPos, capZonesPositions)[1]
    respawnGroupsDistance.append({group = respawnGroup, distance = minDistance})
  }
  respawnGroupsDistance.sort(@(a, b) a.distance <=> b.distance)
  return respawnGroupsDistance
}

let function getRespawnGroups(canUseRespawnbaseType, forTeam, respawnPointsEids) {
  let respawnGroups = {}
  groupRespawnGroupsQuery(function(eid, comps) {
    if (comps.respawnIconType == canUseRespawnbaseType && comps.team == forTeam) {
      respawnGroups[comps.selectedGroup] <- comps.transform[3]
      respawnPointsEids[comps.selectedGroup] <- eid
    }
  })
  return respawnGroups
}

let function getCustomRespawnGroups(canUseRespawnbaseType, forTeam, respawnPointsEids) {
  let respawnGroups = {}
  groupCustomRespawnGroupsQuery(function(eid, comps) {
    if (comps.respawnIconType == canUseRespawnbaseType && comps.team == forTeam && comps.respawn_point__respawnersQueue.len() == 0) {
      respawnGroups[comps.selectedGroup] <- comps.transform[3]
      respawnPointsEids[comps.selectedGroup] <- eid
    }
  })
  return respawnGroups
}

let function getCapzonePositions(team) {
  let capzonesPos = []
  capzoneQuery.perform(function(_eid, comps) {
    if (comps.active && comps["capzone__capTeam"] != team)
      capzonesPos.append(comps.transform[3])
  })
  return capzonesPos
}

let function findForceRespawnBaseGroup(team, respawnType) {
  local respawnGroup = -1
  forceRespawnGroupsQuery.perform(function(_eid, comps) {
    if (comps.active && comps.team == team && respawnType == comps.respawnbaseType)
      respawnGroup = comps.respawnBaseGroup
  })
  return respawnGroup
}

let function getAdditionalForSpawnTab(spawnTab, capZonesPositions, respawnGroups, customRespawnGroups){
  let additionalTab = {}
  let allSpawnsByDistance = sortRespawnGroupsByDistance(capZonesPositions, respawnGroups, customRespawnGroups)
  local needAddCount = MIN_NUM_OF_POINTS - spawnTab.len()
  for (local i = 0; i < allSpawnsByDistance.len() && needAddCount!=0; i++)
    if (spawnTab?[allSpawnsByDistance[i].group] == null) {
      additionalTab[allSpawnsByDistance[i].group] <- allSpawnsByDistance[i].group
      needAddCount--
    }
  return additionalTab
}

let function getRespawnGroup(canUseRespawnbaseType, team, for_bot) {
  let forceRespawnGroup = findForceRespawnBaseGroup(team, canUseRespawnbaseType)
  if (forceRespawnGroup >= 0)
    return forceRespawnGroup

  let respawnPointsEids = {}
  let respawnGroups = getRespawnGroups(canUseRespawnbaseType, team, respawnPointsEids)

  let capZonesPositions = getCapzonePositions(team)
  if (capZonesPositions.len() == 0)
    return getRandomRespawnGroup(respawnGroups)

  let customRespawnGroups = for_bot ? getCustomRespawnGroups(canUseRespawnbaseType, team, respawnPointsEids) : {}

  let hasChoice = respawnGroups.len() >= MIN_NUM_OF_POINTS || customRespawnGroups.len() > 0
  if (!hasChoice)
    return getRandomRespawnGroup(respawnGroups)

  let prioritySpawnList = findNearestRespawnGroups(capZonesPositions, respawnGroups, customRespawnGroups, respawnPointsEids, team)
  let hasEnoughSpawnGroups = prioritySpawnList.len() >= MIN_NUM_OF_POINTS
  if (!hasEnoughSpawnGroups)
    prioritySpawnList.__update(getAdditionalForSpawnTab(prioritySpawnList, capZonesPositions, respawnGroups, customRespawnGroups))

  return getRandomRespawnGroup(prioritySpawnList)
}

return getRespawnGroup
