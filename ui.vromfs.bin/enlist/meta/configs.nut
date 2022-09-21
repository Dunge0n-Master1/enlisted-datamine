from "%enlSqGlob/ui_library.nut" import *

let json = require("%sqstd/json.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let {nestWatched} = require("%dngscripts/globalState.nut")

let serverConfigs = nestWatched("serverConfig", {})

let function updateAllConfigs(newValue) {
  let { configs = null } = newValue
  if (configs)
    serverConfigs(configs)
}
serverConfigs.whiteListMutatorClosure(updateAllConfigs)

let function dumpConfig() {
  let { userId = -1 } = userInfo.value
  if (userId < 0)
    return

  let path = $"enlisted_config_{userId}.json"
  json.save(path, serverConfigs.value, { logger = log_for_user })
  console_print($"Current configuration saved to {path}")
}

console_register_command(dumpConfig, "meta.dumpConfig")

return {
  configs = serverConfigs
  updateAllConfigs
}
