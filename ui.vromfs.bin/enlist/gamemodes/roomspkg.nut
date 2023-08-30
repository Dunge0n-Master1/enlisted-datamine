from "%enlSqGlob/ui_library.nut" import *

let { defTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let faComp = require("%ui/components/faComp.nut")
let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { lockIconSize } = require("eventModeStyle.nut")


let txt = @(text, width = flex(), color = defTxtColor) {
    size = [width, SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXT
    color
    text
  }.__update(fontSub)

let textArea = @(text, params = {}) {
    size = [flex(), SIZE_TO_CONTENT]
    rendObj = ROBJ_TEXTAREA
    behavior = Behaviors.TextArea
    color = defTxtColor
    text
  }.__update(fontSub, params)

let lockIcon = faComp("lock", {
    fontSize = lockIconSize
    valign = ALIGN_CENTER
  })

let smallCampaignIcon = @(campaign, color = 0x40404040) faComp("circle", {
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    fontSize = fontSub.fontSize + hdpx(8)
    color
    children = {
      pos = array(2, hdpx(1))
      rendObj = ROBJ_TEXT
      color = 0xFFFFFFFF
      text = loc($"{campaign}/short")
    }.__update(fontSub)
  })


let mkIcon = @(icon, size){
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture($"{icon}:{size}:{size}:K")
  color = defTxtColor
}


let iconInBattle = mkIcon("!ui/uiskin/status/in_battle_status.svg", lockIconSize)
let iconPreparingBattle = mkIcon("!ui/uiskin/status/not_ready_status.svg", lockIconSize)
let iconMod = mkIcon("!ui/uiskin/mod_icon.svg", lockIconSize)


return {
  txt
  textArea
  lockIcon
  smallCampaignIcon
  iconInBattle
  iconPreparingBattle
  iconMod
}