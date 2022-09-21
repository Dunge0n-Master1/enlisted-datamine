from "%enlSqGlob/ui_library.nut" import *

let { fontXXLarge, fontSmall, fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let campaignSelectWnd = require("campaign_select_wnd.nut")
let { mkNotifierBlink } = require("%enlist/components/mkNotifier.nut")
let { progressBar } = require("%enlSqGlob/ui/defcomponents.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { curCampaign, canChangeCampaign } = require("%enlist/meta/curCampaign.nut")
let { unseenCampaigns } = require("unseenCampaigns.nut")
let {
  curArmyLevel, curArmyExp, curArmyLevels
} = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { maxCampaignLevel } = require("%enlist/soldiers/model/state.nut")
let { colFull, panelBgColor, midPadding, smallPadding, accentColor,
  titleTxtColor, defTxtColor, colPart
} = require("%enlSqGlob/ui/designConst.nut")
let faComp = require("%ui/components/faComp.nut")
let colorize = require("%ui/components/colorize.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let { setCurSection } = require("%enlist/mainMenu/sectionsState.nut")

let showExpandedButtons = Watched(false)
let campaignBlockHeight = colPart(1.162)
let toggleButtonsShowing = @() showExpandedButtons(!showExpandedButtons.value)
let campaignBgColor = 0xFF0A3550

let expandAnimation = [ { prop = AnimProp.translate, duration = 2, easing = InOutCubic } ]
let expandedPosition = { translate = [0, campaignBlockHeight + midPadding] }
let dropDownAnim = [
  { prop = AnimProp.translate, from = [0, -sh(20)], to = expandedPosition.translate,
    duration = 0.2, easing = InOutCubic, play = true }
]

let largeTxtStyle = {
  color = titleTxtColor
}.__update(fontLarge)

let smallTxtStyle = {
  color = defTxtColor
}.__update(fontSmall)


let needNotifier = Computed(@() maxCampaignLevel.value >= 4
  && unseenCampaigns.value.len() > 0)

let campaignButtons = [
  {
    text = loc("campaign/progress")
    action = function() {
      setCurSection("SQUADS")  /* FIX ME: Change to addsScene with camera (requires update of campaign wnd) */
      toggleButtonsShowing()
    }
  }
  {
    text = loc("btn/changeCampaign")
    action = function(){
      toggleButtonsShowing()
      if (canChangeCampaign.value)
        campaignSelectWnd.open()
      else
        msgbox.show({ text = loc("Only squad leader can change params") })
    }
  }
]


let campaignButton = @(text, sf) {
  rendObj = ROBJ_SOLID
  size = flex()
  halign = ALIGN_CENTER
  valign = ALIGN_BOTTOM
  color = (sf & S_HOVER) ? campaignBgColor : panelBgColor
  padding = [smallPadding, 0]
  children = {
    rendObj = ROBJ_TEXT
    text
  }.__update(largeTxtStyle)
}

let campaignBlock = @(campaignName, progress, sf) @() {
  watch = [needNotifier, campaignName, progress]
  size = [colFull(4), campaignBlockHeight]
  gap = midPadding
  flow = FLOW_VERTICAL
  hplace = ALIGN_CENTER
  children = [
    !needNotifier.value ? null
      : mkNotifierBlink(loc("hint/newCampaignAvailable"), {
        size = [flex(), SIZE_TO_CONTENT]
        minWidth = SIZE_TO_CONTENT
      }.__update(smallTxtStyle))
    campaignButton(campaignName.value, sf)
    progressBar(progress.value, {
      vplace = ALIGN_BOTTOM
      color = (sf & S_HOVER) ? campaignBgColor : panelBgColor
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



let function expandedButtons(sf){
  let buttons = campaignButtons.map(@(btn) Bordered(btn.text, btn.action, { btnWidth = colFull(4) }))
  if ((sf & S_HOVER) || (sf & S_ACTIVE))
    buttons.append(faComp("angle-up", arrowsStyle))
  return @() {
    watch = canChangeCampaign
    flow = FLOW_VERTICAL
    gap = midPadding
    animations = dropDownAnim
    transform = expandedPosition
    transitions = expandAnimation
    children = buttons
  }
}

let bottomBlock = @(sf) @(){
  watch = showExpandedButtons
  size = [flex(), SIZE_TO_CONTENT]
  halign = ALIGN_CENTER
  children = showExpandedButtons.value
    ? expandedButtons(sf)
    : levelBlock(sf)
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
    onClick = toggleButtonsShowing
    hotkeys = !showExpandedButtons.value ? []
      : [["^Esc | J:B", { action = toggleButtonsShowing}]]
    hplace = ALIGN_CENTER
    children = [
      bottomBlock(sf)
      campaignBlock(campaignName, progress, sf)
    ]
  })
}


return mkCampaignInfo
