from "%enlSqGlob/ui_library.nut" import *

let { bqSendEvent } = require("options/bigQuery.nut")

let debugBigQuery = mkWatched(persist, "debugBigQuery", false)

let internalSend = @(event, params)
  debugBigQuery.value ? console_print($"bqSendEvent {event}", params) : bqSendEvent(event, params)

let function sendBigQueryUIEvent(eventType, srcWindow = null, srcComponent = null) {
  let params = { }
  if (srcWindow != null)
    params.source_window <- srcWindow
  if (srcComponent != null)
    params.source_component  <- srcComponent
  internalSend(eventType, params)
}

console_register_command(function() {
  let isDebug = !debugBigQuery.value
  console_print($"bqSendEvent debugging is {isDebug ? "ON" : "OFF"}")
  debugBigQuery(isDebug)
}, "debug.bqSendEvent_toggle")

return {
  sendBigQueryUIEvent
}