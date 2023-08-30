from "%enlSqGlob/ui_library.nut" import *

let msgbox = require("%enlist/components/msgbox.nut")
let colorize = require("%ui/components/colorize.nut")
let { MsgMarkedText } = require("%ui/style/colors.nut")
let { mkOnlinePersistentFlag } = require("%enlist/options/mkOnlinePersistentFlag.nut")
let { squadsCfgById } = require("%enlist/soldiers/model/config/squadsConfig.nut")
let { getItemName } = require("%enlSqGlob/ui/itemsInfo.nut")
let {
  curArmyNextUnlockLevel, curArmySquadsUnlocks, curArmyLevelRewardsUnlocks,
  needUpdateCampaignScroll
} = require("%enlist/soldiers/model/armyUnlocksState.nut")
let {
  allItemTemplates, findItemTemplate
} = require("%enlist/soldiers/model/all_items_templates.nut")


let seenGetUnlockTutorial = mkOnlinePersistentFlag("hasSeenGetUnlockTutorial")
let hasSeenGetUnlockTutorial = seenGetUnlockTutorial.flag
let seenGetUnlockTutorialActivate = seenGetUnlockTutorial.activate

let nextTutorialUnlock = Computed(function() {
  if (hasSeenGetUnlockTutorial.value)
    return null

  let lvl = curArmyNextUnlockLevel.value
  let squadsUnlocks = curArmySquadsUnlocks.value
  let rewardsUnlocks = curArmyLevelRewardsUnlocks.value
  return squadsUnlocks.findvalue(@(v) v?.level == lvl)
    ?? rewardsUnlocks.findvalue(@(v) v?.level == lvl)
})

let function showGetUnlockTutorial(unlock) {
  let { armyId, level, unlockType, unlockId, rewardInfo = {} } = unlock
  local tutorialText = ""
  if (unlockType == "squad") {
    let titleLocId = squadsCfgById.value?[armyId][unlockId].titleLocId
    tutorialText = loc("getCampaignSquadTutorial", {
      level = colorize(MsgMarkedText, level)
      name = colorize(MsgMarkedText, loc(titleLocId))
    })
  }
  else if (unlockType == "level_reward") {
    let itemTpl = findItemTemplate(allItemTemplates, armyId, rewardInfo?.rewardId)
    tutorialText = loc("getCampaignSquadTutorial", {
      level = colorize(MsgMarkedText, level)
      name = colorize(MsgMarkedText, getItemName(itemTpl))
    })
  }
  else
    tutorialText = loc("hint/takeReward")

  msgbox.show({
    text = tutorialText
    buttons = [
      {
        text = loc("Ok")
        action = function() {
          seenGetUnlockTutorialActivate()
          needUpdateCampaignScroll(true)
        }
        isCurrent = true
      }
    ]
  })
}

return {
  nextTutorialUnlock
  showGetUnlockTutorial
  hasSeenGetUnlockTutorial
}
