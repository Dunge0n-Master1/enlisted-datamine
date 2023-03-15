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
let { midPadding, defTxtColor, titleTxtColor, columnWidth, defVertGradientImg,
  hoverVertGradientImg, colPart
} = require("%enlSqGlob/ui/designConst.nut")
let { mkPortraitIcon } = require("decoratorPkg.nut")
let { mkRankIcon, getRankConfig } = require("%enlSqGlob/ui/rankPresentation.nut")
let { playerRank } = require("%enlist/profile/rankState.nut")
let { premiumBtnSize } = require("%enlist/currency/premiumComp.nut")
let { blinkUnseen, unblinkUnseen } = require("%ui/components/unseenComponents.nut")
let {
  hasUnopenedAchievements, hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks
} = require("%enlist/unlocks/unseenUnlocksState.nut")


let portraitWidth = columnWidth
let squareBlockSize= [portraitWidth, portraitWidth]


let defBlockBg = {
  size = squareBlockSize
  rendObj = ROBJ_IMAGE
  image = defVertGradientImg
}

let hoverBlockBg = {
  size = squareBlockSize
  rendObj = ROBJ_IMAGE
  image = hoverVertGradientImg
}


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


let playerRankBlock = @(sf) @() {
  watch = playerRank
  valign = ALIGN_CENTER
  halign = ALIGN_CENTER
  children = [
    sf & S_HOVER ? hoverBlockBg : defBlockBg
    mkRankIcon(playerRank.value?.rank, colPart(0.53))
  ]
}


let playerPortrait = @(sf) @() {
  watch = [hasUnseenElements, hasUnopenedElements, chosenPortrait]
  children = [
    sf & S_HOVER ? hoverBlockBg : defBlockBg
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
    flow = FLOW_VERTICAL
    halign = ALIGN_RIGHT
    children = [
      {
        rendObj = ROBJ_TEXT
        text = frameNick(pNick, nickFrame)
        vplace = ALIGN_CENTER
      }.__update(sf & S_HOVER ? largeNickTxtHovered : largeNickTxtCommon)
      curRank == null ? null : {
        rendObj = ROBJ_TEXT
        text = loc(curRank.locId)
      }.__update(sf & S_HOVER ? smallNickTxtHovered : smallNickTxtCommon)
    ]
  }
}


let profileButtonUi = watchElemState(@(sf) {
  size = [SIZE_TO_CONTENT, premiumBtnSize]
  halign = ALIGN_RIGHT
  behavior = Behaviors.Button
  onHover = @(on) setTooltip(on ? loc("btn/openProfile") : null)
  onClick = profileScene
  flow = FLOW_HORIZONTAL
  gap = midPadding
  valign = ALIGN_CENTER
  children = [
    nickNameBlock(sf)
    {
      flow = FLOW_HORIZONTAL
      children = [
        playerPortrait(sf)
        playerRankBlock(sf)
      ]
    }
  ]
})

return profileButtonUi
