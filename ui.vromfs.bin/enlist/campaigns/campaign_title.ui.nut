from "%enlSqGlob/ui_library.nut" import *

let { h2_txt, sub_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let msgbox = require("%enlist/components/msgbox.nut")
let campaignSelectWnd = require("campaign_select_wnd.nut")
let { mkNotifierBlink } = require("%enlist/components/mkNotifier.nut")
let { progressBar } = require("%enlSqGlob/ui/defcomps.nut")
let { gameProfile } = require("%enlist/soldiers/model/config/gameProfile.nut")
let { curCampaign, canChangeCampaign } = require("%enlist/meta/curCampaign.nut")
let { hasCampaignSelection } = require("campaign_sel_state.nut")
let { unseenCampaigns } = require("unseenCampaigns.nut")
let {
  curArmyLevel, curArmyExp, curArmyLevels
} = require("%enlist/soldiers/model/armyUnlocksState.nut")
let { maxCampaignLevel } = require("%enlist/soldiers/model/state.nut")
let {
  shadowStyle, titleTxtColor, defTxtColor
} = require("%enlSqGlob/ui/viewConst.nut")

let text = @(text, stateFlags, customStyle = {}) @() {
  watch = stateFlags
  rendObj = ROBJ_TEXT
  color = stateFlags.value & S_HOVER ? titleTxtColor : defTxtColor
  text
}.__update(sub_txt, shadowStyle, customStyle)

let needNotifier = Computed(@() maxCampaignLevel.value >= 4
                                    && unseenCampaigns.value.len() > 0)

let function chooseCampaignLabel(stateFlags) {
  let children = text(loc("btn/changeCampaign"), stateFlags, sub_txt)
  return @() {
    watch = stateFlags
    hplace = ALIGN_RIGHT
    rendObj = ROBJ_BOX
    borderWidth = [0, 0, hdpx(1), 0]
    borderColor = stateFlags.value & S_HOVER ? titleTxtColor : defTxtColor
    children
  }
}

let function mkChooseCampaignBtn(stateFlags) {
  let campaignLabel = chooseCampaignLabel(stateFlags)
  return @() {
    watch = needNotifier
    size = [flex(), SIZE_TO_CONTENT]
    minWidth = SIZE_TO_CONTENT
    flow = FLOW_VERTICAL
    children = [
      needNotifier.value
        ? mkNotifierBlink(loc("hint/newCampaignAvailable"), {
          size = [flex(), SIZE_TO_CONTENT]
          minWidth = SIZE_TO_CONTENT
        })
        : null
      campaignLabel
    ]
  }
}

let function campaignInfo() {
  let curLevel = curArmyLevel.value
  let expToNextLevel = curArmyLevels.value?[curLevel].expSize ?? 0
  let percent = expToNextLevel > 0
    ? (curArmyExp.value).tofloat() / expToNextLevel : 0
  let campaign = curCampaign.value

  let stateFlags = Watched(0)
  let res = !hasCampaignSelection.value ? {} : {
    behavior = Behaviors.Button
    onElemState = @(sf) stateFlags(sf)
    onClick = @() canChangeCampaign.value
      ? campaignSelectWnd.open()
      : msgbox.show({ text = loc("quickMatch/squadLeaderParams") })
  }
  return res.__update({
    watch = [hasCampaignSelection, gameProfile, curCampaign, curArmyLevel, curArmyExp, curArmyLevels]
    flow = FLOW_VERTICAL
    children = [
      text(loc(gameProfile.value?.campaigns[campaign].title ?? campaign), stateFlags, h2_txt)
      text(loc("levelInfo", { level = curLevel }), stateFlags)
      progressBar({ value = percent, color = titleTxtColor })
      hasCampaignSelection.value ? mkChooseCampaignBtn(stateFlags) : null
    ]
  })
}

return campaignInfo
