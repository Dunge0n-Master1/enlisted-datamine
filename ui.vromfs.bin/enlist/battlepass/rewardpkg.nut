from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { accentColor, mkTimerIcon, transpBgColor, defItemBlur, smallPadding
} = require("%enlSqGlob/ui/designConst.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let { rewardsPresentation } = require("%enlist/items/itemsPresentation.nut")
let { taskSlotPadding } = require("%enlSqGlob/ui/tasksPkg.nut")


let accentTxtStyle = { color = accentColor }.__update(fontSub)
let timerSize = hdpxi(13)
let rewardIconWidth = hdpxi(42)


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


let function mkRewardIcon(reward, size = hdpxi(30), override = {}) {
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
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = transpBgColor
  color = defItemBlur
  padding = taskSlotPadding
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = smallPadding
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
