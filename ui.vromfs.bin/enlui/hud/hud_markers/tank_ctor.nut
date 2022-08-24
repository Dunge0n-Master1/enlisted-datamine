from "%enlSqGlob/ui_library.nut" import *

let { forcedMinimalHud } = require("%ui/hud/state/hudGameModes.nut")

let {Point2} = require("dagor.math")
let {controlledVehicleEid, inPlane} = require("%ui/hud/state/vehicle_state.nut")
let {tank_markers_Set, tank_markers_GetWatched} = require("%ui/hud/state/vehicle_markers.nut")

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

let tank_unit_outer = Picture($"ui/skin#tank_unit_outer.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
let tank_unit_inner = Picture($"ui/skin#tank_unit_inner.svg:{unitIconSize[0]}:{unitIconSize[1]}:K")
let repairIco = Picture($"!ui/skin#item_repair_kit.svg:{repairIconSize[0]}:{repairIconSize[1]}:K")

let mkIcon = memoize(@(colors) {
  rendObj = ROBJ_IMAGE
  color = colors.outer
  image = tank_unit_outer
  size = unitIconSize

  children = {
    rendObj = ROBJ_IMAGE
    color = colors.inner
    image = tank_unit_inner
    size = unitIconSize
  }
  markerFlags = MARKER_SHOW_ONLY_IN_VIEWPORT
})

let mkRepairIcon = memoize(@(colors) {
  rendObj = ROBJ_IMAGE
  color = colors.outer
  image = repairIco
  size = repairIconSize
  pos = [0, fsh(2)]
  children = {
    rendObj = ROBJ_IMAGE
    color = colors.inner
    image = repairIco
    size = repairIconSize
  }
})

let getIconColors = memoize(@(hasSquadmates, hasGroupmates)
  hasSquadmates
    ? {inner=HUD_COLOR_SQUADMATE_INNER,     outer=HUD_COLOR_SQUADMATE_OUTER}
    : hasGroupmates
      ? {inner=HUD_COLOR_GROUPMATE_BOT_INNER, outer=HUD_COLOR_GROUPMATE_BOT_OUTER}
      : {inner=HUD_COLOR_TEAMMATE_INNER,      outer=HUD_COLOR_TEAMMATE_OUTER}
)

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
let sz = [0,0]

let tank = function(eid, repairMarker){
  let infoState = tank_markers_GetWatched(eid)
  let watch = [infoState, forcedMinimalHud, controlledVehicleEid, inPlane, hasRepairKit]
  return function(){
    if (controlledVehicleEid.value == eid)
      return {watch}
    let {names=[], isEmpty, repairRequired, hasSquadmates, hasGroupmates} = infoState.value
    let showNames = names.len() > 0
    let namesComp = showNames ? mkNames(eid, names) : null
    let minHud = forcedMinimalHud.value
    let maxRepairIconDistance = minHud ? MIN_HUD_REPAIR_ICON_MAX_DIST : REPAIR_ICON_MAX_DIST
    let maxIconDistance = minHud && !inPlane.value ? MIN_HUD_ICON_MAX_DIST : ICON_MAX_DIST
    let minDistance = !repairMarker && hasRepairKit.value && repairRequired ? maxRepairIconDistance : 0
    let maxDistance = !repairMarker ? maxIconDistance : maxRepairIconDistance
    let ico = !repairMarker
      ? isEmpty ? null : mkIcon(getIconColors(hasSquadmates, hasGroupmates))
      : hasRepairKit.value && repairRequired ? mkRepairIcon(getIconColors(hasSquadmates, hasGroupmates)) : null
    return {
      data = {
        eid
        distScaleFactor = 0.5
        clampToBorder = false
        yOffs = 0.25
        opacityRangeX = showNames && !minHud
          ? zeroPoint
          : minHud ? opRangeX_hardcore : opRangeX
        opacityRangeY = showNames && !minHud ? zeroPoint : opRangeY
        minDistance
        maxDistance
      }

      sortOrder = eid
      watch
      transform = {}

      halign = ALIGN_CENTER
      valign = ALIGN_BOTTOM
      size = sz // icon will have same pos with or without name
      children = [namesComp, ico]
    }
  }
}

let memoizedMapRepair = mkMemoizedMapSet(@(eid) tank(eid, true))
let memoizedMap = mkMemoizedMapSet(@(eid) tank(eid, false))

return {
  tank_ctor = freeze({
    watch = tank_markers_Set
    ctor = function() {
      let v = tank_markers_Set.value
      return memoizedMap(v).values().extend(memoizedMapRepair(v).values())
    }
  })
}