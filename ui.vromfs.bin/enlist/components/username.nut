from "%enlSqGlob/ui_library.nut" import *

let { body_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let { defTxtColor, defBgColor } = require("%enlSqGlob/ui/viewConst.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let { is_xbox } = require("%dngscripts/platform.nut")

let userName = @() {
  rendObj = ROBJ_TEXT
  text = userInfo.value?.nameorig ?? ""
  watch = userInfo
  color = defTxtColor
}.__update(body_txt)

let userIcon = faComp("user", {
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  margin = hdpx(2)
  color = defTxtColor
})

let widgetUserName = is_xbox ? {
  rendObj = ROBJ_SOLID
  hplace = ALIGN_RIGHT
  vplace = ALIGN_BOTTOM
  padding = [fsh(1), fsh(2)]
  gap = fsh(1)
  color = defBgColor
  flow = FLOW_HORIZONTAL
  children = [
    userIcon
    userName
  ]
} : null

return {
  userName
  widgetUserName
}
