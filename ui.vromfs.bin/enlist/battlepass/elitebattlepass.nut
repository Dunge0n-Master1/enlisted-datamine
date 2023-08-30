from "%enlSqGlob/ui_library.nut" import *

let { seasonIndex, premiumUnlock } = require("%enlist/unlocks/taskRewardsState.nut")
let { purchaseInProgress } = require("%enlist/shop/armyShopState.nut")
let { unlockProgress } = require("%enlSqGlob/userstats/unlocksState.nut")
let { shopItems } = require("%enlist/shop/shopItems.nut")
let { userstatStats } = require("%enlSqGlob/userstats/userstat.nut")

const PREMPASS_STAT = "prempass_active_stat_s{0}"

let elitePassItem = Computed(@() shopItems.value
  .findvalue(@(i) i?.prempass_active_stat_season == seasonIndex.value))

let isDebugBP = mkWatched(persist, "isDebugBP", false)
let hasEliteBattlePassBase = Computed(@()
  (userstatStats.value?.stats.battle_pass.main_game[PREMPASS_STAT.subst(seasonIndex.value)] ?? 0) > 0)

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