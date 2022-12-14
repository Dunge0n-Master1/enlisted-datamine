from "%enlSqGlob/ui_library.nut" import *

let {
  basicProgress, premiumProgress, combinedUnlocks, nextStage, nextRewardStage,
  progressCounters, currentProgress
} = require("bpState.nut")
let itemMapping = require("%enlist/items/itemsMapping.nut")
let { hasEliteBattlePass } = require("eliteBattlePass.nut")
let { getOneReward } = require("rewardsPkg.nut")

let curItem = mkWatched(persist, "curItem", null)
let isOpened = mkWatched(persist, "isOpened", false)

enum RewardState {
  COMPLETED = 0
  IN_PROGRESS = 1
  INACTIVE = 2
  ACQUIRED = 3
}

let unlockToShow = Computed(@() progressCounters.value.isCompleted
  ? combinedUnlocks.value
  : combinedUnlocks.value.slice(0, progressCounters.value.total))

let getOneRewardByStageData = @(stageData, mappedItems = {})
  getOneReward(stageData?.rewards ?? stageData?.currencyRewards ?? {}, mappedItems)

let combinedRewards = Computed(function(){
  let { current, required, interval } = currentProgress.value
  let mappedItems = itemMapping.value

  let basicRewarded = basicProgress.value.lastRewardedStage
  let premiumRewarded = premiumProgress.value.lastRewardedStage
  let isBasicDone = basicProgress.value.isFinished || basicProgress.value.isCompleted
  let isPremiumDone =  premiumProgress.value.isFinished || premiumProgress.value.isCompleted
  let isLastRewardDone = isBasicDone || isPremiumDone

  return unlockToShow.value.map(function(stageData, stageIdx) {
    let { stage, isPremium = false } = stageData
    let { reward = null, count = 0 } = getOneRewardByStageData(stageData, mappedItems)
    let isReceived = (isPremium ? premiumRewarded : basicRewarded) > stage
    local progressVal = null
    local progressState = null
    if (stageIdx == nextRewardStage.value && isLastRewardDone)
      progressState = RewardState.COMPLETED
    else if (stageIdx < nextStage.value)
      progressState = isPremium && !hasEliteBattlePass.value
        ? RewardState.INACTIVE
        : RewardState.ACQUIRED
    else {
      progressVal = stageIdx == nextStage.value && interval != 0
        ? (current - required + interval).tofloat() / interval
        : 0
      progressState = RewardState.IN_PROGRESS
    }
    return { reward, count, stageIdx, isPremium, isReceived, progressState, progressVal }
  })
})

let function getRewardIdx(rewardTemplate = ""){

  local rewardIdx = null
  local state = null
  foreach (idx, r in combinedRewards.value){
    if (r.reward?.itemTemplate == rewardTemplate) {
      if (r.progressState == RewardState.COMPLETED)
        return idx
      if ((r.progressState == RewardState.IN_PROGRESS && state != RewardState.IN_PROGRESS)
          || (r.progressState == RewardState.INACTIVE && state == null)) {
        state = r.progressState
        rewardIdx = idx
      }
    }
  }
  return rewardIdx
}

let function curItemUpdate(rewardIdx = null){
  rewardIdx = rewardIdx ?? nextRewardStage.value ?? nextStage.value
  curItem({
    reward = getOneRewardByStageData(combinedUnlocks.value?[rewardIdx])?.reward
    stageIdx = rewardIdx
  })
}

let function openBPwindow(rewardIdx = null){
  curItemUpdate(rewardIdx)
  isOpened(true)
}

return {
  RewardState
  unlockToShow
  combinedRewards
  isOpened
  getRewardIdx
  openBPwindow
  curItem
  curItemUpdate
}