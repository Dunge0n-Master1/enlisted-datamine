from "%enlSqGlob/ui_library.nut" import *

let { fontSub, fontBody } = require("%enlSqGlob/ui/fontsStyle.nut")
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
let { midPadding, titleTxtColor, defItemBlur, darkTxtColor, panelBgColor, bigPadding,
  hoverSlotBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { mkPortraitIcon } = require("decoratorPkg.nut")
let { mkRankImage, getRankConfig } = require("%enlSqGlob/ui/rankPresentation.nut")
let { playerRank } = require("%enlist/profile/rankState.nut")
let { premiumBtnSize } = require("%enlist/currency/premiumComp.nut")
let { blinkUnseen, unblinkUnseen } = require("%ui/components/unseenComponents.nut")
let {
  hasUnopenedAchievements, hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks
} = require("%enlist/unlocks/unseenUnlocksState.nut")


let portraitWidth = hdpxi(62)
let squareBlockSize= [portraitWidth, portraitWidth]


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


let playerRankBlock = @(sf) @() {
  watch = playerRank
  rendObj = ROBJ_WORLD_BLUR
  size = squareBlockSize
  color = defItemBlur
  fillColor = sf & S_HOVER ? hoverSlotBgColor : panelBgColor
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = mkRankImage(playerRank.value?.rank, { size = squareBlockSize, rendObj = null })
}


let playerPortrait = @() {
  watch = [hasUnseenElements, hasUnopenedElements, chosenPortrait]
  size = squareBlockSize
  children = [
    mkPortraitIcon(getPortrait(chosenPortrait.value?.guid), portraitWidth)
    {
      pos = [0, midPadding]
      hplace = ALIGN_CENTER
      vplace = ALIGN_BOTTOM
      children = !hasUnseenElements.value ? null
        : hasUnopenedElements.value ? blinkUnseen
        : unblinkUnseen
    }
  ]
}


let nickNameBlock = @(sf) function() {
  let { rank = 0 } = playerRank.value
  let curRank = rank == 0 ? null : getRankConfig(rank)
  let pNick = userInfo.value?.nameorig ?? ""
  let nickFrame = chosenNickFrame.value?.guid
  return {
    watch = [playerRank, chosenNickFrame, userInfo]
    size = [SIZE_TO_CONTENT, flex()]
    padding = [0, bigPadding]
    flow = FLOW_VERTICAL
    valign = ALIGN_CENTER
    children = [
      {
        rendObj = ROBJ_TEXT
        text = frameNick(pNick, nickFrame)
        vplace = ALIGN_CENTER
        color = sf & S_HOVER ? darkTxtColor : titleTxtColor
      }.__update(fontBody)
      curRank == null ? null : {
        rendObj = ROBJ_TEXT
        text = loc(curRank.locId)
        color = sf & S_HOVER ? darkTxtColor : titleTxtColor
      }.__update(fontSub)
    ]
  }
}


let profileButtonUi = watchElemState(@(sf) {
  size = [SIZE_TO_CONTENT, premiumBtnSize + bigPadding]
  padding = [bigPadding, 0, 0, 0]
  halign = ALIGN_RIGHT
  minWidth = fsh(27.5)
  behavior = Behaviors.Button
  onHover = @(on) setTooltip(on ? loc("btn/openProfile") : null)
  onClick = profileScene
  sound = {
    hover = "ui/enlist/button_highlight"
    click = "ui/enlist/button_click"
    active = "ui/enlist/button_action"
  }
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_BOTTOM
  children = [
    {
      rendObj = ROBJ_SOLID
      size = [SIZE_TO_CONTENT, flex()]
      flow = FLOW_HORIZONTAL
      color = sf & S_HOVER ? hoverSlotBgColor : panelBgColor
      children = [
        playerPortrait
        nickNameBlock(sf)
        playerRankBlock(sf)
      ]
    }
  ]
})

return profileButtonUi
