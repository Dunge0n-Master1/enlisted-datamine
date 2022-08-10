let eventbus = require("eventbus")
let {log} = require("%sqstd/log.nut")()
let { Watched } = require("frp")

let sharedData = {}
let NOT_INITED = {}
let dataVersion = persist("SharedWatchedVersions", @() {})
let lockSharing = {}

let function sendForeign(event, data) {
  try {
    eventbus.send_foreign(event, data)
  } catch (err) {
    log($"eventbus.send_foreign('{event}') failed")
    log(err)
    throw err?.errMsg ?? "Unknown error"
  }
}

let function make(name, ctor) {
  if (name in sharedData) {
    assert(false, $"sharedWatched: duplicate name: {name}")
    return sharedData[name]
  }

  dataVersion[name] <- dataVersion?[name] ?? 0
  let res = persist(name, @() Watched(NOT_INITED))
  sharedData[name] <- res
  if (res.value == NOT_INITED) {
    res(ctor())
    dataVersion[name] = -1
    sendForeign("sharedWatched.requestData", { name })
  }

  res.subscribe(function(value) {
    if (name in lockSharing)
      return

    let version = max(0, dataVersion[name]) + 1
    dataVersion[name] = version
    sendForeign("sharedWatched.update", { name, value, version })
  })

  return res
}

eventbus.subscribe("sharedWatched.update",
  function(msg) {
    let { name, value, version } = msg
    if (name in sharedData && dataVersion[name] < version) {
      lockSharing[name] <- true
      dataVersion[name] = version
      sharedData[name](value)
      delete lockSharing[name]
    }
  })

eventbus.subscribe("sharedWatched.requestData",
  function(msg) {
    let { name } = msg
    if (name in sharedData)
      sendForeign("sharedWatched.update", {
        name
        value = sharedData[name].value
        version = max(0, dataVersion[name])
      })
  })

return make