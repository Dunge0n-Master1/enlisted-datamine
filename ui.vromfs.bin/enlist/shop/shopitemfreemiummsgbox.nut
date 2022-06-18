from "%enlSqGlob/ui_library.nut" import *

let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { curCampaign  } = require("%enlist/meta/curCampaign.nut")
let msgbox = require("%ui/components/msgbox.nut")
let freemiumWnd = require("%enlist/currency/freemiumWnd.nut")

let function shopItemFreemiumMsgBox(cb = @() null) {
  let campaign = loc(gameProfile.value?.campaigns[curCampaign.value].title
    ?? curCampaign.value)
  msgbox.show({
    text = loc("freemium/buyFullVersion", { campaign })
    buttons = [
      { text = loc("Ok"), isCancel = true}
      { text = loc("freemium/getPack"), action = function() {
        freemiumWnd()
        cb()
      }}
    ]
  })
}

return shopItemFreemiumMsgBox