import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {E3DCOLOR} = require("dagor.math")
let stateEid = mkWatched(persist, "stateEid", INVALID_ENTITY_ID)
let canShoot = mkWatched(persist, "canShoot", false)
let teammateAim = mkWatched(persist, "teammateAim", false)
let isAiming = mkWatched(persist, "isAiming", false)
let isAimPressed = mkWatched(persist, "isAimPressed", false)
let overheat = mkWatched(persist, "overheat", 0.0)
let debugForceCrosshair = mkWatched(persist, "debugForceCrosshair", false)
let crosshairType = mkWatched(persist, "crosshairType", "t_post")
let crosshairColor = mkWatched(persist, "crosshairColor", E3DCOLOR(255, 255, 255, 255))
let showCustomCrosshair = mkWatched(persist, "showCustomCrosshair", false)
let crosshairCustomType = mkWatched(persist, "crosshairCustomType", "chevron")
let crosshairReloadEndTime = mkWatched(persist, "crosshairReloadEndTime", 0)
let crosshairReloadTotalTime = mkWatched(persist, "crosshairReloadTotalTime", 0)

let function trackCrossHair(eid, comp) {
  stateEid(eid)
  canShoot(comp["ui_crosshair_state__canShoot"])
  teammateAim(comp["ui_crosshair_state__teammateAim"])
  isAiming.update(comp["ui_crosshair_state__isAiming"])
  isAimPressed(comp.ui_crosshair_state__isAimPressed)
  overheat(comp["ui_crosshair_state__overheat"])
  debugForceCrosshair(comp["ui_crosshair_state__debugForceCrosshair"])
  crosshairType(comp["ui_crosshair_state__crosshairType"])
  crosshairColor(comp["ui_crosshair_state__color"])
  showCustomCrosshair(comp["ui_crosshair_state__showCustomCrosshair"])
  crosshairCustomType(comp["ui_crosshair_state__crosshairCustomType"])
  crosshairReloadEndTime(comp.ui_crosshair_state__reloadEndTime)
  crosshairReloadTotalTime(comp.ui_crosshair_state__reloadTotalTime)
}

ecs.register_es("script_chrosshair_state_es",
  {
    [["onChange","onInit"]] = trackCrossHair,
    onDestroy = @() stateEid(INVALID_ENTITY_ID)
  },
  {
    comps_track = [
      ["ui_crosshair_state__reloadEndTime", ecs.TYPE_FLOAT],
      ["ui_crosshair_state__reloadTotalTime", ecs.TYPE_FLOAT],
      ["ui_crosshair_state__canShoot", ecs.TYPE_BOOL],
      ["ui_crosshair_state__teammateAim", ecs.TYPE_BOOL],
      ["ui_crosshair_state__isAiming", ecs.TYPE_BOOL],
      ["ui_crosshair_state__isAimPressed", ecs.TYPE_BOOL],
      ["ui_crosshair_state__overheat", ecs.TYPE_FLOAT],
      ["ui_crosshair_state__debugForceCrosshair", ecs.TYPE_BOOL],
      ["ui_crosshair_state__crosshairType", ecs.TYPE_STRING],
      ["ui_crosshair_state__color", ecs.TYPE_COLOR],
      ["ui_crosshair_state__showCustomCrosshair", ecs.TYPE_BOOL],
      ["ui_crosshair_state__crosshairCustomType", ecs.TYPE_STRING],
    ]
  }
)

return {
  eid = stateEid
  canShoot = canShoot
  teammateAim = teammateAim
  overheat = overheat
  isAiming = isAiming
  isAimPressed
  debugForceCrosshair = debugForceCrosshair
  crosshairType = crosshairType
  crosshairColor = crosshairColor
  showCustomCrosshair = showCustomCrosshair
  crosshairCustomType = crosshairCustomType
  reloadEndTime = crosshairReloadEndTime
  reloadTotalTime = crosshairReloadTotalTime
}
