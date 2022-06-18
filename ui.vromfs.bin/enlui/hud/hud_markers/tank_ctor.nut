from "%enlSqGlob/ui_library.nut" import *

let { forcedMinimalHud } = require("%ui/hud/state/hudGameModes.nut")

let {Point2} = require("dagor.math")
let {controlledVehicleEid, inPlane} = require("%ui/hud/state/vehicle_state.nut")
let teammateName = require("%ui/hud/components/teammateName.nut")
let {
  HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER,
  HUD_COLOR_SQUADMATE_INNER, HUD_COLOR_SQUADMATE_OUTER,
  HUD_COLOR_GROUPMATE_BOT_INNER, HUD_COLOR_GROUPMATE_BOT_OUTER
} = require("%enlSqGlob/ui/style/unit_colors.nut")

let unitIconSize = [fsh(1), fsh(1)].map(@(v) v.tointeger())

let mkIcon = @(colorInner, colorOuter) {
  key = $"icon_{colorInner}_{colorOuter}"
  rendObj = ROBJ_IMAGE
  color = colorOuter
  image = Picture($"ui/skin#tank_unit_outer.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
  size = unitIconSize
  minDistance = 0.5

  children = {
    rendObj = ROBJ_IMAGE
    color = colorInner
    image = Picture($"ui/skin#tank_unit_inner.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
    size = unitIconSize
  }
  markerFlags = MARKER_SHOW_ONLY_IN_VIEWPORT
}

let teammateVehicleIcon = mkIcon(HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER)
let squadVehicleIcon = mkIcon(HUD_COLOR_SQUADMATE_INNER, HUD_COLOR_SQUADMATE_OUTER)
let groupVehicleIcon = mkIcon(HUD_COLOR_GROUPMATE_BOT_INNER, HUD_COLOR_GROUPMATE_BOT_OUTER)

let nameOffset = [fsh(0), fsh(10), -fsh(10)]

let mkNames = function(eid, names) {
  return {
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    pos = [0, -fsh(2)]
    gap = hdpx(5)
    children = names.slice(0, 3).map(@(name, index)
      teammateName(eid, name, HUD_COLOR_TEAMMATE_INNER)
        ?.__update({pos=[nameOffset[index], 0]})
    )
  }
}
let opRangeX = Point2(0.25, 0.35)
let opRangeY = Point2(0.25, 0.75)
let opRangeX_hardcore = Point2(0.125, 0.145)
let zeroPoint = Point2(0, 0)

return function tank(eid, info){
  if (info.isEmpty)
    return null

  return function(){
    if (controlledVehicleEid.value == eid)
      return {watch = controlledVehicleEid}
    let icon = info.hasSquadmates ? squadVehicleIcon
               : info.hasGroupmates ? groupVehicleIcon
               : teammateVehicleIcon
    let showNames = (info?.names.len() ?? 0) > 0
    let names = showNames ? mkNames(eid, info?.names ?? []) : null
    let minHud = forcedMinimalHud.value
    return {
      data = {
        eid
        minDistance = 2
        maxDistance = minHud && !inPlane.value ? 200 : 1000
        distScaleFactor = 0.5
        clampToBorder = false
        yOffs = 0.25
        opacityRangeX = showNames && !minHud
          ? zeroPoint
          : minHud ? opRangeX_hardcore : opRangeX
        opacityRangeY = showNames && ! minHud ? zeroPoint : opRangeY
      }

      key = $"unit_marker_{eid}"
      sortOrder = eid
      watch = [controlledVehicleEid, forcedMinimalHud, inPlane]
      transform = {}

      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      size = [0,0] // icon will have same pos with or without name
      children = [names, icon]
    }
  }
}