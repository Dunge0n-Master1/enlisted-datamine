from "%enlSqGlob/ui_library.nut" import *

let { fontBody, fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, activeTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { doBuyUnlock, unlockPrices } = require("taskRewardsState.nut")
let { mkRewardImages, prepareRewards, mkRewardTooltip } = require("%enlist/battlepass/rewardsPkg.nut")
let { cardCountCircle, imageSize, gapCards } = require("%enlist/battlepass/bpPkg.nut")
let { withTooltip } = require("%ui/style/cursors.nut")
let rewardsItemsMapping = require("%enlist/items/itemsMapping.nut")
let { curArmy } = require("%enlist/soldiers/model/state.nut")
let { commonArmy } = require("%enlist/meta/profile.nut")

let mkRewardsCards = @(rewards) {
  flow = FLOW_HORIZONTAL
  margin = [fsh(2), 0, fsh(2), 0]
  gap = gapCards
  children = rewards.map(function(rewardData) {
    let { count, reward } = rewardData
    return {
      children = [
        withTooltip(mkRewardImages(reward, imageSize), @() mkRewardTooltip(reward))
        cardCountCircle(count)
      ]
    }
  })
}

let mkRewardName = function(reward, otherArmy) {
  let armyName = loc($"{reward?.armyId ?? commonArmy.value}/full")
  return otherArmy
    ? $"{armyName}: {loc(reward.name)}"
    : loc(reward.name)
}

let function mkRewardsView(task) {
  let { lastRewardedStage, stages } = task
  let { rewards = null } = stages?[lastRewardedStage]

  if (rewards == null)
    return null

  return function() {
    let countAll = rewards.len()
    let possibleArmies = ["", curArmy.value, commonArmy.value]
    let viewRewards = prepareRewards(rewards, rewardsItemsMapping.value)
      .filter(@(r) r != null)
    let rewardsForArmy = viewRewards
      .filter(@(r) possibleArmies.contains(r?.reward.armyId ?? "") )

    local otherArmy = false
    local countForArmy = rewardsForArmy.len()
    if (countForArmy == 0) {
      otherArmy = true
      countForArmy = 1
      rewardsForArmy.append(viewRewards[0])
    }

    let otherArmiesTxt = countForArmy == countAll ? null : {
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      rendObj = ROBJ_TEXT
      text = loc("unlocks/eventMoreRewards", { count = countAll - countForArmy })
      color = activeTxtColor
    }.__update(fontBody)

    let children = []
    let { name = "" } = task?.localization
    if (name != "")
      children.append({
        rendObj = ROBJ_TEXT
        text = name
        color = defTxtColor
      }.__update(fontSub))

    let cards = mkRewardsCards(rewardsForArmy)
    children.append(cards)

    if (countForArmy == 1) {
      let mainReward = rewardsForArmy[0].reward
      if ("name" in mainReward)
        children.append({
          rendObj = ROBJ_TEXT
          text = mkRewardName(mainReward, otherArmy)
          color = activeTxtColor
        }.__update(fontBody))
      children.append(otherArmiesTxt)

      if ("description" in mainReward)
        children.append({
          size = [flex(), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc(mainReward.description)
          color = defTxtColor
        }.__update(fontSub))
    } else {
      children.append(otherArmiesTxt)
    }

    return {
      watch = [rewardsItemsMapping, curArmy, commonArmy]
      size = [flex(), SIZE_TO_CONTENT]
      halign = ALIGN_CENTER
      flow = FLOW_VERTICAL
      gap = hdpx(10)
      children
    }
  }
}

let function buyUnlockMsg(task) {
  let { currency = "", price = 0 } = unlockPrices.value?[task.name]
  if (price <= 0 || currency == "")
    return

  purchaseMsgBox({
    price
    currencyId = currency
    title = loc("unlocks/buyNextEventTask")
    productView = mkRewardsView(task)
    purchase = @() doBuyUnlock(task.name)
    alwaysShowCancel = true
    srcComponent = "buy_next_event_unlock"
  })
}

return buyUnlockMsg