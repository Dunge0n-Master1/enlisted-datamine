from "%enlSqGlob/ui_library.nut" import *

let {useful_box_markers_GetWatched, useful_box_markers_Set} = require("%ui/hud/state/useful_boxes.nut")
let {Point2} = require("dagor.math")
let { watchedTeam } = require("%ui/hud/state/watched_hero.nut")
let is_teams_friendly = require("%enlSqGlob/is_teams_friendly.nut")

let mkSize =  @(x,y) [fsh(x), fsh(y)].map(@(v) v.tointeger())
let defaultIconSize = mkSize(3.5, 3.5)
let mkSvg = memoize(function(img, size) {
  return $"!ui/uiskin/{img}.svg:{size[0]}:{size[1]}:K"
})

let mkIco = memoize(function(image, size) {
  return {
    size
    halign = ALIGN_CENTER
    valign = ALIGN_CENTER
    hplace = ALIGN_CENTER
    vplace = ALIGN_CENTER
    rendObj = ROBJ_IMAGE
    image = image!= null ? Picture(mkSvg(image, size)) : null
  }
})

let opx = Point2(0.2, 0.2)
let ctor = function(eid) {
  let state = useful_box_markers_GetWatched(eid)
  let watch = [watchedTeam, state]
  return function() {
    let info = state.value
    let iconSize = info?.size ? mkSize(info.size.x, info.size.y) : defaultIconSize
    let isFriendly = is_teams_friendly(info?.team, watchedTeam.value)
    if (!isFriendly)
      return {watch}
    return {
      watch
      data = {
        eid
        minDistance = info?.minDistance ?? 0.1
        maxDistance = info?.maxDistance ?? 10.0
        yOffs = info?.offsetY ?? 0.0
        distScaleFactor = 0.5
        clampToBorder = info?.clampToBorder ?? false
        opacityRangeX = info?.opacityRangeX ?? opx
        opacityRangeY = info?.opacityRangeY ?? opx
        opacityCenterRelativeDist = info?.opacityCenterRelativeDist ?? 0.05
        opacityCenterMinMult = info?.opacityCenterMinMult ?? 0.5
      }
      halign = ALIGN_CENTER
      valign = ALIGN_CENTER
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      transform = {}
      key = eid
      behavior = Behaviors.OverlayTransparency
      sortOrder = eid
      children = mkIco(info.image, iconSize)
    }
  }
}

let memoizedMap = mkMemoizedMapSet(ctor)
return {
   useful_boxes_marker_ctor = {
     watch = useful_box_markers_Set
     ctor = @() memoizedMap(useful_box_markers_Set.value).values()
   }
}
