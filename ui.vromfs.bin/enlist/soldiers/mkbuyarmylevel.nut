from "%enlSqGlob/ui_library.nut" import *

let { currencyBtn } = require("%enlist/currency/currenciesComp.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { buyArmyLevel } = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { sound_play } = require("%dngscripts/sound_system.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")

let function mkBuyArmyLevel(lvlToBuy, price, priceFull = null) {

  let function buyArmyLevelMsg() {
    purchaseMsgBox({
      price
      currencyId = "EnlistedGold"
      title = loc("armyLevel", { level = lvlToBuy + 1 })
      description = loc("buy/armyLevelConfirm")
      purchase = @() buyArmyLevel(function(isSuccess) {
        if (isSuccess)
          sound_play("ui/purchase_level_campaign")
      })
      srcComponent = "buy_campaign_level"
    })
  }

  return {
    size = [flex(), SIZE_TO_CONTENT]
    children = currencyBtn({
      btnText = utf8ToUpper(loc("squads/buyLvl", {
        item = utf8ToUpper(loc("squads/lvlShort", { level = lvlToBuy + 1 }))
      }))
      currencyId = "EnlistedGold"
      price
      priceFull
      cb = buyArmyLevelMsg
      style = {
        key = $"buyNextLvl{price}"
        hotkeys = [[ "^J:Y", { description = {skip=true}} ]]
        size = [flex(), hdpx(50)]
        margin = 0
        padding = 0
        stopHover = true
      }
    })
  }
}

return mkBuyArmyLevel