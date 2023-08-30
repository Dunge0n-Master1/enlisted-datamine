from "%enlSqGlob/ui_library.nut" import *

let { saveJson, loadJson } = require("%sqstd/json.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let {nestWatched} = require("%dngscripts/globalState.nut")
let { disableNetwork } = require("%enlSqGlob/login_state.nut")
let eventbus = require("eventbus")
let serverConfigs = nestWatched("serverConfig", {})
let { set_huge_alloc_threshold } = require("dagor.memtrace")

const DISABLE_NETWORK_CONFIG = "disable_network_config.json"

if (disableNetwork) {
  let prevSize = set_huge_alloc_threshold(66560 << 10)
  serverConfigs(loadJson(DISABLE_NETWORK_CONFIG))
  set_huge_alloc_threshold(prevSize)
}

let function updateAllConfigs(newValue) {
  let { configs = null } = newValue
  if (configs && !disableNetwork)
    serverConfigs(configs)
}
serverConfigs.whiteListMutatorClosure(updateAllConfigs)

let function dumpConfig(name=null) {
  let { userId = -1 } = userInfo.value
  if (userId < 0 || name==null)
    return

  let path = name ?? $"enlisted_config_{userId}.json"
  saveJson(path, serverConfigs.value, { logger = log_for_user })
  console_print($"Current configuration saved to {path}")
}

const EVENT_SAVE_DISABLE_NETWORK_DATA = "meta.saveDisableNetworkData"

console_register_command(@() eventbus.send(EVENT_SAVE_DISABLE_NETWORK_DATA, null), EVENT_SAVE_DISABLE_NETWORK_DATA)
eventbus.subscribe(EVENT_SAVE_DISABLE_NETWORK_DATA, @(_) dumpConfig(DISABLE_NETWORK_CONFIG))

console_register_command(dumpConfig, "meta.dumpConfig")

return {
  configs = serverConfigs
  updateAllConfigs
  EVENT_SAVE_DISABLE_NETWORK_DATA
}
