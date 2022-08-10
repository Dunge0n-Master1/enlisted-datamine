from "%enlSqGlob/ui_library.nut" import *

let { debounce } = require("%sqstd/timers.nut")
let {
  timeLeft, basicUnlockId, basicUnlock, basicProgress, premiumUnlockId, premiumUnlock,
  premiumProgress, hasBattlePass, unlockPrices,
  rewardsInProgress, purchaseInProgress, doReceiveRewards, doBuyUnlock,
  nextBasicStage, nextPremiumStage, seasonIndex
} = require("%enlist/unlocks/taskRewardsState.nut")
let { hasEliteBattlePass, premRewardsAllowed } = require("eliteBattlePass.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")

const BP_PREMIUM_STAT = "battle_pass_stage"

let combinedUnlocks = Computed(function() {
  let basicRewards = basicUnlock.value?.stages ?? []
  let premRewards = premiumUnlock.value?.stages ?? []
  local premIdx = 0
  local premProgress = 0
  let res = []
  foreach (basicStage, basic in basicRewards) {
    foreach (stat in basic?.updStats ?? []){
      premProgress += stat?.name == BP_PREMIUM_STAT ? (stat?.value ?? 0).tointeger() : 0
    }
    res.append(basic.__merge({
      stage = basicStage
    }))
    for (local premStage = premIdx; premStage < premRewards.len(); ++premStage) {
      let premium = premRewards[premStage]
      if (premium.progress > premProgress)
        break
      res.append(premium.__merge({
        stage = premStage
        isPremium = true
      }))
      ++premIdx
    }
  }
  return res
    .map(function(r) {
      let rewards = r?.rewards ?? {}
      if ("currencyRewards" in r) {
        rewards.__update(r.currencyRewards)
        delete r.currencyRewards
      }
      if (rewards.len() > 0)
        r.rewards <- rewards.map(@(val) val.tointeger())
      return r
    })
    .filter(@(r) r?.rewards != null)
})

let combinedUnlocksGrid = Computed(function() {
  local lastIdx = 0
  local lastProgress = 0
  local stepProgress = 0
  let res = array(combinedUnlocks.value.len())
  foreach (idx, unlock in combinedUnlocks.value)
    if (!(unlock?.isPremium ?? false)) {
      let { progress } = unlock
      if (idx == lastIdx) {
        res[idx] = progress
      } else {
        stepProgress = (progress - lastProgress).tofloat() / (idx - lastIdx)
        for (local i = lastIdx; i <= idx; ++i)
          res[i] = (lastProgress + (i - lastIdx) * stepProgress + 0.5).tointeger()
      }
      lastIdx = idx
      lastProgress = progress
    }
  for (; lastIdx < res.len(); ++lastIdx) {
    res[lastIdx] = lastProgress.tointeger()
    lastProgress += stepProgress
  }
  return res
})

let function calcUnlockRatio(unlocksGrid, progress, minProgress = 0.0) {
  let length = unlocksGrid.len()
  if (length < 1)
    return 0.0

  let index = unlocksGrid.findindex(@(p) p >= progress)
  if (index == null)
    return 1.0

  let prev = unlocksGrid?[index - 1].tofloat() ?? minProgress
  let curr = unlocksGrid[index].tofloat()
  return min((index + (progress - prev).tofloat() / (curr - prev)) / length, 1.0)
}

let clampStage = @(stage, total, full) stage < full ? stage
  : full > total ? total + (stage - total) % (full - total)
  : full - 1

let function clampProgress(grid, total, progress) {
  if (grid.len() == 0 || total == 0)
    return progress

  let lastProgress = grid.top()
  if (progress < lastProgress)
    return progress

  let firstProgress = grid[total - 1]
  return firstProgress < lastProgress
    ? firstProgress + (progress - firstProgress) % (lastProgress - firstProgress)
    : lastProgress
}

let progressCounters = Computed(function() {
  let full = combinedUnlocks.value.len()
  let { startStageLoop = 0, periodic = false } = basicUnlock.value
  let loopIndex = startStageLoop - 1
  let loop = loopIndex >= 0 ? full - loopIndex : 0
  let total = periodic ? loopIndex : full
  let { current, lastRewardedStage } = basicProgress.value
  let stageCurrent = combinedUnlocksGrid.value.findindex(@(p) p > current) ?? full
  return {
    rewarded = max(lastRewardedStage, premiumProgress.value.lastRewardedStage)
    current = min(total, stageCurrent)
    total
    full
    loop
    isCompleted = stageCurrent >= total
  }
})

let currentProgress = Computed(function() {
  let { total, full } = progressCounters.value
  local { current, required, stage } = basicProgress.value
  stage = clampStage(stage, total, full)
  let interval = (combinedUnlocksGrid.value?[stage] ?? 0)
    - (combinedUnlocksGrid.value?[stage - 1] ?? 0)
  return {
    current = clamp(current, required - interval, required)
    required
    interval
  }
})

let currentUnlockRatio = Computed(function() {
  let { rewarded, total, full, loop, isCompleted } = progressCounters.value
  if (full == 0 || combinedUnlocksGrid.value.len() == 0)
    return {
      received = 0.0
      earned = 0.0
    }

  local { current } = basicProgress.value
  if (!isCompleted) {
    let earned = calcUnlockRatio(combinedUnlocksGrid.value.slice(0, total), current)
    let received = rewarded.tofloat() / total
    return {
      received
      earned = earned - received
    }
  }

  let received = clampStage(rewarded, total, full).tofloat() / full
  let first = combinedUnlocksGrid.value?[total - 1] ?? 0
  let diff = combinedUnlocksGrid.value.top() - first
  let progress = first + (rewarded - total) * diff / loop

  if (current > progress)
    return {
      received
      earned = 1.0 - received
    }

  current = clampProgress(combinedUnlocksGrid.value, total, current)
  return {
    received
    earned = calcUnlockRatio(combinedUnlocksGrid.value, current) - received
  }
})

let function isWorthlessReward(stage) {
  let { rewards = {}, currencyRewards = {} } = stage
  return rewards.len() == 0 && currencyRewards.len() == 0
}

let hasReward = Computed(@() basicProgress.value.hasReward
  || (hasEliteBattlePass.value && premiumProgress.value.hasReward))

let findStageIdx = @(stages, stageIdx, isPremium)
  stages.findindex(@(s) s.stage >= stageIdx && (s?.isPremium ?? false) == isPremium) //empty stages are filtered, so take first not empty stage

let nextRewardInfo = Computed(function() {
  let stages = combinedUnlocks.value
  local unlockId = null
  local stageIdx = null
  local isReadyToReceive = true
  let { total, full } = progressCounters.value
  if (basicProgress.value.hasReward && (!premiumProgress.value.hasReward || !premRewardsAllowed.value)) {
    unlockId = basicUnlockId.value
    stageIdx = findStageIdx(stages, clampStage(basicProgress.value.lastRewardedStage, total, full), false)
  } else if (premiumProgress.value.hasReward && hasEliteBattlePass.value) {
    unlockId = premiumUnlockId.value
    stageIdx = findStageIdx(stages, clampStage(premiumProgress.value.lastRewardedStage, total, full), true)
    isReadyToReceive = premRewardsAllowed.value
  }
  return { unlockId, stageIdx, isReadyToReceive }
})

let nextRewardStage = Computed(@() nextRewardInfo.value.stageIdx)
let nextStage = Computed(function() {
  let { rewarded, total, full } = progressCounters.value
  let res = clampStage(rewarded, total, full)
  return max(res, nextRewardStage.value ?? res) //no need to go before next reward while loop
})

let nextUnlock = Computed(@() combinedUnlocks.value?[nextStage.value])


let nextUnlockPrice = Computed(@() (basicProgress.value.hasReward
  || basicProgress.value.isFinished
  || !hasEliteBattlePass.value)
    ? null
    : unlockPrices.value?[basicUnlockId.value])

let receiveRewardInProgress = Computed(@() basicUnlockId.value in rewardsInProgress.value
  || premiumUnlockId.value in rewardsInProgress.value)

let buyUnlockInProgress = Computed(@() basicUnlockId.value in purchaseInProgress.value)

let function receiveNextReward() {
  let { unlockId, isReadyToReceive } = nextRewardInfo.value
  if (unlockId == null)
    return
  if (!isReadyToReceive)
    showMsgbox({ text = loc("msg/cantReceiveRewardsTryLater") })
  else
    doReceiveRewards(unlockId)
}

let function buyNextStage() {
  if (nextUnlockPrice.value)
    doBuyUnlock(basicUnlockId.value)
}

let curWorthlessRewardId = keepref(Computed(@() !hasReward.value || receiveRewardInProgress.value ? null
  : isWorthlessReward(nextPremiumStage.value) && hasEliteBattlePass.value ? premiumUnlockId.value
  : isWorthlessReward(nextBasicStage.value) ? basicUnlockId.value
  : null))

let tryReceiveReward = debounce(@(id) doReceiveRewards(id), 0.01)
curWorthlessRewardId.subscribe(tryReceiveReward)

return {
  timeLeft
  basicProgress
  premiumProgress
  combinedUnlocks
  currentUnlockRatio
  progressCounters
  currentProgress
  nextStage
  nextRewardStage
  nextUnlock
  hasReward
  hasBattlePass
  nextUnlockPrice
  receiveRewardInProgress
  buyUnlockInProgress
  receiveNextReward
  buyNextStage
  seasonIndex
}
