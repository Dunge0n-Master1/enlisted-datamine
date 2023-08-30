from "%enlSqGlob/ui_library.nut" import *

let { hasNewbieUnlocksData } = require("%enlist/unlocks/unseenUnlocksState.nut")
let { mkOnlineSaveData } = require("%enlSqGlob/mkOnlineSaveData.nut")
let { markShopItemSeen } = require("unseenShopItems.nut")
let { curAvailableShopItems } = require("%enlist/shop/armyShopState.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")

let markedAllBundlesSeenTime = mkOnlineSaveData("markedArmyBundlesSeenTime", @() {})
curAvailableShopItems.subscribe(function(items) {
  let armyId = curArmy.value

  if (!hasNewbieUnlocksData.value && ((markedAllBundlesSeenTime.watch.value?[armyId] ?? 0) == 0)) {
    //Mark seen bundles only for old players once, so they won't
    // see many 'new' stuff. But keep show new bundles with notificaiton.
    let unseenGuids = items.filter(@(item)
      ((item?.shop_price ?? 0) > 0)
      || ((item?.curShopItemPrice.price ?? 0) > 0)
      || ((item?.curItemCost ?? {}).len() > 0)
    ).map(@(item) item.guid)
    if (unseenGuids.len()) {
      let savedTime = markedAllBundlesSeenTime.watch.value
      markedAllBundlesSeenTime.setValue(savedTime.__merge({[armyId] = serverTime.value}))
      markShopItemSeen(armyId, unseenGuids)
    }
  }
  else if (hasNewbieUnlocksData.value && armyId) {
    let savedTime = markedAllBundlesSeenTime.watch.value
    markedAllBundlesSeenTime.setValue(savedTime.__merge({[armyId] = serverTime.value}))
  }
})

console_register_command(@() markedAllBundlesSeenTime.setValue({}), "meta.resetSeenBundlesTime")