import "%dngscripts/ecs.nut" as ecs
let rndInstance = require("%sqstd/rand.nut")()
let {FLT_MAX} = require("math")

let groupRespawnGroupsQuery = ecs.SqQuery("groupRespawnGroupsQuery", {comps_ro=["selectedGroup", "transform", "respawnIconType", "team"], comps_rq=["autoRespawnSelector"]})
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

let function findNearestRespawnGroups(respawnGroups, capZonesPositions) {
  let respawnGroupsMap = {}
  foreach (zonePos in capZonesPositions) {
    let resultGroup = findNearestPoint(zonePos, respawnGroups)[0] ?? -1
    if (respawnGroupsMap?[resultGroup] == null)
      respawnGroupsMap[resultGroup] <- resultGroup
  }
  return respawnGroupsMap
}

let function sortRespawnGroupsByDistance(respawnGroups, capZonesPositions) {
  let respawnGroupsDistance = []
  foreach (respawnGroup, respawnPos in respawnGroups){
    let minDistance = findNearestPoint(respawnPos, capZonesPositions)[1]
    respawnGroupsDistance.append({group = respawnGroup, distance = minDistance})
  }
  respawnGroupsDistance.sort(@(a, b) a.distance <=> b.distance)
  return respawnGroupsDistance
}

let function getRespawnGroups(canUseRespawnbaseType, forTeam) {
  let respawnGroups = {}
  groupRespawnGroupsQuery(function(_eid, comps) {
    if (comps.respawnIconType == canUseRespawnbaseType && comps.team == forTeam)
      respawnGroups[comps.selectedGroup] <- comps.transform[3]
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

let function getAdditionalForSpawnTab(spawnTab, respawnGroups, capZonesPositions){
  let additionalTab = {}
  let allSpawnsByDistance = sortRespawnGroupsByDistance(respawnGroups, capZonesPositions)
  local needAddCount = MIN_NUM_OF_POINTS - spawnTab.len()
  for (local i = 0; i < allSpawnsByDistance.len() && needAddCount!=0; i++)
    if (spawnTab?[allSpawnsByDistance[i].group] == null) {
      additionalTab[allSpawnsByDistance[i].group] <- allSpawnsByDistance[i].group
      needAddCount--
    }
  return additionalTab
}

let function getRespawnGroup(canUseRespawnbaseType, team) {
  let forceRespawnGroup = findForceRespawnBaseGroup(team, canUseRespawnbaseType)
  if (forceRespawnGroup >= 0)
    return forceRespawnGroup
  let respawnGroups = getRespawnGroups(canUseRespawnbaseType, team)
  let capZonesPositions = getCapzonePositions(team)
  local hasEnoughSpawnGroups = respawnGroups.len() >= MIN_NUM_OF_POINTS
  let noAvailableZones = capZonesPositions.len() == 0
  if (noAvailableZones || !hasEnoughSpawnGroups)
    return getRandomRespawnGroup(respawnGroups)

  let prioritySpawnList = findNearestRespawnGroups(respawnGroups, capZonesPositions)
  hasEnoughSpawnGroups = prioritySpawnList.len() >= MIN_NUM_OF_POINTS
  if (!hasEnoughSpawnGroups)
    prioritySpawnList.__update(getAdditionalForSpawnTab(prioritySpawnList, respawnGroups, capZonesPositions))
  return getRandomRespawnGroup(prioritySpawnList)
}

return getRespawnGroup