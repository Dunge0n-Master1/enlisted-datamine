from "%enlSqGlob/ui_library.nut" import *

let { get_app_id } = require("app")
let { getCurrentLanguage } = require("dagor.localize")

let appId = mkWatched(persist, "appId", get_app_id())
let gameLanguage = getCurrentLanguage()

return {
  appId
  gameLanguage
}
