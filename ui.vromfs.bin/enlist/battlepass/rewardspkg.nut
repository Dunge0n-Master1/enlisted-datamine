from "%enlSqGlob/ui_library.nut" import *

let { body_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let faComp = require("%ui/components/faComp.nut")
let {
  defTxtColor, activeTxtColor, accentTitleTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")
let { rewardWidthToHeight, rewardsPresentation } = require("%enlist/items/itemsPresentation.nut")
let { secondsToHoursLoc } = require("%ui/helpers/time.nut")
let tooltipBox = require("%ui/style/tooltipBox.nut")


let defCardSize = [hdpx(170), hdpx(210)]

let function prepareRewards(rewards, itemMapping = {}) {
  let list = []
  foreach (key, count in rewards) {
    let reward = itemMapping?[key.tostring()] ?? rewardsPresentation?[key.tostring()]
    if (reward != null && count.tointeger() > 0)
      list.append({ reward, count })
  }
  list.sort(@(a, b) (a?.worth ?? 0) <=> (b?.worth ?? 0))
  return list
}

// find most valuable reward that have presentation data
let getOneReward = @(rewards, itemMapping = {}) prepareRewards(rewards, itemMapping)?[0]

let function mkRewardIcon(reward, size = hdpx(30), override = {}) {
  let { icon = null } = reward
  if (icon == null)
    return null
  return {
    rendObj = ROBJ_IMAGE
    size = [size, size]
    image = Picture("{0}:{1}:{1}:K".subst(icon, size.tointeger()))
    keepAspect = true
  }.__update(override)
}

let function mkRewardImages(reward, sizeBg = defCardSize, override = {}) {
  let { cardImage = null, cardImageParams = {}, bgImage = null } = reward
  if (cardImage == null)
    return null

  let hasBg = bgImage != null
  return {
    rendObj = hasBg ? ROBJ_IMAGE : null
    size = sizeBg
    image = hasBg ? Picture(bgImage) : null
    children = type(cardImage) == "function" ? cardImage(sizeBg)
      : {
          rendObj = ROBJ_IMAGE
          image = Picture(cardImage)
        }.__update(cardImageParams)
  }.__update(override)
}

let function mkRewardText(reward, pxSize,  override = {}){
  let { cardText = null} = reward
  if (cardText == null)
    return null
  return {
    rendObj = ROBJ_BOX
    borderWidth = hdpx(1)
    children = {
      rendObj = ROBJ_TEXT
      fontSize = pxSize
      hplace = ALIGN_CENTER
      vplace = ALIGN_CENTER
      text = cardText
    }
  }.__update(override)
}

let mkSeasonTime = @(timeLeft, override = {}) {
  flow = FLOW_HORIZONTAL
  valign = ALIGN_CENTER
  gap = hdpx(2)
  children = [
    faComp("clock-o", {
      fontSize = hdpx(13)
      color = accentTitleTxtColor
    }.__update(override))
    {
      rendObj = ROBJ_TEXT
      text = secondsToHoursLoc(timeLeft)
      color = accentTitleTxtColor
    }.__update(sub_txt, override)
  ]
}

let function mkRewardTooltip(presentation) {
  let children = []
  if ("name" in presentation)
    children.append({
      rendObj = ROBJ_TEXT
      text = presentation.name
      color = activeTxtColor
    }.__update(body_txt))
  if ("description" in presentation)
    children.append({
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      maxWidth = hdpx(500)
      text = presentation.description
      color = defTxtColor
    }.__update(sub_txt))

  return children.len() == 0 ? null : tooltipBox({ flow = FLOW_VERTICAL, children })
}

return {
  getOneReward
  mkRewardIcon
  mkSeasonTime
  prepareRewards
  mkRewardImages
  mkRewardText
  rewardWidthToHeight
  mkRewardTooltip
  defCardSize
}
