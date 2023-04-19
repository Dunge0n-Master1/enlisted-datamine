from "%enlSqGlob/ui_library.nut" import *

let msgbox = require("%ui/components/msgbox.nut")
let freemiumWnd = require("%enlist/currency/freemiumWnd.nut")
let { curCampaignLocId } = require("%enlist/meta/curCampaign.nut")

let function shopItemFreemiumMsgBox(cb = @() null) {
  let campaign = loc(curCampaignLocId.value)
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