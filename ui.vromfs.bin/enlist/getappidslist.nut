let { get_app_id } = require("app")
let log = require("%sqstd/log.nut")()

let appIdsList = [get_app_id()]

let setAppIdsList = function(list) {
  log("[APP IDS] set list ", list)
  appIdsList.clear()
  appIdsList.extend(list)
}
let getAppIdsList = @() clone appIdsList

return { setAppIdsList, getAppIdsList }