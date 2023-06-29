from "%enlSqGlob/ui_library.nut" import *

let { fontSmall } = require("%enlSqGlob/ui/fontsStyle.nut")
let { accentColor, colPart, mkTimerIcon } = require("%enlSqGlob/ui/designConst.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { rewardsPresentation } = require("%enlist/items/itemsPresentation.nut")


let accentTxtStyle = { color = accentColor }.__update(fontSmall)
let timerSize = colPart(0.22)


let rewardIconWidth = colPart(0.68)


let function prepareRewards(rewards, itemMapping = {}) {
  let list = []
  foreach (key, count in rewards) {
    let reward = itemMapping?[key.tostring()] ?? rewardsPresentation?[key.tostring()]
    if (reward != null && count.tointeger() > 0)
      list.append({ reward, count })
  }
  return list
}


let getOneReward = @(rewards, itemMapping = {}) prepareRewards(rewards, itemMapping)?[0]


let function mkRewardIcon(reward, size = colPart(0.49), override = {}) {
  let { icon = null } = reward
  if (icon == null)
    return null
  return {
    rendObj = ROBJ_IMAGE
    size = [size, size]
    image = Picture("{0}:{1}:{1}:K".subst(icon, size.tointeger()))
    keepAspect = KEEP_ASPECT_FIT
  }.__update(override)
}

let mkSeasonTime = @(timeLeft, override = {}) {
  size = SIZE_TO_CONTENT
  flow = FLOW_HORIZONTAL
  valign = ALIGN_BOTTOM
  gap = colPart(0.033)
  children = [
    mkTimerIcon(timerSize, { color = accentColor })
    {
      rendObj = ROBJ_TEXT
      text = secondsToHoursLoc(timeLeft)
    }.__update(accentTxtStyle, override)
  ]
}


return {
  mkSeasonTime
  mkRewardIcon
  getOneReward
  rewardIconWidth
}
