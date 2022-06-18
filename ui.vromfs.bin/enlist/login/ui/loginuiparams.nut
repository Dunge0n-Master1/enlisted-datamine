from "%enlSqGlob/ui_library.nut" import *

let { get_setting_by_blk_path } = require("settings")
let auth  = require("auth")

local registerUrl = get_setting_by_blk_path("registerUrl") ?? "https://login.gaijin.net/profile/register"

let function addQueryParam(url, name, value) {
  let delimiter = url.contains("?") ? "&" : "?"
  return "".concat(url,delimiter, name, "=", value)
}

let distrStr = auth?.get_distr() ?? ""
if (distrStr != "") {
  registerUrl = addQueryParam(registerUrl, "distr", distrStr)
}

return {
  loginBlockOverride = Watched({
    size = [fsh(40), fsh(45)]
    hplace = ALIGN_RIGHT
    vplace = ALIGN_CENTER
  })
  infoBlock = Watched(null)
  registerUrl
}