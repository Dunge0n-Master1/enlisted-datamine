from "%enlSqGlob/ui_library.nut" import *

let {Point2} = require("dagor.math")
let {mkCountdownTimer} = require("%ui/helpers/timers.nut")
let {HUD_COLOR_TEAMMATE_OUTER} = require("%enlSqGlob/ui/style/unit_colors.nut")

let mineIconSize = [fsh(2.5), fsh(2.5)].map(@(v) v.tointeger())
let mineTimerSize = [fsh(2.5), fsh(2.5)].map(@(v) v.tointeger())
let { mine_markers } = require("%ui/hud/state/mine_markers.nut")
let { mineIcon } = require("%ui/hud/huds/player_info/mineIcon.nut")

let function mkTimerIcon(info) {
  let timerEndtime = Watched(info.blockedToTime)
  let countDownTimer = mkCountdownTimer(timerEndtime)
  let curProgressW = Computed(@() info.installBlockTime > 0 ? countDownTimer.value / info.installBlockTime : 0)
  let commands = [
    [VECTOR_FILL_COLOR, Color(0, 0, 0, 0)],
    [VECTOR_SECTOR, 50, 50, 50, 50, 0.0, 0.0],
  ]
  let sector = commands[1]
  curProgressW.subscribe(@(v) sector[6] = 360.0 * v)
  return @() {
    watch = curProgressW
    size = mineTimerSize
    lineWidth = mineTimerSize[0] * 0.3
    color = Color(255, 255, 255)
    fillColor = Color(122, 1, 0, 0)
    rendObj = ROBJ_VECTOR_CANVAS
    commands = commands
  }
}

let function unit(eid, info){
  let blockedByTimer = info.blockedToTime >= 0
  let mineType = info?.type
  return @(){
      data = {
        eid = eid
        minDistance = 0.1
        maxDistance = 10
        distScaleFactor = 0.5
        yOffs = blockedByTimer ? 0.2 : 0.1
        clampToBorder = false
        opacityRangeX = Point2(0.2, 0.2)
        opacityRangeY = Point2(0.2, 0.2)
      }
      rendObj = ROBJ_IMAGE
      color = HUD_COLOR_TEAMMATE_OUTER
      key = $"mine_marker_{eid}"
      sortOrder = eid
      transform = {}
      image = blockedByTimer ? null : mineIcon(mineType, mineIconSize)
      size = blockedByTimer ? mineTimerSize : mineIconSize
      watch = [mine_markers]

      children = blockedByTimer ? mkTimerIcon(info) : null
      markerFlags = MARKER_SHOW_ONLY_IN_VIEWPORT
    }
}

return {
  mine_ctor = unit
}