from "%enlSqGlob/ui_library.nut" import *

let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { colFull, transpPanelBgColor, midPadding, smallPadding, accentColor,
  darkPanelBgColor, colPart, defItemBlur, defTxtColor, brightAccentColor,
  bigPadding, hoverSlotBgColor, darkTxtColor, highlightLineHgt
} = require("%enlSqGlob/ui/designConst.nut")
let { mkColoredGradientX, mkTwoSidesGradientX } = require("%enlSqGlob/ui/gradients.nut")
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
let { data } = require("%enlist/debriefing/debriefingStateInMenu.nut")
let { dbgData } = require("%enlist/debriefing/debriefingDbgState.nut")


const CAMPAIGN_CHANGE_UID = "cangeCampaignUid"

let campaignBlockHeight = colFull(1)

let highlightLine = freeze({
  rendObj = ROBJ_IMAGE
  size = [flex(), highlightLineHgt]
  image = mkTwoSidesGradientX({centerColor = 0x5AFFFFFF, sideColor = 0x00FFFFFF, width=12, isAlphaPremultiplied=false})
})

let function mkCampaignButton(textObs, hasNotifierObs) {
  let function onClick() {
    if (canChangeCampaign.value)
      campaignSelectWnd.open()
    else
      msgbox.show({ text = loc("quickMatch/squadLeaderParams") })
  }
  return watchElemState(@(sf){
    rendObj = ROBJ_WORLD_BLUR_PANEL
    behavior = Behaviors.Button
    onClick
    watch = [textObs, hasNotifierObs]
    size = flex()
    halign = ALIGN_CENTER
  //  valign = ALIGN_BOTTOM
    color = defItemBlur
    fillColor = sf & S_HOVER ? hoverSlotBgColor : transpPanelBgColor
    children = [
      highlightLine
      {
        rendObj = ROBJ_TEXT
        hplace = ALIGN_CENTER
        vplace = ALIGN_CENTER
        padding = [smallPadding, 0]
        text = loc(textObs.value)
        color = sf & S_HOVER ? darkTxtColor : defTxtColor
      }.__update(fontLarge)
      !hasNotifierObs.value ? null : blinkUnseen
    ]
  })
}

let armyProgressToShow = {}
let function updateProgressAnim(debriefing) {
  let { armyExp = 0, armyWasExp = 0, armyWasLevel = 0, armyProgress = null } = debriefing
  if (armyProgress == null)
    return

  let { expToArmyLevel = [] } = armyProgress

  let expToNextLevel = expToArmyLevel?[armyWasLevel] ?? expToArmyLevel.top() ?? 0
  let wasProgress = expToNextLevel > 0 ? armyWasExp.tofloat() / expToNextLevel : 1
  let hasNewLevel = armyWasExp + armyExp >= expToNextLevel

  armyProgressToShow.__update({ wasProgress, armyWasLevel, hasNewLevel })
}

foreach (v in [data, dbgData])
  v.subscribe(updateProgressAnim)


let progressBarBgImage = mkColoredGradientX({colorLeft=0xFFFC7A40, colorRight=brightAccentColor})

let function mkCampaignBlock() {
  let campaignName = Computed(function() {
    let campaign = curCampaign.value
    return gameProfile.value?.campaigns[campaign].title ?? campaign
  })
  let progress = Computed(function() {
    let expToNextLevel = curArmyLevels.value?[curArmyLevel.value].expSize ?? 0
    return expToNextLevel > 0
      ? curArmyExp.value.tofloat() / expToNextLevel
      : 1
  })

  let needNotifier = Computed(@() maxCampaignLevel.value >= 4
    && unseenCampaigns.value.len() > 0)
  let progressCmp = @() {
    watch = progress
    size = [flex(), SIZE_TO_CONTENT]
    children = gradientProgressBar(progress.value, {
      vplace = ALIGN_BOTTOM
      bgImage = progressBarBgImage
      emptyColor = darkPanelBgColor
    }, armyProgressToShow)
  }

  return {
    size = [colPart(5), campaignBlockHeight]
    gap = midPadding
    flow = FLOW_VERTICAL
    hplace = ALIGN_CENTER
    children = [
      mkCampaignButton(campaignName, needNotifier)
      progressCmp
    ]
  }
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
      color = defTxtColor
    }.__update(fontLarge)
  }
}


let function campaignTitle() {
  return {
    size = [colFull(4), SIZE_TO_CONTENT]
    padding = [bigPadding, 0, 0, 0]
    gap = midPadding
    hplace = ALIGN_CENTER
    children = [
      levelBlock
      mkCampaignBlock()
    ]
  }
}

return campaignTitle
