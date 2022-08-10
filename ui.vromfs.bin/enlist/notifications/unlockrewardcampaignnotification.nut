from "%enlSqGlob/ui_library.nut" import *

let { MsgMarkedText }  = require("%ui/style/colors.nut")
let itemMapping = require("%enlist/items/itemsMapping.nut")
let { unlockRewardsInProgress } = require("%enlSqGlob/userstats/userstat.nut")
let { activeUnlocks, unlockProgress } = require("%enlSqGlob/userstats/unlocksState.nut")
let { unlockedCampaigns } = require("%enlist/meta/campaigns.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { curCampaign, setCurCampaign } = require("%enlist/meta/curCampaign.nut")
let { showMsgbox } = require("%enlist/components/msgbox.nut")
let colorize = require("%ui/components/colorize.nut")


let waitForUnlockReward = Watched({})

unlockRewardsInProgress.subscribe(function(v) {
  foreach (id, _ in v) {
    let { lastRewardedStage = -1 } = unlockProgress.value?[id]
    if (lastRewardedStage >= 0)
      waitForUnlockReward.mutate(@(v) v[id] <- lastRewardedStage) //warning disable: -iterator-in-lambda
  }
})

let function getRewardCampaigns(id, lastRewardedStage) {
  let { rewards = {} } = activeUnlocks.value?[id].stages[lastRewardedStage - 1]
  let res = {}
  foreach (key, _ in rewards) {
    let { armyId = "" } = itemMapping.value?[key.tostring()]
    let campaign = gameProfile.value?.campaignByArmyId[armyId]
    if (unlockedCampaigns.value.contains(campaign))
      res[campaign] <- true
  }
  return res
}

let function showUnlockRewardMsgBox(id, lastRewardedStage) {
  let campaigns = getRewardCampaigns(id, lastRewardedStage)
  if (campaigns.len() == 0 || curCampaign.value in campaigns)
    return
  let campaign = campaigns.keys()[0]
  showMsgbox({
    uid = "unlockRewardNotification"
    text = loc("msg/receivedRewardForOtherCampaign", {
      campaign = colorize(MsgMarkedText, loc(gameProfile.value?.campaigns[campaign].title ?? campaign))
    })
    buttons = [
      { text = loc("Ok"),
        action = @() setCurCampaign(campaign)
        isCurrent = true
      }
      { text = loc("Cancel")
        isCancel = true
      }
    ]
  })
}

unlockProgress.subscribe(function(v) {
  let idsToRemove = []
  foreach (id, prevStage in waitForUnlockReward.value) {
    let { lastRewardedStage = -1 } = v?[id]
    if (prevStage >= lastRewardedStage)
      continue
    idsToRemove.append(id)
    showUnlockRewardMsgBox(id, lastRewardedStage)
  }

  if (idsToRemove.len() > 0)
    waitForUnlockReward.mutate(@(wr) idsToRemove.each(@(id) delete wr[id]))
})