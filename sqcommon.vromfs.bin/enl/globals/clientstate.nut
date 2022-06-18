from "%enlSqGlob/ui_library.nut" import *

let { get_app_id } = require("app")
let { getCurrentLanguage } = require("dagor.localize")
let sharedWatched = require("%dngscripts/sharedWatched.nut")

let language = sharedWatched("language", getCurrentLanguage)
let appId = mkWatched(persist, "appId", get_app_id())

return {
  language
  appId
}
