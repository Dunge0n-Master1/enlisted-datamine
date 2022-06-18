from "%enlSqGlob/ui_library.nut" import *

let steam = require("steam")
let { isSteamRunning } = require("%enlSqGlob/login_state.nut")
let circuitConf = require("app").get_circuit_conf()

let function getShopUrl() {
  if (!isSteamRunning.value)
    return circuitConf?.shopUrl
  let url = circuitConf?.shopUrlSteam
  return url ? url.subst({ appId = steam.get_app_id(), steamId = steam.get_my_id() }) : null
}

let function getUrlByGuid(guid) {
  let url  = isSteamRunning.value
    ? circuitConf?.shopGuidUrlSteam
    : circuitConf?.shopGuidUrl
  if (!url || !guid.len())
    return null
  let params = { guid = guid }
  if (isSteamRunning.value)
    params.__update({ appId = steam.get_app_id(), steamId = steam.get_my_id() })
  return url.subst(params)
}

return {
  getShopUrl
  getUrlByGuid
}