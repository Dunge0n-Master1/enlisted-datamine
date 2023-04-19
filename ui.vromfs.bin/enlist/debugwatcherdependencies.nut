let logW = require("%enlSqGlob/library_logs.nut").with_prefix("[WatchedDep] ")
let { Watched } = require("frp")

let function dumpListeners(watched, prefix="") {
  let listeners = watched.dbgGetListeners()
  let { watchers, subscribers } = listeners
  logW($"{prefix}{watched.tostring()}")
  logW($"{prefix}{watchers.len()} watchers:")
  let childPrefix = $"{prefix}  "
  foreach (w in watchers) {
    if (w instanceof Watched)
      dumpListeners(w, childPrefix)
    else
      logW($"{childPrefix}{w.tostring()}")
  }
  logW($"{prefix}{subscribers.len()} subscriber(s)")
}

return dumpListeners