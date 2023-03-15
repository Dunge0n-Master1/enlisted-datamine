from "%enlSqGlob/ui_library.nut" import *

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { accentColor, defTxtColor, midPadding, defVertGradientImg, hoverVertGradientImg,
  titleTxtColor, colPart, disabledTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { blinkUnseen, unblinkUnseen } = require("%ui/components/unseenComponents.nut")
let crossplayIcon = require("%enlist/components/crossplayIcon.nut")
let openChangeGameModeWnd = require("%enlist/gameModes/gameModesWnd/gameModeWnd.nut")
let { currentGameModeId, allGameModesById, hasUnseenGameMode, hasUnopenedGameMode
} = require("%enlist/gameModes/gameModeState.nut")
let { canChangeQueueParams } = require("%enlist/state/queueState.nut")
let { isInSquad, isSquadLeader, squadLeaderState } = require("%enlist/squad/squadState.nut")
let { crossnetworkPlay, needShowCrossnetworkPlayIcon, CrossplayState
} = require("%enlSqGlob/crossnetwork_state.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let colorize = require("%ui/components/colorize.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")


let defTxtStyle = { color = titleTxtColor }.__update(fontMedium)
let disabledTxtStyle = { color = disabledTxtColor }.__update(fontMedium)


let squadLeaderGameModeId = Computed(@() squadLeaderState.value?.gameModeId)
let selectedGameModeId = Computed(@() isInSquad.value && !isSquadLeader.value
  ? squadLeaderGameModeId.value
  : currentGameModeId.value)

let selectedGameMode = Computed(@() allGameModesById.value?[selectedGameModeId.value])


let canShowCrossplayIcon = Computed(@() needShowCrossnetworkPlayIcon
  && crossnetworkPlay.value != CrossplayState.OFF
  && (!isInSquad.value || isSquadLeader.value)
  && selectedGameMode.value?.needShowCrossplayIcon
)


let gameModeCrossplayIcon = @() {
  watch = canShowCrossplayIcon
  hplace = ALIGN_RIGHT
  children = canShowCrossplayIcon.value ? crossplayIcon({ iconColor = defTxtColor }) : null
}


let gameModeUnseenIcon = @() {
  watch = [hasUnseenGameMode, hasUnopenedGameMode]
  hplace = ALIGN_LEFT
  vplace = ALIGN_TOP
  children = !hasUnseenGameMode.value ? null
    : hasUnopenedGameMode.value ? blinkUnseen
    : unblinkUnseen
}


let changeGameModeBtn = watchElemState(function(sf) {
  let gameMode = utf8ToUpper(selectedGameMode.value?.title ?? "")
  let btnText = loc("changeGameMode/Mode", { gameMode = colorize(accentColor, gameMode) })
  let { isVersionCompatible = true } = selectedGameMode.value
  return {
    watch = [selectedGameMode, canChangeQueueParams]
    rendObj = ROBJ_IMAGE
    image = sf & S_HOVER ? hoverVertGradientImg : defVertGradientImg
    size = [flex(), colPart(0.806)]
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick = openChangeGameModeWnd
    hotkeys = canChangeQueueParams.value ? [[ "^J:X" ]] : null
    padding = [0, midPadding]
    children =  [
      mkHotkey("^J:X | G", openChangeGameModeWnd)
      {
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        text = btnText
      }.__update(isVersionCompatible ? defTxtStyle : disabledTxtStyle)
      gameModeCrossplayIcon
      gameModeUnseenIcon
    ]
  }
})



return {
  changeGameModeBtn
  selectedGameMode
  openChangeGameModeWnd
}
