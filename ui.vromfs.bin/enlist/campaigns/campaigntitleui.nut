from "%enlSqGlob/ui_library.nut" import *

let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { colFull, transpPanelBgColor, midPadding, smallPadding, accentColor, titleTxtColor,
  darkPanelBgColor, colPart, defItemBlur, defTxtColor, miniPadding, briteAccentColor,
  hoverPanelBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { mkColoredGradientX, mkColoredGradientY } = require("%enlSqGlob/ui/gradients.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let campaignSelectWnd = require("%enlist/campaigns/chooseCampaignWnd.nut")
let { gradientProgressBar } = require("%enlSqGlob/ui/defComponents.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { curCampaign, canChangeCampaign } = require("%enlist/meta/curCampaign.nut")
let { unseenCampaigns } = require("unseenCampaigns.nut")
let { blinkUnseen } = require("%ui/components/unseenComponents.nut")
let { curArmyLevel, curArmyExp, curArmyLevels
} = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { maxCampaignLevel } = require("%enlist/soldiers/model/state.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let colorize = require("%ui/components/colorize.nut")


const CAMPAIGN_CHANGE_UID = "cangeCampaignUid"

let largeTxtStyle = { color = defTxtColor }.__update(fontLarge)
let hoverLargeTxtStyle = { color = titleTxtColor }.__update(fontLarge)

let campaignBlockHeight = colPart(1.162)

let needNotifier = Computed(@() maxCampaignLevel.value >= 4
  && unseenCampaigns.value.len() > 0)

let lineGradient = mkColoredGradientY(0x5AFFFFFF, 0x00FFFFFF, 12, false)
let thinLineWidth = colPart(0.054)
let wideLineWidth = colPart(0.084)

let highlightLine = @(width) {
  rendObj = ROBJ_IMAGE
  size = [width, flex()]
  image = lineGradient
}

let leftLinesBlock = {
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_HORIZONTAL
  gap = miniPadding
  hplace = ALIGN_LEFT
  children = [
    highlightLine(wideLineWidth)
    highlightLine(thinLineWidth)
  ]
}


let rightLinesBlock = {
  size = [SIZE_TO_CONTENT, flex()]
  flow = FLOW_HORIZONTAL
  gap = miniPadding
  hplace = ALIGN_RIGHT
  children = [
    highlightLine(thinLineWidth)
    highlightLine(wideLineWidth)
  ]
}


let campaignButton = @(text, hasNotifier, sf) {
  rendObj = ROBJ_WORLD_BLUR
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  color = defItemBlur
  fillColor = sf & S_HOVER ? hoverPanelBgColor : transpPanelBgColor
  children = [
    leftLinesBlock
    {
      rendObj = ROBJ_TEXT
      hplace = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      padding = [smallPadding, 0]
      text = loc(text)
    }.__update(sf & S_HOVER ? hoverLargeTxtStyle : largeTxtStyle)
    !hasNotifier ? null : blinkUnseen
    rightLinesBlock
  ]
}


let progressBarBgImage = mkColoredGradientX(0xFFFC7A40, briteAccentColor)

let campaignBlock = @(campaignName, progress, sf) @() {
  watch = [needNotifier, campaignName, progress]
  size = [colFull(4), campaignBlockHeight]
  gap = midPadding
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  children = [
    campaignButton(campaignName.value, needNotifier.value, sf)
    gradientProgressBar(progress.value, {
      vplace = ALIGN_BOTTOM
      bgImage = progressBarBgImage
      emptyColor = darkPanelBgColor
    })
  ]
}


let function levelBlock() {
  let curLevel = curArmyLevel.value
  let levelText = utf8ToUpper(loc("levelInfo", { level = colorize(accentColor, curLevel) }))
  return {
    watch = curArmyLevel
    key = "campaignLevelBlock"
    size = [flex(), SIZE_TO_CONTENT]
    pos = [0, campaignBlockHeight + midPadding]
    children = {
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      halign = ALIGN_CENTER
      size = [flex(), SIZE_TO_CONTENT]
      text = levelText
    }.__update(largeTxtStyle)
  }
}


let function campaignTitle() {
  let campaignName = Computed(function() {
    let campaign = curCampaign.value
    return gameProfile.value?.campaigns[campaign].title ?? campaign
  })
  let progress = Computed(function() {
    let expToNextLevel = curArmyLevels.value?[curArmyLevel.value].expSize ?? 0
    return expToNextLevel > 0
      ? curArmyExp.value.tofloat() / expToNextLevel
      : 100
  })


  return watchElemState(@(sf) {
    size = [colFull(4), SIZE_TO_CONTENT]
    gap = midPadding
    hplace = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = function() {
      if (canChangeCampaign.value)
        campaignSelectWnd.open()
      else
        msgbox.show({ text = loc("quickMatch/squadLeaderParams") })
    }
    children = [
      levelBlock
      campaignBlock(campaignName, progress, sf)
    ]
  })
}

return campaignTitle()
