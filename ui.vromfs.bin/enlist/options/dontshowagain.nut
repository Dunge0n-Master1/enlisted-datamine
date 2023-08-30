from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { settings } = require("%enlist/options/onlineSettings.nut")
let { TIME_DAY_IN_SECONDS } = require("%ui/helpers/time.nut")

const DONT_SHOW_TODAY_ID = "dontShowToday"

let dontShowToday = Computed(@() settings.value?[DONT_SHOW_TODAY_ID] ?? {})

let curDaySeconds = Watched(0)

let function recalcDay() {
  let time = serverTime.value
  let today = (time / TIME_DAY_IN_SECONDS) * TIME_DAY_IN_SECONDS
  curDaySeconds(today)
  gui_scene.resetTimeout(today + TIME_DAY_IN_SECONDS - time, recalcDay)
}


serverTime.subscribe(function(t) {
  if (t <= 0)
    return
  serverTime.unsubscribe(callee())
  recalcDay()
})


let function setDontShowToday(key, value) {
  let list = clone dontShowToday.value

  if (value)
    list[key] <- curDaySeconds.value
  else
    delete list[key]

  settings.mutate(@(v) v[DONT_SHOW_TODAY_ID] <- list)
}


let getDontShowToday = @(key) (dontShowToday.value?[key] ?? 0) == curDaySeconds.value


let function mkDontShowTodayComp(key) {
  return Computed(function(){
    return (dontShowToday.value?[key] ?? 0) == curDaySeconds.value
  })
}

console_register_command(@() settings.mutate(@(v) v[DONT_SHOW_TODAY_ID] <- {}), "dontShowAgain.reset")

return {
  setDontShowToday
  getDontShowToday
  mkDontShowTodayComp
}