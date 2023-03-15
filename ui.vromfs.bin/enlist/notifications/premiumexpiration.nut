from "%enlSqGlob/ui_library.nut" import *

let canDisplayOffers = require("%enlist/canDisplayOffers.nut")
let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let JB = require("%ui/control/gui_buttons.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { TIME_DAY_IN_SECONDS, secondsToHoursLoc, TIME_HOUR_IN_SECONDS
} = require("%ui/helpers/time.nut")
let { hasPremium, premiumEndTime, premiumActiveTime } = require("%enlist/currency/premium.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { showMsgbox, showMessageWithContent } = require("%enlist/components/msgbox.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let { mkOnlineSaveData } = require("%enlSqGlob/mkOnlineSaveData.nut")
let { premium } = require("%enlist/meta/servProfile.nut")
let { nestWatched } = require("%dngscripts/globalState.nut")
let isNewbie = require("%enlist/unlocks/isNewbie.nut")


let EXPIRING_TIME = TIME_DAY_IN_SECONDS * 15
let MAX_WAIT_TIME = TIME_DAY_IN_SECONDS * 7

let nextTimeToWarn = mkOnlineSaveData("nextTimeToWarnPremium", @() 0)
let setNextTimeToWarn = nextTimeToWarn.setValue
let timeToWarnStorage = nextTimeToWarn.watch
let needToWarn = nestWatched("needToWarnPremium", false)

let canShow = keepref(Computed(@() userInfo.value != null
  && onlineSettingUpdated.value
  && canDisplayOffers.value
))
let needToShowWarn = keepref(Computed(@() !isNewbie.value && needToWarn.value && canShow.value))
let needToCheckTime = keepref(Computed(@() premium.value.len() > 0 && onlineSettingUpdated.value))


let function showExpiringWarn() {
  let timeText = Computed(function(){
    let timeTillExpiration = premiumActiveTime.value
    if (timeTillExpiration <= 0)
      return loc("premium/premiumSuggest")
    return loc("premium/premiumSuggestSoon", { time = secondsToHoursLoc(timeTillExpiration) })
  })
  showMessageWithContent({
    content = @() {
      watch = timeText
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      text = timeText.value
    }.__update(body_txt)
    buttons = [
      {
        text = loc("Ok")
        action = function() {
          premiumWnd()
          sendBigQueryUIEvent("open_premium_window", "premium_expiring")
        }
        customStyle = { hotkeys = [["^J:Y"]] }
      }
      {
        text = loc("Cancel")
        isCurrent = true
        isCancel = true
        customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
      }
    ]
  })
}


let function showExpiredWarn() {
  showMsgbox({
    text = loc("premium/premiumSuggest")
    buttons = [
      {
        text = loc("Ok")
        action = function() {
          premiumWnd()
          sendBigQueryUIEvent("open_premium_window", "premium_expired")
        }
        customStyle = { hotkeys = [["^J:Y"]] }
      }
      {
        text = loc("Cancel")
        isCurrent = true
        isCancel = true
        customStyle = { hotkeys = [[$"^{JB.B} | Esc"]] }
      }
    ]
  })
}


local setNextWarnTime

let function updateTime(delay) {
  gui_scene.resetTimeout(delay, setNextWarnTime)
  setNextTimeToWarn(serverTime.value + delay)
}

setNextWarnTime = function() {
  let nextWarn = timeToWarnStorage.value
  let curTime = serverTime.value
  if (hasPremium.value) {
    let activeTime = premiumActiveTime.value
    if (activeTime < TIME_DAY_IN_SECONDS) {
      let lastHourPremium = activeTime - TIME_HOUR_IN_SECONDS
      if (lastHourPremium < 0)
        needToWarn(true)
      else
        updateTime(lastHourPremium)
      return
    }
    if (activeTime <= EXPIRING_TIME && curTime - nextWarn >= TIME_DAY_IN_SECONDS) {
      // premium ends in 15 days or less and had not had warning today
      updateTime(TIME_DAY_IN_SECONDS)
      needToWarn(true)
    }
    return
  }
  if (curTime < nextWarn)
    return
  let timeWithoutPremium = curTime - premiumEndTime.value
  if (timeWithoutPremium < TIME_DAY_IN_SECONDS) {
    // premium has ended today and player has not seen warning
    updateTime(TIME_DAY_IN_SECONDS)
    needToWarn(true)
    return
  }
  if (timeWithoutPremium > TIME_DAY_IN_SECONDS) {
    let time = timeWithoutPremium <= MAX_WAIT_TIME ? TIME_DAY_IN_SECONDS : MAX_WAIT_TIME
    updateTime(time)
    needToWarn(true)
  }
}

let function showWarning() {
  if (premiumActiveTime.value > 0)
    showExpiringWarn()
  else
    showExpiredWarn()
  defer(@() needToWarn(false))
}

needToCheckTime.subscribe(@(v) v ? setNextWarnTime() : null)
hasPremium.subscribe(@(_v) setNextWarnTime())
needToShowWarn.subscribe(@(v) v ? showWarning() : null)

console_register_command(function(time) {
  setNextTimeToWarn(serverTime.value + time)
  setNextWarnTime()
}, "meta.addPremiumWarningTime")
