from "%enlSqGlob/ui_library.nut" import *

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { accentColor, defTxtColor, midPadding, transpPanelBgColor, colPart, disabledTxtColor,
  darkTxtColor, defItemBlur, smallPadding, hoverPanelBgColor, hoverTxtColor
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
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")
let { serversToShow } = require("%enlist/gameModes/gameModesWnd/serverClusterUi.nut")

let smallTxtStyle = { color = defTxtColor }.__update(fontMedium)
let hoverSmallTxtStyle = { color = hoverTxtColor }.__update(fontMedium)
let activeSmallTxtStyle = { color = darkTxtColor }.__update(fontMedium)
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
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  children = !hasUnseenGameMode.value ? null
    : hasUnopenedGameMode.value ? blinkUnseen
    : unblinkUnseen
}


let function changeGameModeBtn() {
  let group = ElemGroup()
  let serversComp = serversToShow(group)
  return watchElemState(function(sf) {
    let gameMode = utf8ToUpper(selectedGameMode.value?.title ?? "")
    let { isVersionCompatible = true } = selectedGameMode.value
    return {
      watch = [selectedGameMode, canChangeQueueParams]
      rendObj = ROBJ_WORLD_BLUR
      size = [flex(), colPart(0.806)]
      color = defItemBlur
      fillColor = sf & S_ACTIVE ? accentColor
        : sf & S_HOVER ? hoverPanelBgColor
        : transpPanelBgColor
      group
      padding = [0, midPadding]
      valign = ALIGN_CENTER
      behavior = Behaviors.Button
      onClick = openChangeGameModeWnd
      hotkeys = canChangeQueueParams.value ? [[ "^J:X" ]] : null
      children =  [
        mkHotkey("^J:X | G", openChangeGameModeWnd)
        {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_VERTICAL
          gap = smallPadding
          children = [
            {
              size = [flex(), SIZE_TO_CONTENT]
              flow = FLOW_HORIZONTAL
              halign = ALIGN_CENTER
              gap = smallPadding
              children = [
                {
                  rendObj = ROBJ_TEXT
                  text = loc("change_mode")
                }.__update(!isVersionCompatible ? disabledTxtStyle
                  : sf & S_ACTIVE ? activeSmallTxtStyle
                  : sf & S_HOVER ? hoverSmallTxtStyle
                  : smallTxtStyle)
                {
                  rendObj = ROBJ_TEXT
                  text = gameMode
                }.__update(!isVersionCompatible ? disabledTxtStyle
                  : sf & S_ACTIVE ? activeSmallTxtStyle
                  : sf & S_HOVER ? hoverSmallTxtStyle
                  : smallTxtStyle)
              ]
            }
            serversComp
          ]
        }
        gameModeCrossplayIcon
        gameModeUnseenIcon
      ]
    }
  })
}



return {
  changeGameModeBtn
  selectedGameMode
  openChangeGameModeWnd
}
