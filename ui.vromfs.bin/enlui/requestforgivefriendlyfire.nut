import "%dngscripts/ecs.nut" as ecs
let { has_network } = require("net")
let {client_request_unicast_net_sqevent} = require("ecs.netevent")

return function forgive(localPlayerEid, eid) {
  if (has_network())
    client_request_unicast_net_sqevent(localPlayerEid, ecs.event.RequestForgiveFriendlyFire({eid}))
}