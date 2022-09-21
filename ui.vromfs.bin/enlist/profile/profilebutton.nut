from "%enlSqGlob/ui_library.nut" import *

let { fontSmall, fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let userInfo = require("%enlSqGlob/userInfo.nut")
let profileScene = require("%enlist/profile/profileScene.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let {
  hasUnseenDecorators, hasUnseenMedals, hasUnseenWallposters,
  hasUnopenedDecorators, hasUnopenedMedals, hasUnopenedWallposters
} = require("%enlist/profile/unseenProfileState.nut")
let { hasAchievementsReward } = require("%enlist/unlocks/taskListState.nut")
let { chosenNickFrame, chosenPortrait } = require("%enlist/profile/decoratorState.nut")
let { frameNick, getPortrait } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { panelBgColor, midPadding, defTxtColor, titleTxtColor, columnWidth
} = require("%enlSqGlob/ui/designConst.nut")
let { mkPortraitIcon } = require("decoratorPkg.nut")
let { mkRankIcon, getRankConfig } = require("%enlSqGlob/ui/rankPresentation.nut")
let { playerRank } = require("%enlist/profile/rankState.nut")
let { premiumBtnSize } = require("%enlist/currency/premiumComp.nut")
let { smallUnseenNoBlink, smallUnseenBlink } = require("%ui/components/unseenComps.nut")
let {
  hasUnopenedAchievements, hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks
} = require("%enlist/unlocks/unseenUnlocksState.nut")


let portraitWidth = columnWidth
let stateFlag = Watched(0)

let hasUnseenElements = Computed(@() hasUnseenDecorators.value
  || hasUnseenMedals.value
  || hasUnseenWallposters.value
  || hasAchievementsReward.value
  || hasUnseenWeeklyTasks.value)

let hasUnopenedElements = Computed(@() hasUnopenedDecorators.value
  || hasUnopenedMedals.value
  || hasUnopenedWallposters.value
  || hasUnopenedAchievements.value
  || hasUnopenedWeeklyTasks.value)

let smallNickTxtCommon = {
  color =  defTxtColor
}.__update(fontSmall)

let smallNickTxtHovered = {
  color = titleTxtColor
}.__update(fontSmall)

let largeNickTxtCommon = {
  color = defTxtColor
}.__update(fontLarge)

let largeNickTxtHovered = {
  color = titleTxtColor
}.__update(fontLarge)


let playerRankBlock = @() {
  watch = playerRank
  rendObj = ROBJ_SOLID
  color = panelBgColor
  size = [portraitWidth, portraitWidth]
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = mkRankIcon(playerRank.value?.rank, hdpxi(43))
}

let playerPortrait = @() {
  watch = [hasUnseenElements, hasUnopenedElements, chosenPortrait]
  rendObj = ROBJ_SOLID
  color = panelBgColor
  children = [
    mkPortraitIcon(getPortrait(chosenPortrait.value?.guid), portraitWidth)
    {
      pos = [0, midPadding]
      hplace = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      children = !hasUnseenElements.value ? null
        : hasUnopenedElements.value ? smallUnseenBlink
        : smallUnseenNoBlink
    }
  ]
}


let function nickNameBlock() {
  let curRank = getRankConfig(playerRank.value?.rank)
  let pNick = userInfo.value?.nameorig ?? ""
  let nickFrame = chosenNickFrame.value?.guid
  let sf = stateFlag.value
  return {
    watch = [playerRank, chosenNickFrame, userInfo, stateFlag]
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    children = [
      {
        rendObj = ROBJ_TEXT
        text = frameNick(pNick, nickFrame)
        vplace = ALIGN_CENTER
      }.__update(sf & S_HOVER ? largeNickTxtHovered : largeNickTxtCommon)
      {
        rendObj = ROBJ_TEXT
        text = loc(curRank.locId)
      }.__update(sf & S_HOVER ? smallNickTxtHovered : smallNickTxtCommon)
    ]
  }
}


let profileButtonUi = {
  size = [SIZE_TO_CONTENT, premiumBtnSize]
  halign = ALIGN_RIGHT
  children = {
    flow = FLOW_HORIZONTAL
    behavior = Behaviors.Button
    gap = midPadding
    onClick = profileScene
    valign = ALIGN_CENTER
    onElemState = @(sf) stateFlag(sf)
    onHover = @(on) setTooltip(on ? loc("btn/openProfile") : null)
    children = [
      nickNameBlock
      {
        flow = FLOW_HORIZONTAL
        children = [
          playerPortrait
          playerRankBlock
        ]
      }
    ]
  }
}

return profileButtonUi
