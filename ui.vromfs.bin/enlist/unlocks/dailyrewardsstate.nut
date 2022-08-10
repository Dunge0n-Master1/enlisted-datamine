from "%enlSqGlob/ui_library.nut" import *

let {
  unlockRewardsInProgress, markUserLogsAsSeen
} = require("%enlSqGlob/userstats/userstat.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { doReceiveRewards } = require("taskRewardsState.nut")
let {
  newItemsToShow, markNewItemsSeen
} = require("%enlist/soldiers/model/newItemsToShow.nut")

let { getStageByIndex } = require("%enlSqGlob/unlocks_utils.nut")
let {
  activeUnlocks, unlockProgress, emptyProgress, unlockLogs
} = require("%enlSqGlob/userstats/unlocksState.nut")
let itemMapping = require("%enlist/items/itemsMapping.nut")
let { dailyTasks } = require("%enlist/unlocks/taskListState.nut")


const LOGIN_UNLOCK_ID = "every_day_award"
let specialUnlocks = ["every_day_award_100_days_in_row", "every_day_award_365_days_in_row",
  "every_day_award_730_days_in_row"]

let isReceiveDayRewardInProgress = Computed(@()
  unlockRewardsInProgress.value?[LOGIN_UNLOCK_ID] ?? false)

let specialUnlock = Computed(@() specialUnlocks.findvalue(@(u)
  (unlockProgress.value?[u].isCompleted ?? false)
    && !(unlockProgress.value?[u].isFinished ?? true))
)
let specialUnlockToReceive = Watched(null)

let dailyRewardsUnlock = Computed(@() activeUnlocks.value?[LOGIN_UNLOCK_ID]
  .__merge(unlockProgress.value?[LOGIN_UNLOCK_ID] ?? emptyProgress))

let dailyRewardsCrates = Computed(function() {
  let curArmyId = curArmy.value
  if (curArmyId == null)
    return []

  let rewardsItems = itemMapping.value
  let res = {}
  foreach (stage in dailyRewardsUnlock.value?.stages ?? [])
    foreach (rewardId, _ in stage?.rewards ?? {}) {
      let {
        armyId = "", crateId = ""
      } = rewardsItems?[rewardId.tostring()]
      if (crateId != "")
        res[crateId] <- {
          armyId = armyId != "" ? armyId : curArmyId
          id = crateId
        }
    }

  return res.values()
})

let function getCurLoginUnlockStage(unlock) {
  let { lastRewardedStage = 0, stages = [] } = unlock
  return stages.len() == 0 ? null
    : getStageByIndex(unlock, lastRewardedStage - 1)
}

let receivedDailyReward = Computed(function() {
  let curArmyId = curArmy.value
  if (curArmyId == null)
    return null

  let { allItems = [] } = newItemsToShow.value
  let receivedItems = allItems.filter(@(item) "basetpl" in item)
  if (receivedItems.len() == 0)
    return null

  return {
    curArmyId
    receivedItems
  }
})

let function calcRewardCfg(stageData, rewardsItems, cratesComp, curArmyId) {
  let rewardsData = []
  let rewardCrate = Watched(null)
  foreach (rewardId, _ in stageData?.rewards ?? {}) {
    let rewardCfg = rewardsItems?[rewardId.tostring()]
    if (rewardCfg == null)
      continue

    rewardsData.append(rewardCfg)
    local { armyId = "", crateId = "" } = rewardCfg
    if (crateId != "") {
      armyId = armyId != "" ? armyId : curArmyId
      rewardCrate({
        armyId
        id = crateId
        content = cratesComp?[crateId][armyId]
      })
    }
  }
  return {
    rewardsData
    rewardCrate
  }
}

let function getStageRewardsData(rewards, mappedItems, cratesComp, armyId) {
  let itemsData = {}
  let crates = []
  foreach (rewardId, count in rewards) {
    if (count <= 0)
      continue

    let presentanion = mappedItems?[rewardId.tostring()]
    if (presentanion == null)
      continue

    let { itemTemplate = "", crateId = "" } = presentanion
    if (itemTemplate != "") {
      if (itemTemplate not in itemsData)
        itemsData[itemTemplate] <- { count, presentanion }
      else
        itemsData[itemTemplate].count += count
    }
    if (crateId != "")
      crates.append(crateId)
  }

  let cratesContent = {}
  foreach (crateId in crates)
    foreach (itemTemplate, count in (cratesComp?[crateId][armyId].items ?? [])) {
      let presentanion = mappedItems.findvalue(@(pres) pres?.itemTemplate == itemTemplate)
      cratesContent[itemTemplate] <- { count, itemTemplate, presentanion }
    }

  return {
    crates
    cratesContent
    itemsData
  }
}

let boosterLogs = Computed(@() (unlockLogs.value ?? [])
  .filter(@(log) log.type == "ADD_BOOSTER"))

let curBoosteredDailyTask = Computed(function() {
  let tasks = dailyTasks.value ?? []
  let logs = boosterLogs.value.filter(@(log)
    tasks.findvalue(@(u) u.name == log.unlock) != null)

  if (logs.len() == 0)
    return null

  let boosterLog = logs.top()
  return tasks.findvalue(@(u) u.name == boosterLog.unlock)
    .__merge({ boosterLog })
})

let function markBoosterLogsSeen() {
  let userlogs = boosterLogs.value.map(@(b) b.id)
  if (userlogs.len() > 0)
    markUserLogsAsSeen(userlogs)
}

let function receiveDayReward() {
  if (isReceiveDayRewardInProgress.value)
    return
  doReceiveRewards(LOGIN_UNLOCK_ID)
}

let function gotoNextStageOrClose(receivedData, closeCb) {
  let { hasRewards = false, hasBoosters = false } = receivedData
  if (hasRewards)
    markNewItemsSeen()
  if (hasBoosters)
    markBoosterLogsSeen()

  if (!(dailyRewardsUnlock.value.hasReward ?? false)){
    closeCb()
    if (specialUnlock.value != null){
      specialUnlockToReceive(specialUnlock.value)
      doReceiveRewards(specialUnlock.value)
    }
  }
}

let function imitateCrateReward(boostersData, receivedItems, mappedItems, rType = "hasBoosters") {
  let res = {
    itemsData = {}
    cratesContent = {}
    crateItemsData = {}
  }.__update({ [rType] = true })

  foreach (booster in boostersData)
    foreach (boosterPack in booster)
      foreach (mappedItem, count in boosterPack.items) {
        let presentanion = mappedItems?[mappedItem]
        if (presentanion == null)
          continue

        let itemTemplate = presentanion?.itemTemplate
        if (itemTemplate == null)
          continue

        res.cratesContent[itemTemplate] <- { itemTemplate, count, presentanion }
      }

  foreach (receivedItem in receivedItems) {
    let { basetpl, count } = receivedItem
    res.crateItemsData[basetpl] <- {
      count
      itemTemplate = basetpl
    }
  }

  return res
}

return {
  dailyRewardsUnlock
  dailyRewardsCrates
  receivedDailyReward
  calcRewardCfg
  getStageRewardsData
  receiveDayReward
  gotoNextStageOrClose
  curBoosteredDailyTask
  isReceiveDayRewardInProgress
  markBoosterLogsSeen
  imitateCrateReward
  getCurLoginUnlockStage
  specialUnlock
  specialUnlockToReceive
}
