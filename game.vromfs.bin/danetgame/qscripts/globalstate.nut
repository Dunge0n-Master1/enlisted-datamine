let eventbus = require("eventbus")
//let {logerr} = require("%sqstd/log.nut")()
let { Watched } = require("frp")
let { ndbWrite, ndbRead, ndbExists } = require("nestdb")
const EVT_NEW_DATA = "GLOBAL_PERMANENT_STATE.newDataAvailable"
let registered = {}

let function readNewData(name){
  if (name in registered) {
    let {key, watched} = registered[name]
    watched(ndbRead(key))
  }
//  else
//    println($"requested data for unknown subscriber '{name}'")
// it spamming too much, but without info about VM logs are useless
}

let function globalWatched(name, ctor=null) {
  assert(name not in registered, $"Global persistent state duplicate registration: {name}")
  let key = $"GLOBAL_PERSIST_STATE/{name}"
  local val
  if (ndbExists(key)) {
    val = ndbRead(key)
  }
  else {
    val = ctor?()
    ndbWrite(key, val)
  }
  let res = Watched(val)
  registered[name] <- {key, watched=res}
  let function update(value) {
    ndbWrite(key, value)
    res(value)
    eventbus.send_foreign(EVT_NEW_DATA, name)
  }
  res.whiteListMutatorClosure(readNewData)
  res.whiteListMutatorClosure(update)
  return {
    [name] = res,
    [$"{name}Update"] = update
  }
}

eventbus.subscribe(EVT_NEW_DATA, readNewData)

let usedKeys = {}

let function nestWatched(key, def=null){
  assert(key not in usedKeys, @() $"persistent {key} already registered")
  let ndbKey = $"PERSIST_STATE/{key}"
  local val
  if (ndbExists(ndbKey))
    val = ndbRead(ndbKey)
  else {
    val = def
    ndbWrite(ndbKey, val)
  }
  let res = Watched(val)
  res.subscribe(@(v) ndbWrite(ndbKey, v))
  usedKeys[key] <- true
  return res
}

return {
  globalWatched
  nestWatched
}