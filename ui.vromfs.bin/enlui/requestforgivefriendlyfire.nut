let { has_network } = require("net")
let {sendNetEvent, RequestForgiveFriendlyFire} = require("dasevents")

return function forgive(localPlayerEid, eid) {
  if (has_network())
    sendNetEvent(localPlayerEid, RequestForgiveFriendlyFire({player=eid}))
}