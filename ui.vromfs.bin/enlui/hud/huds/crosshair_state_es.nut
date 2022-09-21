import "%dngscripts/ecs.nut" as ecs
from "%enlSqGlob/ui_library.nut" import *

let {E3DCOLOR} = require("dagor.math")

let { watchedTable2TableOfWatched } = require("%sqstd/frp.nut")
let { mkFrameIncrementObservable } = require("%ui/ec_to_watched.nut")
let defValue = freeze({
  crossHairEid = INVALID_ENTITY_ID
  canShoot = false
  teammateAim = false
  isAiming = false
  isAimPressed =false
  overheat = 0.0
  debugForceCrosshair = false
  crosshairType = "t_post"
  crosshairColor = E3DCOLOR(255,255,255,255)
  crosshairReloadEndTime = 0
  crosshairReloadTotalTime = 0
})
let { state, stateSetValue } = mkFrameIncrementObservable(defValue, "state")
let {
  crossHairEid, canShoot, teammateAim, isAiming, isAimPressed, overheat, debugForceCrosshair,
  crosshairType, crosshairColor, crosshairReloadEndTime, crosshairReloadTotalTime
} = watchedTable2TableOfWatched(state)


ecs.register_es("script_chrosshair_state_es",
  {
    [["onChange","onInit"]] = function(_, eid, comp){
      stateSetValue({
        crossHairEid = eid
        canShoot = comp["ui_crosshair_state__canShoot"]
        teammateAim = comp["ui_crosshair_state__teammateAim"]
        isAiming = comp["ui_crosshair_state__isAiming"]
        isAimPressed = comp["ui_crosshair_state__isAimPressed"]
        overheat = comp["ui_crosshair_state__overheat"]
        debugForceCrosshair = comp["ui_crosshair_state__debugForceCrosshair"]
        crosshairType = comp["ui_crosshair_state__crosshairType"]
        crosshairColor = comp["ui_crosshair_state__color"]
        crosshairReloadEndTime = comp["ui_crosshair_state__reloadEndTime"]
        crosshairReloadTotalTime = comp["ui_crosshair_state__reloadTotalTime"]
      })
    },
    onDestroy = @() stateSetValue(defValue)
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
    ]
  }
)

return {
  crossHairEid
  canShoot
  teammateAim
  overheat
  isAiming
  isAimPressed
  debugForceCrosshair
  crosshairType
  crosshairColor
  reloadEndTime = crosshairReloadEndTime
  reloadTotalTime = crosshairReloadTotalTime
}
