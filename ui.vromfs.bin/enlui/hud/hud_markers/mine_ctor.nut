from "%enlSqGlob/ui_library.nut" import *

let {Point2} = require("dagor.math")
let {mkCountdownTimer} = require("%ui/helpers/timers.nut")
let {HUD_COLOR_TEAMMATE_OUTER} = require("%enlSqGlob/ui/style/unit_colors.nut")
let {mine_markers_Set, mine_markers_GetWatched} = require("%ui/hud/state/mine_markers.nut")
let { mineIcon } = require("%ui/hud/huds/player_info/mineIcon.nut")

let mineIconSize = [fsh(2.5), fsh(2.5)].map(@(v) v.tointeger())
let mineTimerSize = [fsh(2.5), fsh(2.5)].map(@(v) v.tointeger())
let mineIconMemo = memoize(@(typ, size) mineIcon(typ, size), 1)

let function mkTimerIcon(state) {
  let timerEndtime = Computed(@() state.value.blockedToTime)
  let countDownTimer = mkCountdownTimer(timerEndtime)
  let curProgressW = Computed(@() state.value.installBlockTime > 0 ? countDownTimer.value / state.value.installBlockTime : 0)
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
    commands
  }
}

let function mine(eid){
  let watch = mine_markers_GetWatched(eid)
  let timerIcon = mkTimerIcon(watch)
  return function(){
    let blockedByTimer = watch.value.blockedToTime >= 0
    let mineType = watch.value?.type
    let mIco = mineIconMemo(mineType, mineIconSize)
    return {
      data = {
        eid
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
      key = eid
      sortOrder = eid
      transform = {}
      image = blockedByTimer ? null : mIco
      size = blockedByTimer ? mineTimerSize : mineIconSize
      watch

      children = blockedByTimer ? timerIcon : null
      markerFlags = MARKER_SHOW_ONLY_IN_VIEWPORT
    }
  }
}

let memoizedMap = mkMemoizedMapSet(mine)

return {
  mine_ctor = {watch = mine_markers_Set, ctor = @() memoizedMap(mine_markers_Set.value).values()}
}