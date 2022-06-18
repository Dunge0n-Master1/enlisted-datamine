from "%enlSqGlob/ui_library.nut" import *

let profileServer = require("%enlist/profileServer/profileServer.nut")
let eventbus = require("eventbus")

let function sendResult(data, id) {
  eventbus.send("profile_srv.response", {data, id})
}


let function handleMessages(msg) {
  let {id, data} = msg
  profileServer.request(data.method, data?.params, id,
    @(result) sendResult(result, id), data?.token)
}


eventbus.subscribe("profile_srv.request", handleMessages)
