from "%enlSqGlob/ui_library.nut" import *

let { forcedMinimalHud } = require("%ui/hud/state/hudGameModes.nut")

let {Point2} = require("dagor.math")
let {controlledVehicleEid, inPlane} = require("%ui/hud/state/vehicle_state.nut")
let teammateName = require("%ui/hud/components/teammateName.nut")
let {hasRepairKit} = require("%ui/hud/state/vehicle_maintenance_state.nut")
let {
  HUD_COLOR_TEAMMATE_INNER, HUD_COLOR_TEAMMATE_OUTER,
  HUD_COLOR_SQUADMATE_INNER, HUD_COLOR_SQUADMATE_OUTER,
  HUD_COLOR_GROUPMATE_BOT_INNER, HUD_COLOR_GROUPMATE_BOT_OUTER
} = require("%enlSqGlob/ui/style/unit_colors.nut")

let MIN_HUD_REPAIR_ICON_MAX_DIST = 40
let REPAIR_ICON_MAX_DIST = 50
let MIN_HUD_ICON_MAX_DIST = 200
let ICON_MAX_DIST = 1000

let unitIconSize = [fsh(1), fsh(1)].map(@(v) v.tointeger())
let repairIconSize = [fsh(3), fsh(3)].map(@(v) v.tointeger())

let mkIcon = @(colors) {
  rendObj = ROBJ_IMAGE
  color = colors.outer
  image = Picture($"ui/skin#tank_unit_outer.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
  size = unitIconSize

  children = {
    rendObj = ROBJ_IMAGE
    color = colors.inner
    image = Picture($"ui/skin#tank_unit_inner.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
    size = unitIconSize
  }
  markerFlags = MARKER_SHOW_ONLY_IN_VIEWPORT
}

let mkRepairIcon = @(colors) {
  rendObj = ROBJ_IMAGE
  color = colors.outer
  image = Picture($"ui/skin#item_reapair_kit.svg:{repairIconSize[0]}:{repairIconSize[1]}:K")
  size = repairIconSize
  pos = [0, fsh(2)]
  children = {
    rendObj = ROBJ_IMAGE
    color = colors.inner
    image = Picture($"ui/skin#item_reapair_kit.svg:{repairIconSize[0]}:{repairIconSize[1]}:K")
    size = repairIconSize
  }
}

let nothing = @(...) null

let getIconColors = @(info)
  info.hasSquadmates     ? {inner=HUD_COLOR_SQUADMATE_INNER,     outer=HUD_COLOR_SQUADMATE_OUTER}
    : info.hasGroupmates ? {inner=HUD_COLOR_GROUPMATE_BOT_INNER, outer=HUD_COLOR_GROUPMATE_BOT_OUTER}
                         : {inner=HUD_COLOR_TEAMMATE_INNER,      outer=HUD_COLOR_TEAMMATE_OUTER}

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
  let minHud = forcedMinimalHud.value
  let maxRepairIconDistance = minHud ? MIN_HUD_REPAIR_ICON_MAX_DIST : REPAIR_ICON_MAX_DIST
  let maxIconDistance = minHud && !inPlane.value ? MIN_HUD_ICON_MAX_DIST : ICON_MAX_DIST
  let mkTankIcon = function(iconCtor, minDistance, maxDistance) {
    if (controlledVehicleEid.value == eid)
      return {watch = controlledVehicleEid}
    let colors = getIconColors(info)
    let showNames = (info?.names.len() ?? 0) > 0
    let names = showNames ? mkNames(eid, info?.names ?? []) : null

    return {
      data = {
        eid
        distScaleFactor = 0.5
        clampToBorder = false
        yOffs = 0.25
        opacityRangeX = showNames && !minHud
          ? zeroPoint
          : minHud ? opRangeX_hardcore : opRangeX
        opacityRangeY = showNames && ! minHud ? zeroPoint : opRangeY
        minDistance
        maxDistance
      }

      key = $"unit_marker_{eid}"
      sortOrder = eid
      watch = [controlledVehicleEid, forcedMinimalHud, inPlane, hasRepairKit]
      transform = {}

      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      size = [0,0] // icon will have same pos with or without name
      children = [names, iconCtor(colors)]
    }
  }
  return [
    @() mkTankIcon(info.isEmpty ? nothing : mkIcon, hasRepairKit.value && info.repairRequired ? maxRepairIconDistance : 0, maxIconDistance)
    @() mkTankIcon(hasRepairKit.value && info.repairRequired ? mkRepairIcon : nothing, 0, maxRepairIconDistance)
  ]
}