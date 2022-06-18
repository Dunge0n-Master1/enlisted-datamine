from "%enlSqGlob/ui_library.nut" import *

let userInfo = require("%enlSqGlob/userInfo.nut")
let profileScene = require("%enlist/profile/profileScene.nut")
let unseenSignal = require("%ui/components/unseenSignal.nut")(0.8)
  .__update({ hplace = ALIGN_RIGHT })
let { sub_txt, h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { hasProfileCard } = require("%enlist/featureFlags.nut")
let { borderColor } = require("%enlist/profile/profilePkg.nut")
let { setTooltip } = require("%ui/style/cursors.nut")
let { hasUnseenDecorators, hasUnseenMedals
} = require("%enlist/profile/unseenProfileState.nut")
let { hasAchievementsReward } = require("%enlist/unlocks/taskListState.nut")
let { chosenNickFrame, chosenPortrait } = require("%enlist/profile/decoratorState.nut")
let { frameNick, getPortrait } = require("%enlSqGlob/ui/decoratorsPresentation.nut")
let { bigPadding, titleTxtColor, defTxtColor, isWide
} = require("%enlSqGlob/ui/viewConst.nut")
let { mkPortraitIcon } = require("decoratorPkg.nut")
let { mkRankIcon } = require("%enlSqGlob/ui/rankPresentation.nut")
let { playerRank } = require("%enlist/profile/rankState.nut")

let PORTRAIT_WIDTH = hdpx(60)

let hasUnseenElements = Computed(@() hasUnseenDecorators.value
  || hasUnseenMedals.value || hasAchievementsReward.value)

let mkChosenPortrait = @(chosenPortraitVal, sf) @() {
  rendObj = ROBJ_BOX
  watch = playerRank
  borderWidth = hdpx(1)
  margin = [bigPadding, 0]
  borderColor = borderColor(sf)
  children = [
    mkPortraitIcon(getPortrait(chosenPortraitVal?.guid), PORTRAIT_WIDTH)
    mkRankIcon(playerRank.value?.rank, {
      vplace = ALIGN_BOTTOM
      hplace = ALIGN_CENTER
      pos = [0, hdpx(10)]
    })
  ]
}

let mkText = @(txt, sf) {
  rendObj = ROBJ_TEXT
  text = txt
  color = sf & S_HOVER ? titleTxtColor : defTxtColor
}

let function profileWidgetUI() {
  let res = {
    watch = [
      userInfo, hasProfileCard, hasUnseenElements, chosenPortrait, chosenNickFrame
    ]
  }
  let pName = userInfo.value?.nameorig ?? ""
  let chosenPortraitVal = chosenPortrait.value
  let hasUnseen = hasUnseenElements.value
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
                {
                  flow = FLOW_HORIZONTAL
                  pos = [0, bigPadding]
                  vplace = ALIGN_BOTTOM
                  valign = ALIGN_CENTER
                  children = [
                    hasUnseen ? unseenSignal : null
                    mkText(isWide
                      ? loc("profile/playerCardTab")
                      : frameNick(pName, chosenNickFrame.value?.guid), sf
                    ).__update(sub_txt)
                  ]
                }
              ]
            }
            mkChosenPortrait(chosenPortraitVal, sf)
          ]
        })
      })
}

return profileWidgetUI
