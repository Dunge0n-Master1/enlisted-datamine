from "%enlSqGlob/ui_library.nut" import *

let { forcedMinimalHud } = require("%ui/hud/state/hudGameModes.nut")
let {Point2} = require("dagor.math")
let { makeArrow } = require("%ui/hud/huds/hud_markers/components/hud_markers_components.nut")
let {localPlayerTeam} = require("%ui/hud/state/local_player.nut")
let {controlledVehicleEid, inPlane} = require("%ui/hud/state/vehicle_state.nut")
let {
  HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER, HUD_COLOR_ENEMY_INNER, HUD_COLOR_ENEMY_OUTER, HUD_COLOR_UNIDENTIFIED_INNER, HUD_COLOR_UNIDENTIFIED_OUTER
} = require("%enlSqGlob/ui/style/unit_colors.nut")

let defTransform = {}

let unitIconSize = [fsh(1.1), fsh(1.5)].map(@(v) v.tointeger())

let baseIcon = @(colorOuter, colorInner) {
  key = "icon"
  rendObj = ROBJ_IMAGE
  color = colorOuter
  image = Picture($"ui/skin#unit_outer.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
  size = unitIconSize
  minDistance = 0.5
  transform = { translate = [0, hdpx(-10)] }

  children = {
    rendObj = ROBJ_IMAGE
    color = colorInner
    image = Picture($"ui/skin#unit_inner.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
    size = unitIconSize
  }
  markerFlags = MARKER_SHOW_ONLY_IN_VIEWPORT
}

let teammateIcon = baseIcon(HUD_COLOR_TEAMMATE_OUTER, HUD_COLOR_TEAMMATE_INNER)
let enemyIcon    = baseIcon(HUD_COLOR_ENEMY_OUTER, HUD_COLOR_ENEMY_INNER)
let unidentifiedIcon = baseIcon(HUD_COLOR_UNIDENTIFIED_OUTER, HUD_COLOR_UNIDENTIFIED_INNER)
let zeroPoint = Point2(0, 0)
//local opRange = Point2(0.25, 0.75)
let opRange_hardcore = Point2(0.15, 0.35)

return function aircraft(eid, marker) {
  let {isIdentified, isFriendly} = marker
  let isHeroPlane = Computed(@() controlledVehicleEid.value == eid)
  let icon = !isIdentified ? unidentifiedIcon
               : isFriendly ? teammateIcon
               : enemyIcon
  let color = !isIdentified ? HUD_COLOR_UNIDENTIFIED_INNER
                : isFriendly ? HUD_COLOR_TEAMMATE_INNER
                : HUD_COLOR_ENEMY_INNER
  let arrow = makeArrow({ color })

  return function() {
    if (isHeroPlane.value)
      return {watch = isHeroPlane}
    let minHud = forcedMinimalHud.value
    return {
      data = {
        eid
        minDistance = 0.5
        maxDistance = minHud && inPlane.value ? 600 : 10000
        distScaleFactor = 0.3
        clampToBorder = false
        yOffs = 1.2
        opacityRangeX = minHud ? opRange_hardcore : zeroPoint
        opacityRangeY = minHud ? opRange_hardcore : zeroPoint
      }

      key = $"aircraft_marker_{eid}"
      sortOrder = eid

      transform = defTransform

      watch = [isHeroPlane, localPlayerTeam, inPlane, forcedMinimalHud]

      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      children = [icon, arrow]
    }
  }
}
