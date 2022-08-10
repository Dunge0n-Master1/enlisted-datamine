from "%enlSqGlob/ui_library.nut" import *

let { activeUnlocks, unlockProgress, emptyProgress
} = require("%enlSqGlob/userstats/unlocksState.nut")
let { seasonRewards, updateSeasonRewards, userstatDescList
} = require("%enlSqGlob/userstats/userstat.nut")
let { hasLbHistory } = require("%enlist/leaderboard/lbState.nut")

let REWARD_UNLOCK = "unlock"
let REWARD_LB = "leaderboard"

let lbRewardsTypes = ["tillPlaces", "tillPercent"]

userstatDescList.subscribe(function(v) {
  if (v.len() > 0)
    updateSeasonRewards()
})

let function getSubArray(tbl, id) {
  if (id not in tbl)
    tbl[id] <- []
  return tbl[id]
}

let eventRewardsUnlocks = Computed(function() {
  let res = {}
  foreach (unlock in activeUnlocks.value) {
    let { events_lb_rewards = null } = unlock?.meta
    if (events_lb_rewards == null)
      continue
    getSubArray(res, events_lb_rewards).append(
      unlock.__merge({ rType = REWARD_UNLOCK }, unlockProgress.value?[unlock.name] ?? emptyProgress))
  }
  return res
})

let mkLbUnlocksStages = {}

lbRewardsTypes.each(function(rType) {
  mkLbUnlocksStages[rType] <- function(rewardCfg) {
    let rewards = rewardCfg?[rType] ?? {}
    if (rewards.len() == 0)
      return null
    let stages = []
    rewards.each(@(r, place) stages.append({ progress = place.tointeger(), rewards = r.itemdefids }))
    //progress = -1: any place
    return stages.sort(@(a, b) b.progress < 0 <=> a.progress < 0 || b.progress <=> a.progress)
  }
})

let lbRewards = Computed(function() {
  let res = {}
  let showPrevSeasonRewards = hasLbHistory.value
  let rewardsBase = showPrevSeasonRewards
    ? seasonRewards.value?.previous
    : seasonRewards.value?.current
  foreach (rewardsBlock in rewardsBase ?? []) {
    let { index = 1, modes = [], category = "", rewards = [] } = rewardsBlock
    let lbUnlockBase = {
      season = index
      category
      rType = REWARD_LB
      stages = []
    }
    foreach (modeId in modes) {
      let resModeUnlocks = getSubArray(res, modeId)
      foreach (rewardCfg in rewards)
        foreach (name, mkStages in mkLbUnlocksStages) {
          let stages = mkStages(rewardCfg)
          if (stages != null)
            resModeUnlocks.append(lbUnlockBase.__merge({ name, stages }))
        }
    }
  }
  return res
})

let function mergeTblArrays(t1, t2) {
  let res = {}
  foreach (key, list in t1)
    res[key] <- clone list
  foreach (key, list in t2)
    if (key in res)
      res[key].extend(list)
    else
      res[key] <- clone list
  return res
}

let allEventRewards = Computed(@() mergeTblArrays(eventRewardsUnlocks.value, lbRewards.value))

return {
  REWARD_UNLOCK
  REWARD_LB
  eventRewardsUnlocks
  lbRewards
  lbRewardsTypes

  allEventRewards
}