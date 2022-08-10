from "%enlSqGlob/ui_library.nut" import *

let clickShopItem = require("%enlist/shop/clickShopItem.nut")
let { findSquadShopItem } = require("%enlist/shop/armyShopState.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let { armies } = require("%enlist/soldiers/model/state.nut")
let { buyRentedSquad } = require("%enlist/soldiers/model/squadInfoState.nut")


let function checkReqMsgbox(rentedSquadData = null) {
  let { armyId = null, squadId = null, hasMsgBox = false } = rentedSquadData
  if (armyId == null || squadId == null)
    return

  let shopItem = findSquadShopItem(armyId, squadId)
  if (shopItem == null) {
    showMsgbox({ text = loc("msg/rentedSquadLimits") })
    return
  }

  let armyLevel = armies.value?[armyId].level ?? 0
  if (hasMsgBox)
    showMsgbox({
      text = loc("msg/rentedSquadBuy")
      buttons = [
        { text = loc("btn/buy"), isCurrent = true, action = @() clickShopItem(shopItem, armyLevel) }
        { text = loc("OK"), isCancel = true }
      ]
    })
  else
    clickShopItem(shopItem, armyLevel)
}

buyRentedSquad.subscribe(checkReqMsgbox)
