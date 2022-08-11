from "%enlSqGlob/ui_library.nut" import *

let { localPlayerEid, localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let { engineer_buildings_markers_Set, engineer_buildings_markers_GetWatched, is_engineer } = require("%ui/hud/state/engineer_map_markers.nut")
let iconSz = hdpxi(18)
let mkSvg = memoize(function(img) {
  log($"loading engineer buildings map marker image: '{img}'")
  return $"!ui/uiskin/{img}.svg:{iconSz}:{iconSz}:K"
})

let size = [iconSz, iconSz]
let mkBuildingMapMarker = memoize(function(eid, transform) {
  let data = freeze({
    eid
    minDistance = 0.7
    maxDistance = 2000
    clampToBorder = true
  })
  let marker = engineer_buildings_markers_GetWatched(eid)
  let watch = [is_engineer, localPlayerEid, localPlayerTeam, marker]
  return function() {
    let {image, team, showToBuilderOnly, buildByPlayer} = marker.value
    let isLocalOwner = localPlayerEid.value == buildByPlayer
    let isFriendly = is_teams_friendly(localPlayerTeam.value, team)
    let isVisible = isFriendly && (!showToBuilderOnly || (is_engineer.value && isLocalOwner))
    return {
      data
      watch
      transform = {}
      children = isVisible ? {
        rendObj = ROBJ_IMAGE
        size
        color = Color(255, 255, 255)
        image = image ? Picture(mkSvg(image)) : null
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        transform
      } : null
    }
  }
})

return {
  watch = engineer_buildings_markers_Set
  ctor = function(p) {
    let transform = p?.transform
    return engineer_buildings_markers_Set.value.keys().map(@(eid) mkBuildingMapMarker(eid, transform))
  }
}
