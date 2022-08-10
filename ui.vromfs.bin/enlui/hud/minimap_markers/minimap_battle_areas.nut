from "%enlSqGlob/ui_library.nut" import *

let { battleAreasPolygon, nextBattleAreasPolygon } = require("%ui/hud/state/battle_areas_state.nut")
let {cos, PI} = require("math")

let mkPolygon = @(points, minimapState, size, animations = []) {
  color = Color(0, 0, 0, 150)
  fillColor = Color(0, 0, 0, 150)

  rendObj = ROBJ_VECTOR_CANVAS
  commands = [[VECTOR_INVERSE_POLY]]
  lineWidth = hdpx(1)

  minimapState
  size
  points
  behavior = Behaviors.MinimapCanvasPolygon
  animations
}

let mkEasing = function(pause) {
  let invCosInterval = pause < 1 ? 1 / (1 - pause) : 0
  return @(t) t < pause
    ? 0.0
    : 0.5 - cos(2*PI * (t - pause) * invCosInterval) * 0.5
}

let mkZoneAnim = @(duration, pause, from, to) {
  prop = AnimProp.opacity,
  from,
  to,
  duration,
  play = true
  loop = true,
  easing = mkEasing(duration > 0 ? (pause / duration) : 0),
}

let animDuration = 5.0
let animPause = 3.0

let oldZoneAnim = mkZoneAnim(animDuration, animPause, 1, 0)
let nextZoneAnim = mkZoneAnim(animDuration, animPause, 0, 1)

let function makeZone(battleAreasPolygonVal, nextBattleAreasPolygonVal, minimap_state, map_size) {
  if ((nextBattleAreasPolygonVal?.len() ?? 0) == 0)
    return mkPolygon(battleAreasPolygonVal, minimap_state, map_size)
  return {children=[
    mkPolygon(battleAreasPolygonVal, minimap_state, map_size, [oldZoneAnim])
    mkPolygon(nextBattleAreasPolygonVal, minimap_state, map_size, [nextZoneAnim])
  ]}
}

let areasPolygons = Computed(@() battleAreasPolygon.value==null ? null : {
  activeAreaPolygon=battleAreasPolygon.value,
  nextAreaPolygon=nextBattleAreasPolygon.value
})

return {
  watch = areasPolygons
  ctor = @(p) battleAreasPolygon.value == null
    ? []
    : [makeZone(areasPolygons.value.activeAreaPolygon, areasPolygons.value.nextAreaPolygon, p.state, p.size)]
}
