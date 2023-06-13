from "%enlSqGlob/ui_library.nut" import *

let { fontMedium } = require("%enlSqGlob/ui/fontsStyle.nut")
let { accentColor, defTxtColor, midPadding, transpPanelBgColor, colPart, disabledTxtColor,
  darkTxtColor, defItemBlur, smallPadding, startBtnWidth
  ,titleTxtColor, hoverSlotBgColor, highlightLineTop
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
let { isGamepad } = require("%ui/control/active_controls.nut")


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


let gameModeCrossplayIcon = function() {
  return {
    watch = canShowCrossplayIcon
    hplace = ALIGN_RIGHT
    children = canShowCrossplayIcon.value ? crossplayIcon({ iconColor = defTxtColor }) : null
  }
}


let gameModeUnseenIcon = @() {
  watch = [hasUnseenGameMode, hasUnopenedGameMode]
  hplace = ALIGN_RIGHT
  vplace = ALIGN_TOP
  children = !hasUnseenGameMode.value ? null
    : hasUnopenedGameMode.value ? blinkUnseen
    : unblinkUnseen
}


let group = ElemGroup()
let serversComp = serversToShow(group, openChangeGameModeWnd)
let mkTxtColor = @(sf, disabled) disabled
  ? disabledTxtColor
  : sf & S_ACTIVE
    ? titleTxtColor
    : sf & S_HOVER ? darkTxtColor : defTxtColor

let changeModeHotkey = mkHotkey("^J:X", openChangeGameModeWnd)

let changeGameModeBtn = watchElemState(function(sf) {
  let gameMode = utf8ToUpper(selectedGameMode.value?.title ?? "")
  let { isVersionCompatible = true } = selectedGameMode.value
  return {
    watch = [canChangeQueueParams, selectedGameMode, isGamepad]
    rendObj = ROBJ_WORLD_BLUR
    size = [startBtnWidth, colPart(0.806)]
    color = defItemBlur
    fillColor = sf & S_HOVER
      ? hoverSlotBgColor
      : sf & S_ACTIVE
        ? accentColor
        : transpPanelBgColor
    group
    behavior = Behaviors.Button
    onClick = openChangeGameModeWnd
    key = canChangeQueueParams.value
    hotkeys = canChangeQueueParams.value ? [[ "^J:X | G" ]] : null
    children = [
      highlightLineTop
      {
        valign = ALIGN_CENTER
        padding = [0, midPadding]
        size = flex()
        children = [
          isGamepad.value && canChangeQueueParams.value ? changeModeHotkey : null
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
                    color = mkTxtColor(sf, !isVersionCompatible)
                  }.__update(fontMedium)
                  {
                    rendObj = ROBJ_TEXT
                    text = gameMode
                    color = mkTxtColor(sf, !isVersionCompatible)
                  }.__update(fontMedium)
                ]
              }
              serversComp
            ]
          }
          gameModeCrossplayIcon
          gameModeUnseenIcon
        ]
      }
    ]
  }
})



return {
  changeGameModeBtn
  selectedGameMode
  openChangeGameModeWnd
}
