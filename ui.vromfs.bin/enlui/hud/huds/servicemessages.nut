from "%enlSqGlob/ui_library.nut" import *

let { get_time_msec } = require("dagor.time")
let { serviceNotificationsList } = require("%enlSqGlob/serviceNotificationsList.nut")
let isAnyMenuVisible = require("%ui/hud/state/isAnyMenuVisible.nut")
let mkServiceNotification = require("%enlSqGlob/notifications/mkServiceNotification.nut")

const SHOW_TIME_MSEC = 30000

let showInfo = mkWatched(persist, "showInfo", {})
let isNotificationsAttached = Watched(false)
let isNotificationsVisible = Computed(@() isNotificationsAttached.value && !isAnyMenuVisible.value)

let getUid = @(notify) $"{notify.message}_{notify.till_timestamp}"
let messagesToShow = Computed(@() serviceNotificationsList.value
  .filter(function(notify) {
    let { leftTime = SHOW_TIME_MSEC } = showInfo.value?[getUid(notify)]
    return leftTime > 0
  }))

let function addInfoOnce(showInfoV, notify) {
  let uid = getUid(notify)
  if (uid not in showInfoV)
    showInfoV[uid] <- { leftTime = SHOW_TIME_MSEC, hideTime = null }
  return showInfoV[uid]
}

let function updateLeftTime() {
  let list = serviceNotificationsList.value
  if (list.len() == 0)
    return
  let curTimeMsec = get_time_msec()
  let showInfoV = clone showInfo.value
  if (!isNotificationsVisible.value)
    foreach (notify in list) {
      let info = addInfoOnce(showInfoV, notify)
      let { hideTime } = info
      if (hideTime != null)
        info.__update({
          hideTime = null
          leftTime = max(0, hideTime - curTimeMsec)
        })
    }
  else {
    local nextTimeMsec = null
    foreach (notify in list) {
      let info = addInfoOnce(showInfoV, notify)
      let { leftTime, hideTime } = info
      if (leftTime <= 0)
        continue
      if (hideTime == null)
        info.hideTime = curTimeMsec + leftTime
      else if (hideTime <= curTimeMsec)
        info.__update({ hideTime = null, leftTime = 0 })
      if (info.hideTime != null)
        nextTimeMsec = nextTimeMsec == null ? info.hideTime : min(nextTimeMsec, info.hideTime)
    }
    if (nextTimeMsec != null)
      gui_scene.resetTimeout(0.001 * (nextTimeMsec - curTimeMsec), updateLeftTime)
  }
  showInfo(showInfoV)
}
serviceNotificationsList.subscribe(@(_) updateLeftTime())
isNotificationsVisible.subscribe(@(_) updateLeftTime())

let serviceMessages = @() {
  watch = messagesToShow
  size = [flex(), SIZE_TO_CONTENT]
  children = mkServiceNotification(messagesToShow.value, {
    onAttach = @() isNotificationsAttached(true)
    onDetach = @() isNotificationsAttached(false)
    isInBattle = true
  })
}

return {
  hasServiceMessages = Computed(@() messagesToShow.value.len() > 0)
  serviceMessages
}