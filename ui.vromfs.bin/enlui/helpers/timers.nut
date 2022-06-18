from "%enlSqGlob/ui_library.nut" import *

let {get_time_msec} = require("dagor.time")
let {get_sync_time} = require("net")
let {ceil} = require("math")

const defaultTimeStep = 0.016666
let function mkCountdownTimer(endTimeWatch, curTimeFunc=get_sync_time, step = defaultTimeStep, timeProcess = @(v) v) {
  let countdownTimer = Watched(0)
  let function updateTimer() {
    let cTime = curTimeFunc()
    let leftTime = max((endTimeWatch.value ?? cTime) - cTime, 0)
    if (leftTime > 0) {
      gui_scene.clearTimer(updateTimer)
      gui_scene.setTimeout(step, updateTimer)
    }
    countdownTimer(timeProcess(leftTime))
  }
  endTimeWatch.subscribe(@(_) updateTimer())
  updateTimer()
  return countdownTimer
}

let function mkUpdateCb(updateDtFunc){
  local curtime = 0
  local last_time = 0
  let function updateCb(){
    curtime = get_time_msec()/1000.0
    updateDtFunc(curtime - last_time)
    last_time = curtime
  }
  return updateCb
}

let setIntervalForUpdateFunc = @(interval, updateDtFunc) gui_scene.setInterval(interval, mkUpdateCb(updateDtFunc))

return {
  mkCountdownTimer
  mkCountdownTimerPerSec = @(endTimeWatch) mkCountdownTimer(endTimeWatch, get_sync_time, 1.0, @(v) ceil(v).tointeger())
  mkUpdateCb
  setIntervalForUpdateFunc
}