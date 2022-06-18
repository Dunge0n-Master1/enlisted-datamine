from "%enlSqGlob/ui_library.nut" import *

let {Point2} = require("dagor.math")
let { localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let {HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER, HUD_COLOR_ENEMY_INNER, HUD_COLOR_ENEMY_OUTER} = require("%enlSqGlob/ui/style/unit_colors.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let destroyableRiIconSize = [fsh(1), fsh(1.25)].map(@(v) v.tointeger())

let function destroyable_ri_ctor(eid, info){
  return @(){
      data = {
        eid = eid
        minDistance = 0.1
        maxDistance = 1000
        distScaleFactor = 0.5
        yOffs = 0.1
        clampToBorder = false
        opacityRangeX = Point2(0.15, 0.15)
        opacityRangeY = Point2(0.15, 0.15)
      }
      rendObj = ROBJ_IMAGE
      color = is_teams_friendly(localPlayerTeam.value, info.addScoreTeam) ? HUD_COLOR_ENEMY_OUTER : HUD_COLOR_TEAMMATE_OUTER
      key = $"destroyable_ri_marker_{eid}"
      sortOrder = eid
      transform = {}
      image = Picture($"ui/skin#unit_outer.svg:{destroyableRiIconSize[0]}:{destroyableRiIconSize[1]}:K")
      size = destroyableRiIconSize

      children = {
        rendObj = ROBJ_IMAGE
        color = is_teams_friendly(localPlayerTeam.value, info.addScoreTeam) ? HUD_COLOR_ENEMY_INNER : HUD_COLOR_TEAMMATE_INNER
        image = Picture($"ui/skin#unit_inner.svg:{destroyableRiIconSize[0]}:{destroyableRiIconSize[1]}:K")
        size = destroyableRiIconSize
      }
      markerFlags = MARKER_SHOW_ONLY_IN_VIEWPORT
      watch = [localPlayerTeam]
    }
}

return {
  destroyable_ri_ctor
}