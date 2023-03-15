from "%enlSqGlob/ui_library.nut" import *

let JB = require("%ui/control/gui_buttons.nut")
let { fontXXLarge, fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { colFull, panelBgColor, midPadding, smallPadding, accentColor, titleTxtColor,
  colPart, topWndBgColor, bottomWndBgColor, defVertGradientImg, hoverVertGradientImg
} = require("%enlSqGlob/ui/designConst.nut")
let { mkColoredGradientY, mkColoredGradientX } = require("%enlSqGlob/ui/gradients.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let campaignSelectWnd = require("%enlist/campaigns/chooseCampaignWnd.nut")
let { gradientProgressBar } = require("%enlSqGlob/ui/defcomponents.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { curCampaign, canChangeCampaign } = require("%enlist/meta/curCampaign.nut")
let { unseenCampaigns } = require("unseenCampaigns.nut")
let { blinkUnseen } = require("%ui/components/unseenComponents.nut")
let { curArmyLevel, curArmyExp, curArmyLevels
} = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { maxCampaignLevel } = require("%enlist/soldiers/model/state.nut")
let { safeAreaVerPadding } = require("%enlSqGlob/safeArea.nut")


let faComp = require("%ui/components/faComp.nut")
let colorize = require("%ui/components/colorize.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let { jumpToArmyProgress } = require("%enlist/mainMenu/sectionsState.nut")


const CAMPAIGN_CHANGE_UID = "cangeCampaignUid"
let showExpandedButtons = Watched(false)
let campaignBlockHeight = colPart(1.162)
let toggleButtonsShowing = @() showExpandedButtons(!showExpandedButtons.value)
let wndGradient = mkColoredGradientY(topWndBgColor, bottomWndBgColor)
let campaignBtnHeight = campaignBlockHeight + midPadding

let expandAnimation = [ { prop = AnimProp.translate, duration = 2, easing = InOutCubic } ]
let expandedPosition = { translate = [0, campaignBtnHeight] }
let dropDownAnim = [
  { prop = AnimProp.translate, from = [0, -sh(20)], to = expandedPosition.translate,
    duration = 0.2, easing = InOutCubic, play = true }
]

let largeTxtStyle = {
  color = titleTxtColor
}.__update(fontLarge)


let needNotifier = Computed(@() maxCampaignLevel.value >= 4
  && unseenCampaigns.value.len() > 0)

let campaignButtons = [
  {
    text = loc("campaign/progress")
    action = function() {
      jumpToArmyProgress()
      toggleButtonsShowing()
      modalPopupWnd.remove(CAMPAIGN_CHANGE_UID)
    }
  }
  {
    text = loc("btn/changeCampaign")
    action = function(){
      toggleButtonsShowing()
      if (canChangeCampaign.value)
        campaignSelectWnd.open()
      else
        msgbox.show({ text = loc("quickMatch/squadLeaderParams") })
      modalPopupWnd.remove(CAMPAIGN_CHANGE_UID)
    }
  }
]


let campaignButton = @(text, hasNotifier, sf) {
  rendObj = ROBJ_IMAGE
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  image = sf & S_HOVER ? hoverVertGradientImg : defVertGradientImg
  padding = [smallPadding, 0]
  children = [
    {
      rendObj = ROBJ_IMAGE
      size = flex()
      opacity = 0.8
      image = Picture("!ui/uiskin/campaign/campaign_button_bg.svg")
    }
    {
      rendObj = ROBJ_TEXT
      text = loc(text)
    }.__update(largeTxtStyle)
    !hasNotifier ? null : blinkUnseen
  ]
}


let progressBarBgImage = mkColoredGradientX(0xFFFC7A40, accentColor)

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
      emptyColor = panelBgColor
    })
  ]
}

let arrowsStyle = {
  margin = 0
  fontSize = fontXXLarge.fontSize
  color = titleTxtColor
  hplace = ALIGN_CENTER
}


let function levelBlock(sf) {
  let curLevel = curArmyLevel.value
  let levelText = loc("levelInfo", { level = colorize(accentColor, curLevel) })
  return @() {
    watch = curArmyLevel
    key = "campaignLevelBlock"
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    halign = ALIGN_CENTER
    transform = expandedPosition
    transitions = expandAnimation
    animations =[
      { prop = AnimProp.translate, from = [0, -sh(20)], to = expandedPosition.translate,
        duration = 0.2, easing = InOutCubic, play = true }
    ]
    children = [
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = levelText
      }.__update(largeTxtStyle)
      !(sf & S_HOVER) ? null : faComp("angle-down", arrowsStyle)
    ]
  }
}


let bottomBlock = @(sf) @(){
  watch = showExpandedButtons
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  children = showExpandedButtons.value ? null : levelBlock(sf)
}


let function mkCampaignInfo() {
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


  return watchElemState(@(sf){
    size = [colFull(4), campaignBlockHeight]
    behavior = Behaviors.Button
    gap = midPadding
    onClick = function() {
      modalPopupWnd.add([sw(50), -campaignBtnHeight], {
        uid = CAMPAIGN_CHANGE_UID
        rendObj = ROBJ_IMAGE
        image = wndGradient
        size = [sw(100), sh(100)]
        padding = [campaignBtnHeight + safeAreaVerPadding.value, 0,0,0]
        animations = dropDownAnim
        transform = expandedPosition
        transitions = expandAnimation
        halign = ALIGN_CENTER
        flow = FLOW_VERTICAL
        gap = midPadding
        onDetach = toggleButtonsShowing
        children = campaignButtons.map(@(btn) Bordered(btn.text, btn.action, { btnWidth = colFull(4) }))
      })
      toggleButtonsShowing()
    }
    hotkeys = !showExpandedButtons.value ? []
      : [[$"^{JB.B} | Esc", { action = toggleButtonsShowing}]]
    hplace = ALIGN_CENTER
    children = [
      bottomBlock(sf)
      campaignBlock(campaignName, progress, sf)
    ]
  })
}


return mkCampaignInfo
