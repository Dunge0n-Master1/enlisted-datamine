from "%enlSqGlob/ui_library.nut" import *

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { smallUnseenNoBlink, smallUnseenBlink } = require("%ui/components/unseenComps.nut")
let crossplayIcon = require("%enlist/components/crossplayIcon.nut")
let { Bordered } = require("%ui/components/txtButton.nut")
let openChangeGameModeWnd = require("%enlist/gameModes/gameModesWnd/gameModeWnd.nut")
let { currentGameModeId, allGameModesById, hasUnseenGameMode, hasUnopenedGameMode
} = require("%enlist/gameModes/gameModeState.nut")
let { canChangeQueueParams } = require("%enlist/state/queueState.nut")
let { isInSquad, isSquadLeader, squadLeaderState } = require("%enlist/squad/squadState.nut")
let { crossnetworkPlay, needShowCrossnetworkPlayIcon, CrossplayState
} = require("%enlSqGlob/crossnetwork_state.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { accentColor, defTxtColor, smallPadding } = require("%enlSqGlob/ui/designConst.nut")


let accentButtonStyle = {
  defTxtColor = accentColor
  defBdColor = accentColor
}

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
    : hasUnopenedGameMode.value ? smallUnseenBlink
    : smallUnseenNoBlink
}


let function changeGameModeBtn() {
  let gameMode = utf8ToUpper(selectedGameMode.value?.title ?? "")
  let btnText = loc("changeGameMode/Mode", { gameMode })
  let { isVersionCompatible = true } = selectedGameMode.value
  return {
    watch = [selectedGameMode, canChangeQueueParams]
    size = [flex(), SIZE_TO_CONTENT]
    children = Bordered(btnText, openChangeGameModeWnd, {
      hotkeys = canChangeQueueParams.value ? [[ "^J:X" ]] : null
      txtFont = fontMedium
      btnWidth = flex()
      bgChild = gameModeCrossplayIcon
      fgChild = gameModeUnseenIcon
      padding = [0, smallPadding]
      isEnabled = canChangeQueueParams.value
    }.__update(isVersionCompatible ? {} : { style = accentButtonStyle })
  )}
}


return {
  changeGameModeBtn
  selectedGameMode
}
