from "%enlSqGlob/ui_library.nut" import *

let { fontHeading2 } = require("%enlSqGlob/ui/fontsStyle.nut")
let {registerUrl} = require("%enlist/login/ui/loginUiParams.nut")
let { get_setting_by_blk_path } = require("settings")
let { smallPadding, titleTxtColor, accentColor } = require("%enlSqGlob/ui/viewConst.nut")
let faComp = require("%ui/components/faComp.nut")
let openUrl = require("%ui/components/openUrl.nut")

if (!(get_setting_by_blk_path("gaijin_net_login") ?? true))
  return null

let function text(str) {
  return {
    rendObj = ROBJ_TEXT
    text = str
    color = titleTxtColor
  }.__update(fontHeading2)
}

let normalColor = accentColor
let hoverColor = Color(255, 168, 0)
let activeColor = Color(200, 100, 0)

let login = {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_IMAGE
      image = Picture("!ui/uiskin/gaijin_logo.avif")
      size = [hdpx(32), hdpx(32)]
    }
    text(loc("login/login"))
  ]
}

let color = @(sf) sf & S_ACTIVE ? activeColor
  : sf & S_HOVER ? hoverColor
  : normalColor

let registrationBtn = watchElemState(@(sf){
  flow = FLOW_HORIZONTAL
  behavior = Behaviors.Button
  valign = ALIGN_BOTTOM
  hplace = ALIGN_RIGHT
  gap = smallPadding
  onClick = @() openUrl(registerUrl)
  children = [
    {
      rendObj = ROBJ_TEXT
      text = loc("login/registration")
      color = color(sf)
    }.__update(fontHeading2)
    faComp("external-link", {color  = color(sf), fontSize = hdpx(17)})
  ]
})


return {
  size = [flex(), SIZE_TO_CONTENT]
  valign = ALIGN_CENTER
  padding = [hdpx(20), 0]
  children =  [
    login
    registrationBtn
  ]
}