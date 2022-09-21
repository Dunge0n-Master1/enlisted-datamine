from "%enlSqGlob/ui_library.nut" import *

let { serviceNotificationsList } = require("%enlSqGlob/serviceNotificationsList.nut")
let { pushSystemMsg } = require("%ui/hud/state/chat.nut")

let shown = persist("shown", @() {})

let pushNewNotifications = @(notifications)
  notifications.each(function(notify) {
    let { message, uid } = notify
    if (uid in shown)
      return
    shown[uid] <- true
    pushSystemMsg(message)
  })

pushNewNotifications(serviceNotificationsList.value)
serviceNotificationsList.subscribe(pushNewNotifications)