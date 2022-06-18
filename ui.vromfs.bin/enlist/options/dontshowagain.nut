from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { settings } = require("%enlist/options/onlineSettings.nut")
let { TIME_DAY_IN_SECONDS } = require("%ui/helpers/time.nut")


const DONT_SHOW_TODAY_ID = "dontShowToday"

let curDay = Computed(@() serverTime.value / TIME_DAY_IN_SECONDS)
let dontShowTodayDays = Computed(@() settings.value?[DONT_SHOW_TODAY_ID] ?? {})

let dontShowToday = Computed(function() {
  let day = curDay.value
  return dontShowTodayDays.value.map(@(d) d >= day)
})

let function setDontShowTodayByKey(key, value) {
  if ((dontShowToday.value?[key] ?? false) == value)
    return
  let day = curDay.value
  let list = dontShowTodayDays.value.filter(@(d) d >= day)
  if (value)
    list.__update({ [key] = day })
  else
    delete list[key]
  settings.mutate(@(v) v[DONT_SHOW_TODAY_ID] <- list)
}

console_register_command(@() settings.mutate(@(v) v[DONT_SHOW_TODAY_ID] <- {}), "dontShowAgain.reset")

return {
  dontShowToday = dontShowToday
  setDontShowTodayByKey = setDontShowTodayByKey
}