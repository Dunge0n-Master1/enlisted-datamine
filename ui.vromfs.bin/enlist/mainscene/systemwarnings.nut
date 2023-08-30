from "%enlSqGlob/ui_library.nut" import *

let { isRunningOnPS5 = @() false } = require_optional("sony")
let { is_ps4 } = require("%dngscripts/platform.nut")
let { attentionTxtColor, transpBgColor, bigPadding } = require("%enlSqGlob/ui/designConst.nut")
let { fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")


let messagesList = [
  { locId = "ps5_update_request", showFunc = @() is_ps4 && isRunningOnPS5(), maxWidth = hdpx(500) }
]

let getMessageBlock = @(data) {
  size = SIZE_TO_CONTENT
  rendObj = ROBJ_SOLID
  color = transpBgColor
  padding = bigPadding
  children = {
    size = SIZE_TO_CONTENT
    maxWidth = data?.maxWidth ?? hdpx(700)
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    text = loc(data.locId)
    halign = ALIGN_CENTER
    color = attentionTxtColor
  }.__update(fontBody)
}

return {
  size = SIZE_TO_CONTENT
  flow = FLOW_VERTICAL
  gap = bigPadding
  hplace = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = messagesList.filter(@(data) data.showFunc()).map(getMessageBlock)
}