from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { textColor, TextActive } = require("%ui/style/colors.nut")
let textButtonTextCtor = require("%ui/components/textButtonTextCtor.nut")
let { sendBigQueryUIEvent } = require("%enlist/bigQueryEvents.nut")
let premiumWnd = require("%enlist/currency/premiumWnd.nut")
let { premiumImage } = require("%enlist/currency/premiumComp.nut")

let function activatePremiumText(sf) {
  let bonus = gameProfile.value?.premiumBonuses.soldiersReserve ?? 0
  return {
    flow = FLOW_HORIZONTAL
    valign = ALIGN_CENTER
    margin = [hdpx(8), hdpx(20), hdpx(8), hdpx(50)]
    gap = hdpx(10)
    children = [
      {
        rendObj = ROBJ_TEXT
        color = textColor(sf, false, TextActive)
        text = loc("btn/reserveSize", {addSize = bonus})
      }.__update(h2_txt)
      premiumImage(hdpx(30))
    ]
  }
}

let activatePremiumBttn = {
  customStyle = {
    textCtor = function(textComp, params, handler, group, sf) {
      textComp = activatePremiumText(sf)
      params = h2_txt
      return textButtonTextCtor(textComp, params, handler, group, sf)
    }
  }
  action = function() {
    premiumWnd()
    sendBigQueryUIEvent("open_premium_window", "army_shop", "reserve_full_message")
  }
}

return activatePremiumBttn