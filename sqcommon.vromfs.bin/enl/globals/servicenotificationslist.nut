let { globalWatched } = require("%dngscripts/globalState.nut")
let { sound_play } = require("%dngscripts/sound_system.nut")

let {serviceNotificationsList, serviceNotificationsListUpdate} = globalWatched("serviceNotificationsList", @() [])
serviceNotificationsList.subscribe(@(_v) sound_play("ui/enlist/notification"))

return {serviceNotificationsList, serviceNotificationsListUpdate}
