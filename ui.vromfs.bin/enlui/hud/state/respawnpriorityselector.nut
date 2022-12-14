import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {needSpawnMenu, selectedRespawnGroupId, canUseRespawnbaseByType} = require("%ui/hud/state/respawnState.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let groupRespawnsGroupsQuery = ecs.SqQuery("groupRespawnGroupsQuery", {comps_ro=["selectedGroup", "team", "respawnIconType"]})

let function getRespawnGroups(forTeam, exludeEid = ecs.INVALID_ENTITY_ID) {
  let respawnGroups = {}
  groupRespawnsGroupsQuery(function(eid, comps) {
    if (comps.team == forTeam && comps.respawnIconType == canUseRespawnbaseByType.value && exludeEid != eid)
      respawnGroups[comps.selectedGroup] <- true
  })
  return respawnGroups
}

let function updateSelectedRespawnGroup(exludeEid = ecs.INVALID_ENTITY_ID) {
  if (!needSpawnMenu.value)
    return
  let respawnGroups = getRespawnGroups(localPlayerTeam.value, exludeEid)
  let respawnType = canUseRespawnbaseByType.value
  let playerSelectedGroupExist = (respawnGroups?[selectedRespawnGroupId.value?[respawnType]] != null)
  if (!playerSelectedGroupExist)
    selectedRespawnGroupId.mutate(@(v) v[respawnType] <- -1)
}

needSpawnMenu.subscribe(@(_v) updateSelectedRespawnGroup())
canUseRespawnbaseByType.subscribe(@(_v) updateSelectedRespawnGroup())

ecs.register_es("respawn_priority_es", {
  [["onInit","onDestroy","onChange"]] = @(...) updateSelectedRespawnGroup()
}, {
  comps_track = [
    ["capzone__capTeam", ecs.TYPE_INT],
    ["active", ecs.TYPE_BOOL]
  ]
})

ecs.register_es("respawn_selector_reset_es", {
  onDestroy = @(_evt,eid,_comp) updateSelectedRespawnGroup(eid)
  onInit = @(...) updateSelectedRespawnGroup()
}, {
  comps_rq = ["selectedGroup"]
})
