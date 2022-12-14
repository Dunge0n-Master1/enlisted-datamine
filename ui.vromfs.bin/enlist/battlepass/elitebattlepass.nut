from "%enlSqGlob/ui_library.nut" import *

let { seasonIndex, premiumUnlock } = require("%enlist/unlocks/taskRewardsState.nut")
let { purchaseInProgress } = require("%enlist/shop/armyShopState.nut")
let { purchasesCount } = require("%enlist/meta/profile.nut")
let { unlockProgress } = require("%enlSqGlob/userstats/unlocksState.nut")
let { shopItemsBase, shopItems } = require("%enlist/shop/shopItems.nut")


let elitePassItem = Computed(@() shopItems.value
  .findvalue(@(i) i?.prempass_active_stat_season == seasonIndex.value))

let isDebugBP = mkWatched(persist, "isDebugBP", false)
let hasEliteBattlePassBase = Computed(function() {
  let purchases = purchasesCount.value
  let season = seasonIndex.value
  return shopItemsBase.value
    .findvalue(@(item, guid) item?.prempass_active_stat_season == season && (purchases?[guid].amount ?? 0) > 0)
    != null
})

let eliteBpUnlockId = Computed(@() premiumUnlock.value?.requirement)
let premRewardsAllowed = Computed(@() eliteBpUnlockId.value == null
  || (unlockProgress.value?[eliteBpUnlockId.value].isFinished ?? false))

let hasEliteBattlePass = Computed(function() {
  let res = hasEliteBattlePassBase.value || premRewardsAllowed.value
  return isDebugBP.value ? !res : res
})

let isPurchaseBpInProgress = Computed(@() elitePassItem.value != null
  && purchaseInProgress.value == elitePassItem.value)

let canBuyBattlePass = Computed(@() !hasEliteBattlePass.value && elitePassItem.value != null)

console_register_command(@() isDebugBP(!isDebugBP.value), "meta.debugBattlePass")

return {
  canBuyBattlePass
  hasEliteBattlePass
  premRewardsAllowed
  isPurchaseBpInProgress
  elitePassItem
}