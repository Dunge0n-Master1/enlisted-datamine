from "%enlSqGlob/ui_library.nut" import *

let {respawn_markers, is_engineer} = require("%ui/hud/state/engineer_map_markers.nut")
let iconSz = hdpx(18).tointeger()
let iconImg = Picture("!ui/skin#spawn_point.svg:{0}:{1}:K".subst(iconSz, iconSz))
let customIconImg = Picture("!ui/skin#custom_spawn_point.svg:{0}:{1}:K".subst(iconSz, iconSz))
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let customSpawnColor = Color(255, 255, 255)
let missionSpawnColor = Color(86,131,212,250)

let function mkRespawnMapMarker(eid, marker, options = null) {
  let {custom, team} = marker

  return @() {
    data = {
      eid = eid
      minDistance = 0.7
      maxDistance = 2000
      clampToBorder = true
    }
    transform = {}
    children = localPlayerTeam.value == team && is_engineer.value? [{
      rendObj = ROBJ_IMAGE
      size = [iconSz, iconSz]
      color = custom ? customSpawnColor : missionSpawnColor
      image = custom ? customIconImg : iconImg
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      transform = options?.transform
    }] : null
   watch=[localPlayerTeam, is_engineer]
  }
}

return {
  watch = respawn_markers
  ctor = @(p) respawn_markers.value.reduce(@(res, info, eid) res.append(mkRespawnMapMarker(eid, info, p)), [])
}