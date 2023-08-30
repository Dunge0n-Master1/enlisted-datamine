import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {E3DCOLOR} = require("dagor.math")

let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")
let defValue = freeze({
  crossHairEid = ecs.INVALID_ENTITY_ID
  canShoot = false
  teammateAim = false
  isAiming = false
  isAimPressed =false
  overheat = 0.0
  debugForceCrosshair = false
  crosshairType = "t_post"
  crosshairCustomType = "chevron"
  crosshairColor = E3DCOLOR(255,255,255,255)
  crosshairReloadEndTime = 0
  crosshairReloadTotalTime = 0
  showCustomCrosshair = false
})
let { state, stateSetValue } = mkFrameIncrementObservable(defValue, "state")
let {
  crossHairEid, teammateAim, isAiming, isAimPressed, overheat, debugForceCrosshair,
  crosshairType, crosshairColor, crosshairReloadEndTime, crosshairReloadTotalTime,
  showCustomCrosshair, crosshairCustomType
} = watchedTable2TableOfWatched(state)


ecs.register_es("script_chrosshair_state_es",
  {
    [["onChange","onInit"]] = function(_, eid, comp){
      stateSetValue({
        crossHairEid = eid
        teammateAim = comp["ui_crosshair_state__teammateAim"]
        isAiming = comp["ui_crosshair_state__isAiming"]
        isAimPressed = comp["ui_crosshair_state__isAimPressed"]
        overheat = comp["ui_crosshair_state__overheat"]
        debugForceCrosshair = comp["ui_crosshair_state__debugForceCrosshair"]
        crosshairType = comp["ui_crosshair_state__crosshairType"]
        crosshairColor = comp["ui_crosshair_state__color"]
        crosshairReloadEndTime = comp["ui_crosshair_state__reloadEndTime"]
        crosshairReloadTotalTime = comp["ui_crosshair_state__reloadTotalTime"]
        showCustomCrosshair = comp["ui_crosshair_state__showCustomCrosshair"]
        crosshairCustomType = comp["ui_crosshair_state__crosshairCustomType"]
      })
    },
    onDestroy = @() stateSetValue(defValue)
  },
  {
    comps_track = [
      ["ui_crosshair_state__reloadEndTime", ecs.TYPE_FLOAT],
      ["ui_crosshair_state__reloadTotalTime", ecs.TYPE_FLOAT],
      ["ui_crosshair_state__teammateAim", ecs.TYPE_BOOL],
      ["ui_crosshair_state__isAiming", ecs.TYPE_BOOL],
      ["ui_crosshair_state__isAimPressed", ecs.TYPE_BOOL],
      ["ui_crosshair_state__overheat", ecs.TYPE_FLOAT],
      ["ui_crosshair_state__debugForceCrosshair", ecs.TYPE_BOOL],
      ["ui_crosshair_state__crosshairType", ecs.TYPE_STRING],
      ["ui_crosshair_state__color", ecs.TYPE_COLOR],
      ["ui_crosshair_state__showCustomCrosshair", ecs.TYPE_BOOL],
      ["ui_crosshair_state__crosshairCustomType", ecs.TYPE_STRING]
    ]
  }
)

return {
  crossHairEid
  //canShoot
  teammateAim
  overheat
  isAiming
  isAimPressed
  debugForceCrosshair
  crosshairType
  crosshairColor
  reloadEndTime = crosshairReloadEndTime
  reloadTotalTime = crosshairReloadTotalTime
  showCustomCrosshair,
  crosshairCustomType
}
