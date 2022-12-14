from "%enlSqGlob/ui_library.nut" import *

let {body_txt, sub_txt} = require("%enlSqGlob/ui/fonts_style.nut")
let { smallUnseenNoBlink, smallUnseenBlink } = require("%ui/components/unseenComps.nut")
let crossplayIcon = require("%enlist/components/crossplayIcon.nut")
let textButton = require("%ui/components/textButton.nut")
let { TextHover, TextNormal } = require("%ui/components/textButton.style.nut")
let openChangeGameModeWnd = require("changeGameModeWnd.nut")
let {
  currentGameModeId, allGameModesById, hasUnseenGameMode, hasUnopenedGameMode
} = require("gameModeState.nut")
let { canChangeQueueParams } = require("%enlist/state/queueState.nut")
let { mkImageCompByDargKey } = require("%ui/components/gamepadImgByKey.nut")
let getGamepadHotkeys = require("%ui/components/getGamepadHotkeys.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { isInSquad, isSquadLeader, squadLeaderState } = require("%enlist/squad/squadState.nut")
let { crossnetworkPlay, needShowCrossnetworkPlayIcon, CrossplayState } = require("%enlSqGlob/crossnetwork_state.nut")
let { Alert } = require("%ui/style/colors.nut")

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

let grpTypeParams = {
  size = [flex(), hdpx(50)]
  halign = ALIGN_CENTER
  margin = 0
  textMargin = hdpx(5)
}

let modeInfo = @(text, color) {
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      color
      text
    }.__update(sub_txt)
    @() {
      watch = selectedGameMode
      rendObj = ROBJ_TEXT
      text = selectedGameMode.value?.title ?? ""
      color
    }.__update(body_txt)
  ]
}

let changeGameModeBtn = textButton(loc("change_mode"), openChangeGameModeWnd, {
    hotkeys = [ ["^J:X", {description={skip=true} sound="click"}] ]
  }.__update(grpTypeParams, {
    textMargin = 0
    textCtor = @(text, params, _handler, _group, sf) function() {
      let gamepadHotkey = getGamepadHotkeys(params?.hotkeys)
      let ac = gamepadHotkey != "" && isGamepad.value
      let txtColor = sf & S_HOVER ? TextHover
        : selectedGameMode.value?.isVersionCompatible ?? true ? TextNormal
        : Alert
      let iconColor = sf & S_HOVER ? TextHover : Color(220, 220, 220)
      return {
        watch = [isGamepad, selectedGameMode]
        size = [flex(), SIZE_TO_CONTENT]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = [
          {
            padding = [0, 0, 0, hdpx(10)]
            hplace = ALIGN_LEFT
            children = ac ? mkImageCompByDargKey(gamepadHotkey, { height = hdpx(40) }) : null
          }
          modeInfo(text.text, txtColor)
          @() {
            watch = [canShowCrossplayIcon, hasUnseenGameMode, hasUnopenedGameMode]
            vplace = ALIGN_CENTER
            hplace = ALIGN_RIGHT
            flow = FLOW_HORIZONTAL
            padding = [0, hdpx(10), 0, 0]
            children = [
              canShowCrossplayIcon.value ? crossplayIcon({ iconColor }) : null
              !hasUnseenGameMode.value ? null
                : hasUnopenedGameMode.value ? smallUnseenBlink
                : smallUnseenNoBlink
            ]
          }
        ]
      }
    }
  })
)

let changeGameModeDisabled = grpTypeParams.__merge({
  rendObj = ROBJ_BOX
  fillColor = Color(0,0,0,200)
  borderWidth = 0
  borderRadius = hdpx(2)
  children = modeInfo(loc("current_mode"), TextNormal)
})

let changeGameModeWidget = @() {
  size = [flex(), SIZE_TO_CONTENT]
  watch = [canChangeQueueParams]
  children = canChangeQueueParams.value ? changeGameModeBtn : changeGameModeDisabled
}

return {
  changeGameModeWidget
  selectedGameMode
}
