from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { defTxtColor, activeTxtColor } = require("%enlSqGlob/ui/viewConst.nut")
let { purchaseMsgBox } = require("%enlist/currency/purchaseMsgBox.nut")
let { doBuyUnlock, unlockPrices } = require("taskRewardsState.nut")
let { mkRewardImages, prepareRewards, mkRewardTooltip } = require("%enlist/battlepass/rewardsPkg.nut")
let { cardCountCircle, sizeCard, imageSize, gapCards } = require("%enlist/battlepass/bpPkg.nut")
let { withTooltip } = require("%ui/style/cursors.nut")


let mkRewardsCards = @(rewards) {
  flow = FLOW_HORIZONTAL
  margin = [fsh(2), 0, 0, 0]
  gap = gapCards
  children = rewards.map(function(rewardData) {
    let {count, reward} = rewardData
    return {
      size = sizeCard
      children = [
        withTooltip(mkRewardImages(reward, imageSize), @() mkRewardTooltip(reward))
        cardCountCircle(count)
      ]
    }
  })
}

let function mkRewardsView(task) {
  let children = []
  let { name = "" } = task?.localization
  if (name != "")
    children.append({
      rendObj = ROBJ_TEXT
      text = name
      color = defTxtColor
    }.__update(sub_txt))

  let { lastRewardedStage, stages } = task
  local { rewards = null } = stages?[lastRewardedStage]
  if (rewards) {
    rewards = prepareRewards(rewards).filter(@(r) r != null)
    let cards = mkRewardsCards(rewards)
    children.append(cards)

    if (rewards.len() == 1) {
      let mainReward = rewards[0].reward
      if ("name" in mainReward)
        children.append({
          rendObj = ROBJ_TEXT
          text = loc(mainReward.name)
          color = activeTxtColor
        }.__update(body_txt))

      if ("description" in mainReward)
        children.append({
          size = [flex(), SIZE_TO_CONTENT]
          halign = ALIGN_CENTER
          rendObj = ROBJ_TEXTAREA
          behavior = Behaviors.TextArea
          text = loc(mainReward.description)
          color = defTxtColor
        }.__update(sub_txt))
    }
  }

  return children.len() == 0 ? null : {
    size = [flex(), SIZE_TO_CONTENT]
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(10)
    children
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