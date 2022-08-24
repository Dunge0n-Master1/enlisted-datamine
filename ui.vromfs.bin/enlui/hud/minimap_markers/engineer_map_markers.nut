from "%enlSqGlob/ui_library.nut" import *

let { respawn_markers_Set, respawn_markers_GetWatched, is_engineer} = require("%ui/hud/state/engineer_map_markers.nut")
let iconSz = hdpxi(18)
let iconImg = Picture("!ui/skin#spawn_point.svg:{0}:{1}:K".subst(iconSz, iconSz))
let customIconImg = Picture("!ui/skin#custom_spawn_point.svg:{0}:{1}:K".subst(iconSz, iconSz))
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let customSpawnColor = Color(255, 255, 255)
let missionSpawnColor = Color(86,131,212,250)

let size = [iconSz, iconSz]
let mkRespawnMapMarker = function(eid, transform) {
  let data = freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = true
  })
  let marker = respawn_markers_GetWatched(eid)
  let watch = [is_engineer, localPlayerTeam, marker]
  return function() {
    let {isCustom, team} = marker.value
    return {
      data
      watch
      transform = {}
      children = localPlayerTeam.value == team && is_engineer.value ? {
        rendObj = ROBJ_IMAGE
        size
        color = isCustom ? customSpawnColor : missionSpawnColor
        image = isCustom ? customIconImg : iconImg
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform
      } : null
    }
  }
}

let memoizedMapByTransform = memoize(@(transform) mkMemoizedMapSet(@(eid) mkRespawnMapMarker(eid, transform)))
return {
  watch = respawn_markers_Set
  ctor = @(p) memoizedMapByTransform(p?.transform)(respawn_markers_Set.value).values()
}