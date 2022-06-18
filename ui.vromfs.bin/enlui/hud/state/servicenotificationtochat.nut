from "%enlSqGlob/ui_library.nut" import *

let serviceNotificationsList = require("%enlSqGlob/serviceNotificationsList.nut")
let { pushSystemMsg } = require("%ui/hud/state/chat.nut")

let showed = persist("showed", @() {})

let pushNewNotifications = @(notifications)
  notifications.each(function(notify) {
    let { message, till_timestamp } = notify
    let uid = $"{message}_{till_timestamp}"
    if (uid in showed)
      return
    showed[uid] <- true
    pushSystemMsg(message)
  })

pushNewNotifications(serviceNotificationsList.value)
serviceNotificationsList.subscribe(pushNewNotifications)