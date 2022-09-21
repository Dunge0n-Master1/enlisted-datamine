from "%enlSqGlob/ui_library.nut" import *

let { hexStringToInt } = require("%sqstd/string.nut")
let { warningColor } = require("%enlSqGlob/ui/viewConst.nut")
let { subscribe } = require("%enlSqGlob/notifications/matchingNotifications.nut")
let { serviceNotificationsList, serviceNotificationsListUpdate } = require("%enlSqGlob/serviceNotificationsList.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let colorize = require("%ui/components/colorize.nut")
const DEF_LIFE_TIME = 300

let function filterOldAndStartTimer() {
  let curTime = serverTime.value
  let newList = serviceNotificationsList.value.filter(@(n) n.till_timestamp > curTime)
  if (newList.len() != serviceNotificationsList.value.len())
    serviceNotificationsListUpdate(newList)

  let nextNotifyTime = newList.reduce(@(res, n) res <= 0 ? n.till_timestamp : min(res, n.till_timestamp), 0)
  if (nextNotifyTime > 0)
    gui_scene.resetTimeout(nextNotifyTime - curTime, filterOldAndStartTimer)
}
filterOldAndStartTimer()

subscribe("web-service", function(ev) {
  if (ev?.func != "show_chat_message")
    return
  local { message = null, till_timestamp = 0, color = 0 } = ev?.params
  if (message == null || (till_timestamp > 0 && till_timestamp <= serverTime.value))
    return

  if (type(color) == "string")
    color = hexStringToInt(color)
  message = colorize(color == 0 ? warningColor : color | 0xFF000000, message)

  if (till_timestamp <= 0)
    till_timestamp = serverTime.value + DEF_LIFE_TIME
  let snl = serviceNotificationsList.value
  snl.append({ message, till_timestamp, uid = $"{message}_{till_timestamp}"})
  serviceNotificationsListUpdate(snl)
  filterOldAndStartTimer()
})