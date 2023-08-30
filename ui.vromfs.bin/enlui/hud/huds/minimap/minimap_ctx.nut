import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *
from "minimap" import MinimapContext

let {Point2} = require("dagor.math")
let {inPlane} = require("%ui/hud/state/vehicle_state.nut")

let mmapComps = {comps_ro = [
  ["left_top", ecs.TYPE_POINT2],
  ["right_bottom", ecs.TYPE_POINT2],
  ["farLeftTop", ecs.TYPE_POINT2, Point2(0,0)],
  ["farRightBottom", ecs.TYPE_POINT2, Point2(0,0)],
  ["northAngle", ecs.TYPE_FLOAT, 0.0],
  ["mapTex", ecs.TYPE_STRING],
  ["farMapTex", ecs.TYPE_STRING, null]
]}

let minimapQuery = ecs.SqQuery("minimapQuery", mmapComps)

let config = {
  mapColor = Color(255, 255, 255, 255)
  fovColor = Color(10, 0, 0, 200)
  mapTex = ""
  left_top = Point2(0,0)
  right_bottom = Point2(0,0)
  northAngle = 0.0
}


let mmContext = persist("ctx", function() {
  let ctx = MinimapContext()
  ctx.setup(config)
  return ctx
})

let function onMinimap(_eid, comp){
  let hasBackMap = (inPlane.value && (comp.farMapTex != null))
  mmContext.setup(config.__merge({
    mapTex = comp.mapTex
    right_bottom = comp.right_bottom
    left_top = comp.left_top
    northAngle = comp.northAngle
  }).__merge(!hasBackMap ? {} : {
    backMapTex = comp.farMapTex
    back_left_top = comp.farLeftTop
    back_right_bottom = comp.farRightBottom
  }))
}

inPlane.subscribe(function(_) {
  minimapQuery.perform(onMinimap)
})

ecs.register_es("minimap_ui_es", { onInit = onMinimap}, mmapComps)


return mmContext
