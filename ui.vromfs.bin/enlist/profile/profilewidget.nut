from "%enlSqGlob/ui_library.nut" import *

let userInfo = require("%enlSqGlob/userInfo.nut")
let profileScene = require("%enlist/profile/profileScene.nut")
let unseenSignal = require("%ui/components/unseenSignal.nut")(0.8)
  .__update({ hplace = ALIGN_RIGHT })
let { sub_txt, h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { hasProfileCard } = require("%enlist/featureFlags.nut")
let { borderColor } = require("%enlist/profile/profilePkg.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let {
  hasUnseenDecorators, hasUnseenMedals, hasUnseenWallposters,
  hasUnopenedDecorators, hasUnopenedMedals, hasUnopenedWallposters
} = require("%enlist/profile/unseenProfileState.nut")
let { hasAchievementsReward } = require("%enlist/unlocks/taskListState.nut")
let { chosenNickFrame, chosenPortrait } = require("%enlist/profile/decoratorState.nut")
let { frameNick, getPortrait } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { bigPadding, smallPadding, titleTxtColor, defTxtColor, isWide
} = require("%enlSqGlob/ui/viewConst.nut")
let { mkPortraitIcon } = require("decoratorPkg.nut")
let { mkRankIcon, rankIconSize } = require("%enlSqGlob/ui/rankPresentation.nut")
let { playerRank } = require("%enlist/profile/rankState.nut")
let {
  hasUnopenedAchievements, hasUnopenedWeeklyTasks, hasUnseenWeeklyTasks
} = require("%enlist/unlocks/unseenUnlocksState.nut")


let PORTRAIT_WIDTH = hdpx(60)

let unseenNoBlink = unseenSignal.__merge({ key = "blink_off", animations = null })
let unseenBlink = unseenSignal.__merge({ key = "blink_on" })

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

let mkChosenPortrait = @(sf) @() {
  rendObj = ROBJ_BOX
  watch = [
    playerRank, chosenPortrait, hasUnseenElements, hasUnopenedElements
  ]
  borderWidth = hdpx(1)
  margin = [bigPadding, 0]
  borderColor = borderColor(sf)

  children = [
    mkPortraitIcon(getPortrait(chosenPortrait.value?.guid), PORTRAIT_WIDTH)
    mkRankIcon(playerRank.value?.rank, rankIconSize, {
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_CENTER
      pos = [0, hdpx(10)]
    })
    {
      vplace = ALIGN_TOP
      hplace = ALIGN_RIGHT
      pos = [ smallPadding, -smallPadding ]
      children = !hasUnseenElements.value ? null
        : hasUnopenedElements.value ? unseenBlink
        : unseenNoBlink
    }
  ]
}

let mkText = @(txt, sf) {
  rendObj = ROBJ_TEXT
  text = txt
  color = sf & S_HOVER ? titleTxtColor : defTxtColor
}

let function profileWidgetUI() {
  let res = {
    watch = [ userInfo, hasProfileCard, chosenNickFrame ]
  }
  let pName = userInfo.value?.nameorig ?? ""

  return !hasProfileCard.value ? res
    : res.__update({
        size = [SIZE_TO_CONTENT, flex()]
        children = watchElemState(@(sf) {
          size = [SIZE_TO_CONTENT, flex()]
          flow = FLOW_HORIZONTAL
          gap = bigPadding
          margin = [0,bigPadding,0,0]
          behavior = Behaviors.Button
          onClick = profileScene
          onHover = @(on) setTooltip(on ? loc("btn/openProfile") : null)
          children = [
            {
              size = [SIZE_TO_CONTENT, flex()]
              halign = ALIGN_RIGHT
              children = [
                mkText(isWide
                  ? frameNick(pName, chosenNickFrame.value?.guid)
                  : loc("profile/playerCardTab"), sf
                ).__update(h2_txt, { vplace = ALIGN_CENTER })
                mkText(isWide
                  ? loc("profile/playerCardTab")
                  : frameNick(pName, chosenNickFrame.value?.guid), sf
                ).__update(sub_txt, {
                  pos = [0, bigPadding]
                  vplace = ALIGN_BOTTOM
                  valign = ALIGN_CENTER
                })
              ]
            }
            mkChosenPortrait(sf)
          ]
        })
      })
}

return profileWidgetUI
