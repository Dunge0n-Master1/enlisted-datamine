let matching_api = require_optional("matching.api")
let eventbus = require("eventbus")

let subscriptions = {}

if (matching_api) {
  matching_api.listen_notify("mrpc.generic_notify")
  matching_api.listen_rpc("mrpc.generic_rpc")
}

eventbus.subscribe("mrpc.generic_notify", function(ev) {
  subscriptions?[ev?.from].each(@(handler) handler(ev))
})

eventbus.subscribe("mrpc.generic_rpc", function(reqctx) {
  matching_api?.send_response(reqctx, {})
  let ev = reqctx.request
  subscriptions?[ev?.from].each(@(handler) handler(ev))
})

let function subscribe(from, handler) {
  if (from not in subscriptions)
    subscriptions[from] <- []
  subscriptions[from].append(handler)
}

let function unsubscribe(from, handler) {
  if (from not in subscriptions)
    return
  let idx = subscriptions[from].indexof(handler)
  if (idx != null)
    subscriptions[from].remove(idx)
}

return {
  subscribe
  unsubscribe
}
