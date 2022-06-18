from "ui_library.nut" import *

let sharedWatched = require("%dngscripts/sharedWatched.nut")
let showCreateRoom = mkWatched(persist, "showCreateRoom", false)
let controllerDisconnected = sharedWatched("controllerDisconnected", @() false)
let actionInProgress = sharedWatched("actionInProgress", @() false)

return {
  showCreateRoom
  controllerDisconnected
  actionInProgress
}
