let sharedWatched = require("%dngscripts/sharedWatched.nut")
let { sound_play } = require("sound")

let serviceNotificationsList = sharedWatched("serviceNotificationsList", @() [])
serviceNotificationsList.subscribe(@(_v) sound_play("ui/enlist/notification"))

return serviceNotificationsList
