from "%enlSqGlob/ui_library.nut" import *

let {Point2} = require("dagor.math")
let { destroyable_ri_Set, destroyable_ri_GetWatched } = require("%ui/hud/state/destroyable_score_ri_markers.nut")
let { localPlayerTeam } = require("%ui/hud/state/local_player.nut")
let {HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER, HUD_COLOR_ENEMY_INNER, HUD_COLOR_ENEMY_OUTER} = require("%enlSqGlob/ui/style/unit_colors.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")
let destroyableRiIconSize = [fsh(1), fsh(1.25)].map(@(v) v.tointeger())

let picInner = Picture($"ui/skin#unit_inner.svg:{destroyableRiIconSize[0]}:{destroyableRiIconSize[1]}:K")
let picOuter = Picture($"ui/skin#unit_outer.svg:{destroyableRiIconSize[0]}:{destroyableRiIconSize[1]}:K")

let defData = freeze({
  minDistance = 0.1
  maxDistance = 1000
  distScaleFactor = 0.5
  yOffs = 0.1
  clampToBorder = false
  opacityRangeX = Point2(0.15, 0.15)
  opacityRangeY = Point2(0.15, 0.15)
})

let function destroyable_ri_ctor(eid){
  let markerState = destroyable_ri_GetWatched(eid)
  let data = defData.__merge({eid})
  return function(){
    let addScoreTeam = markerState.value
    return {
      data
      rendObj = ROBJ_IMAGE
      color = is_teams_friendly(localPlayerTeam.value, addScoreTeam) ? HUD_COLOR_ENEMY_OUTER : HUD_COLOR_TEAMMATE_OUTER
      key = eid
      sortOrder = eid
      transform = {}
      image = picOuter
      size = destroyableRiIconSize

      children = {
        rendObj = ROBJ_IMAGE
        color = is_teams_friendly(localPlayerTeam.value, addScoreTeam) ? HUD_COLOR_ENEMY_INNER : HUD_COLOR_TEAMMATE_INNER
        image = picInner
        size = destroyableRiIconSize
      }
      markerFlags = MARKER_SHOW_ONLY_IN_VIEWPORT
      watch = [localPlayerTeam, markerState]
    }
  }
}

let memoizedMap = mkMemoizedMapSet(destroyable_ri_ctor)

return {
  destroyable_ri_ctor = {
    watch = destroyable_ri_Set
    ctor = @() memoizedMap(destroyable_ri_Set.value).values()
  }
}