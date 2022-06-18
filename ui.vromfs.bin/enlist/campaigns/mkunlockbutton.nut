from "%enlSqGlob/ui_library.nut" import *

let { PrimaryFlat } = require("%ui/components/textButton.nut")
let { shopItems } = require("%enlist/shop/shopItems.nut")
let buyShopItem = require("%enlist/shop/buyShopItem.nut")

let function mkUnlockBtn(lock, override = {}) {
  let { reqPurchase = null } = lock
  if (reqPurchase == null)
    return null
  return function() {
    let res = { watch = shopItems }
    let sItem = shopItems.value?[reqPurchase.findvalue(@(id) id in shopItems.value)]
    if (sItem == null)
      return res
    return res.__update({
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_CENTER
      stopHover = true
      children = PrimaryFlat(loc("btn/participate"),
        @() buyShopItem({ shopItem = sItem }),
        { hotkeys = [["^J:X"]] })
    }, override)
  }
}

return mkUnlockBtn