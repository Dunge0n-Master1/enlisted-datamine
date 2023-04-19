from "%enlSqGlob/ui_library.nut" import *
from "dagor.workcycle" import setInterval

let { get_time_msec } = require("dagor.time")
let time = require("serverTime.nut")

let gameStartServerTimeMsec = mkWatched(persist, "gameStartServerTimeMsec", 0)
let lastReceivedServerTime = mkWatched(persist, "lastReceivedServerTime", 0)

let function updateTime() {
  if (gameStartServerTimeMsec.value <= 0)
    return
  let newTime = (gameStartServerTimeMsec.value + get_time_msec()) / 1000
  // keep local time monotone
  if (newTime > time.value)
    time(newTime)
}

updateTime()
gameStartServerTimeMsec.subscribe(@(_t) updateTime())
setInterval(1.0, updateTime)

let function serverTimeUpdate(timestampMsec, requestTimeMsec) {
  if (timestampMsec <= 0)
    return
  gameStartServerTimeMsec(timestampMsec - (3 * get_time_msec() - requestTimeMsec) / 2)
  lastReceivedServerTime(timestampMsec / 1000)
}

return {
  serverTimeUpdate
  lastReceivedServerTime
}