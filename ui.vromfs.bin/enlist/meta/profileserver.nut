from "%enlSqGlob/ui_library.nut" import *

let { request } = require("%enlist/profileServer/profileServer.nut")
let eventbus = require("eventbus")

let function sendResult(data, id) {
  eventbus.send("profile_srv.response", {data, id})
}

let cleanKeys = ["method", "params", "token"]

let function handleMessages(msg) {
  let { id, data } = msg
  let { method, params = null, token = null } = data
  let args = clone data
  cleanKeys.each(@(key) key in args ? delete args[key] : null)
  request(method, params, args, id, @(result) sendResult(result, id), token)
}


eventbus.subscribe("profile_srv.request", handleMessages)
