from "%enlSqGlob/ui_library.nut" import *

let { json_to_string } = require("json")
let { add_bigquery_record, send_to_server } = require("onlineStorage")
let { startSendToSrvTimer, sendToServer } = require("onlineSettings.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")

let isInstantSendToServer = mkWatched(persist, "isInstantSend", false)
let alreadySend = mkWatched(persist, "alreadySend", {})

let sendRecordToServer = @() isInstantSendToServer.value ? send_to_server() : startSendToSrvTimer()

userInfo.subscribe(function(uInfo) {
  if (uInfo == null)
    alreadySend.mutate(@(v) v.clear())
})

let wrapToString = @(val) typeof val == "string" ? val : json_to_string(val, false)

local function sendOncePerSession(event, params = null, uid = null) {
  uid = uid ?? event
  if (uid in alreadySend.value)
    return
  alreadySend.mutate(@(val) val[uid] <- true)
  add_bigquery_record(event, wrapToString(params ?? ""))
  sendRecordToServer()
}

let function sendEvent(event, params = null) {
  add_bigquery_record(event, wrapToString(params ?? ""))
  sendRecordToServer()
}

console_register_command(
  function() {
    sendToServer()
    isInstantSendToServer(!isInstantSendToServer.value)
    log("isInstantSendToServer = ", isInstantSendToServer.value)
  },
  "bigQuery.instantSend")

return {
  bqSendOncePerSession = sendOncePerSession
  bqSendEvent = sendEvent
}