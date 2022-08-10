from "%enlSqGlob/ui_library.nut" import *

let canDisplayOffers = require("%enlist/canDisplayOffers.nut")
let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { debounce } = require("%sqstd/timers.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { TIME_DAY_IN_SECONDS, secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { hasPremium, premiumEndTime, premiumActiveTime } = require("%enlist/currency/premium.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { settings, onlineSettingUpdated } = require("%enlist/options/onlineSettings.nut")
let { showMsgbox, showMessageWithContent } = require("%enlist/components/msgbox.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")

const SAVE_ID = "premium/notification"
const warnBeforeExpireDays = "premExpiringLastTime"
const warnAfterExpireDays = "premExpiredLastTime"
const WARN_DELAY = "premExpiredDelay"

let EXPIRING_DAYS = 15
let EXPIRING_FREQ = 1
let MAX_WAIT_TIME = 7

let warnAlreadyShown = mkWatched(persist, "warnAlreadyShown", false) //no need to show again this session even if next day switched.
let debugPremiumDays = mkWatched(persist, "debugPremiumDays" , 0)

let canShow = keepref(Computed(@() userInfo.value != null
  && !warnAlreadyShown.value
  && onlineSettingUpdated.value
  && canDisplayOffers.value
  && premiumEndTime.value > 0
))

let nextWarnData = Computed(@() settings.value?[SAVE_ID])

let function resetNextWarnDay() {
  if (SAVE_ID in settings.value)
    settings.mutate(@(s) delete s[SAVE_ID])
}

let function setNextWarnDay(nextWarn) {
  let premEnd = premiumEndTime.value / TIME_DAY_IN_SECONDS
  let { nextWarnDay = 0, premEndDay = 0 } = nextWarnData.value
  if (nextWarnDay != nextWarn || premEndDay != premEnd)
    settings.mutate(@(v) v[SAVE_ID] <- { nextWarnDay = nextWarn, premEndDay = premEnd })
}

let function showExpiringWarn() {
  let timeText = Computed(function(){
    let timeTillExpiration = premiumActiveTime.value - debugPremiumDays.value * TIME_DAY_IN_SECONDS
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
        customStyle = { hotkeys = [["^{0} | Esc".subst(JB.B)]] }
      }
    ]
  })
}

let function showExpiredWarn(){
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
        customStyle = { hotkeys = [["^{0} | Esc".subst(JB.B)]] }
      }
    ]
  })
}

let function checkExpiration(_) {
  if (!canShow.value)
    return

  let curDay = serverTime.value / TIME_DAY_IN_SECONDS + debugPremiumDays.value
  let curPremEndDay = premiumEndTime.value / TIME_DAY_IN_SECONDS
  let { premEndDay = 0, nextWarnDay = 0 } = nextWarnData.value
  if (premEndDay != curPremEndDay) {
    //no need to warn about premium in a day which player bought it.
    setNextWarnDay(hasPremium.value ? max(curDay + EXPIRING_FREQ, curPremEndDay - EXPIRING_DAYS) : curDay + 1)
    return
  }

  if (nextWarnDay > curDay)
    return

  warnAlreadyShown(true)
  let hasPrem = debugPremiumDays.value == 0 ? hasPremium.value
    : (premiumActiveTime.value - debugPremiumDays.value * TIME_DAY_IN_SECONDS) > 0
  if (hasPrem) {
    showExpiringWarn()
    setNextWarnDay(curDay + EXPIRING_FREQ)
    return
  }

  showExpiredWarn()
  setNextWarnDay(curDay + clamp((curDay - curPremEndDay) * 2, 1, MAX_WAIT_TIME))
}

let checkExpirationDebounced = debounce(checkExpiration, 0.1)
foreach (w in [canShow, premiumEndTime, hasPremium, debugPremiumDays])
  w.subscribe(checkExpirationDebounced)
checkExpirationDebounced(null)

let function setDebugPremiumDays(days) {
  warnAlreadyShown(false)
  debugPremiumDays(days)
}

console_register_command(setDebugPremiumDays, "meta.setDebugPremiumDays")
console_register_command(@(days) setDebugPremiumDays(debugPremiumDays.value + days), "meta.addDebugPremiumDays")
console_register_command(resetNextWarnDay, "meta.resetNextWarnPremiumDays")
