from "%enlSqGlob/ui_library.nut" import *

let {mkOnlineSaveData} = require("%enlSqGlob/mkOnlineSaveData.nut")
let { get_setting_by_blk_path } = require("settings")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")

let unseenEventTimeOffset = get_setting_by_blk_path("unseenEventTimeOffset")
let isNotifierAvailable = type(unseenEventTimeOffset) == "integer"
const SECONDS_IN_DAY = 86400

let nextTimeToShow = mkOnlineSaveData("nextTimeToShow", @() 0)
let nextTimeToShowStored = nextTimeToShow.watch


let function markEventSeen() {
  if (!isNotifierAvailable || serverTime.value < nextTimeToShowStored.value)
    return
  let curTime = serverTime.value
  let curDaySec = (curTime + unseenEventTimeOffset) % SECONDS_IN_DAY
  nextTimeToShow.setValue(curTime + SECONDS_IN_DAY - curDaySec)
}


let isEventUnseen = isNotifierAvailable
  ? Computed(@() serverTime.value > nextTimeToShowStored.value)
  : Watched(false)


return {
  isEventUnseen
  markEventSeen
}