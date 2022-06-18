from "%enlSqGlob/ui_library.nut" import *

let { strip } = require("string")
let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let { getStageByIndex } = require("%enlSqGlob/unlocks_utils.nut")
let {
  activeUnlocks, unlockProgress, emptyProgress, allUnlocks
} = require("%enlSqGlob/userstats/unlocksState.nut")
let {
  receiveUnlockRewards, buyUnlock, userstatUnlocks, userstatExecutors, userstatStats
} = require("%enlSqGlob/userstats/userstat.nut")

let rewardsInProgress = Watched({})
let purchaseInProgress = Watched({})

let mkUnlockId = @(flag) Computed(@() activeUnlocks.value.findindex(@(unlock) unlock?.meta[flag] ?? false))
let basicUnlockId = mkUnlockId("monthly_challenges_common") // TODO make enlisted specific naming of tags
let premiumUnlockId = mkUnlockId("monthly_challenges_premium")
let premiumStage0UnlockId = mkUnlockId("monthly_challenges_stage_0_premium")

let basicUnlock = Computed(@() activeUnlocks.value?[basicUnlockId.value])
let premiumUnlock = Computed(@() activeUnlocks.value?[premiumUnlockId.value])
let premiumStage0Unlock = Computed(@() (activeUnlocks.value?[premiumStage0UnlockId.value] ?? {})
  .__merge(unlockProgress.value?[premiumStage0UnlockId.value] ?? emptyProgress))
let basicProgress = Computed(@() unlockProgress.value?[basicUnlockId.value] ?? emptyProgress)
let premiumProgress = Computed(@() unlockProgress.value?[premiumUnlockId.value] ?? emptyProgress)
let nextBasicStage = Computed(@() getStageByIndex(basicUnlock.value, basicProgress.value.lastRewardedStage))
let nextPremiumStage = Computed(@() getStageByIndex(premiumUnlock.value, premiumProgress.value.lastRewardedStage))

let servProgress = Computed(@() userstatUnlocks.value?.unlocks ?? {})

let seasonIndex = Computed(@()
  userstatStats.value?.stats[basicUnlock.value?.table]["$index"] ?? 0)

let hasBattlePass = Computed(@() basicUnlockId.value != null)

let timeLeft = Computed(function() {
  let time = userstatStats.value?.stats[basicUnlock.value?.table]["$endsAt"].tointeger() ?? 0
  return max(time - serverTime.value, 0)
})

let topStageProgress = @(arr) arr && arr.len() > 0 ? arr.top().progress : 0
let taskRewardsCounters = Computed(function() {
  let basic = basicUnlock.value
  let basicStages = basic?.stages
  let loopIndex = (basic?.startStageLoop ?? 1) - 1
  let total = ((basic?.periodic ?? false) ? loopIndex : null)
    ?? basic?.meta.finalMainReward // left for backward compatibility
    ?? max(topStageProgress(basicStages), topStageProgress(premiumUnlock.value?.stages))
  let current = min(total, basicProgress.value.stage)
  let loop = (basicStages?.len() ?? 1) - loopIndex
  return { current, total, loop }
})

let mkPrice = @(price = 0, currency = "") { currency, price }

let unlockPrices = Computed(function() {
  let res = {}
  foreach (unlockName, data in servProgress.value) {
    let price = data?.price ?? 0
    if (price > 0)
      res[unlockName] <- mkPrice(price, data?.currencyCode ?? "")
  }
  foreach (unlockName, unlock in allUnlocks.value) {
    if (unlockName in res)
      continue
    let idx = servProgress.value?[unlockName].stage ?? 0
    let data = unlock?.stages[idx]
    let price = data?.price ?? 0
    if (price > 0)
      res[unlockName] <- mkPrice(price, data?.currencyCode ?? "")
  }
  return res
})

let mkRequirements = memoize(@(reqStr) reqStr.split("&").map(@(v) strip(v)).filter(@(v) v!=""))

let function doReceiveRewards(unlockName) {
  if (unlockName == null || unlockName in rewardsInProgress.value)
    return
  let progressData = servProgress.value?[unlockName]
  let stage = progressData?.stage ?? 0
  let lastReward = progressData?.lastRewardedStage ?? 0
  let requirement = allUnlocks.value?[unlockName].requirement ?? ""
  let requirements = mkRequirements(requirement)
  foreach (req in requirements){
    let {isCompleted} = unlockProgress.value?[req] ?? emptyProgress
    if (!isCompleted){
      log($"Can't receiveRewards results for '{unlockName}' due to incomplete requirements. Not completed unlock: '{req}'")
      return
    }
  }

  if (lastReward < stage) {
    rewardsInProgress.mutate(@(v) v[unlockName] <- stage)
    receiveUnlockRewards(unlockName, stage, {executeAfter="EN.receiveRewards", unlockName})
  }
}

assert("EN.receiveRewards" not in userstatExecutors)
userstatExecutors["EN.receiveRewards"] <- function(_result, context) {
  let { unlockName = null } = context
  if (unlockName == null)
    return "Error: No 'unlockName' in context"

  log($"receiveRewards {unlockName}", rewardsInProgress.value)
  rewardsInProgress.mutate(@(v) delete v[unlockName])
  return $"delete rewardsInProgress['{unlockName}']"
}

let getUnlockPrice = @(unlockName) unlockPrices.value?[unlockName] ?? mkPrice()

let function doBuyUnlock(unlockName, cb = null) {
  if (!unlockName || unlockName in purchaseInProgress.value) {
    log($"buyUnlock ignore {unlockName} because already in progress")
    return
  }
  let curUnlock = allUnlocks.value?[unlockName]
  let stageDesc = servProgress.value?[unlockName] ?? {}
  let stage = (stageDesc?.stage ?? 0) + 1
  let totalStages = curUnlock?.stages.len() ?? 0
  let price = getUnlockPrice(unlockName)
  log($"buyUnlock {unlockName} at {stage}/{totalStages} for {price.price}{price.currency} stage:", stageDesc)
  if ((stage <= totalStages || curUnlock?.periodic == true) && price.price > 0) {
    purchaseInProgress.mutate(@(v) v[unlockName] <- stage)
    buyUnlock(unlockName, stage, price.currency, price.price, function(res) {
      log($"buyUnlock {unlockName} at {purchaseInProgress.value?[unlockName]} results:", res)
      purchaseInProgress.mutate(@(v) delete v[unlockName])
      cb?(res)
    })
  }
}

console_register_command(@() doBuyUnlock(basicUnlockId.value, console_print), "unlocks.buyBasic")
console_register_command(@()
  console_print($"{basicUnlockId.value}:", basicProgress.value, $"{premiumUnlockId.value}:", premiumProgress.value),
  "unlocks.rewardsProgress")

return {
  timeLeft
  seasonIndex
  basicUnlockId
  basicUnlock
  premiumUnlockId
  premiumUnlock
  premiumStage0Unlock
  basicProgress
  premiumProgress
  nextBasicStage
  nextPremiumStage
  taskRewardsCounters
  unlockPrices
  rewardsInProgress
  purchaseInProgress
  hasBattlePass
  doReceiveRewards
  doBuyUnlock
}