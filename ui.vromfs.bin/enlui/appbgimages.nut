from "%enlSqGlob/ui_library.nut" import *

let {strip} = require("string")
let {get_setting_by_blk_path} = require("settings")

let appBgImages = (get_setting_by_blk_path("bgImage") ?? "")
  .split(";")
  .map(strip)
  .filter(@(v) v!="")

return {
  appBgImages = appBgImages
}
