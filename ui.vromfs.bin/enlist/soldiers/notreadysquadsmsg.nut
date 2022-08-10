from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let { defTxtColor, hoverTxtColor, blurBgColor, bigPadding, defBgColor, activeBgColor, warningColor
} = require("%enlSqGlob/ui/viewConst.nut")
let {addModalWindow, removeModalWindow} = require("%ui/components/modalWindows.nut")
let { safeAreaBorders } = require("%enlist/options/safeAreaState.nut")
let { showNotReadySquads, goToSquadAndClose } = require("model/notReadySquadsState.nut")
let JB = require("%ui/control/gui_buttons.nut")

let textButton = require("%ui/components/textButton.nut")
let { mkSquadIcon } = require("%enlSqGlob/ui/squadsUiComps.nut")


const WND_UID = "not_ready_squads_msg"
let needShow = keepref(Computed(@() (showNotReadySquads.value?.notReady.len() ?? 0) > 0))
let close = @() showNotReadySquads(null)

let squadIconSize = [hdpx(60), hdpx(60)]
let squadBlockWidth = hdpx(500)

let header = {
  rendObj = ROBJ_TEXT
  color = defTxtColor
  text = loc("notReadySquads/header")
}.__update(h2_txt)

let mkHint = @(canBattle) {
  size = [hdpx(1100), SIZE_TO_CONTENT]
  rendObj = ROBJ_TEXTAREA
  behavior = Behaviors.TextArea
  halign = ALIGN_CENTER
  color = defTxtColor
  text = loc(canBattle ? "notReadySquads/canBattleHint" : "notReadySquads/hasCantBattleSquadsHint")
}.__update(h2_txt)

let mkText = @(text, color) { rendObj = ROBJ_TEXT, color = color, text = text }

let function mkSquadRow(readyData) {
  let { squad, unreadyMsgs, canBattle } = readyData
  let stateFlags = Watched(0)

  return function() {
    let sf = stateFlags.value
    let textColor = sf & S_HOVER ? hoverTxtColor : defTxtColor
    let allMsgs = (clone unreadyMsgs).map(@(msg, idx)
      mkText(msg, !canBattle && idx == 0 ? warningColor : textColor))
    allMsgs.insert(0, mkText(loc(squad.manageLocId), textColor))

    return {
      watch = stateFlags
      size = [squadBlockWidth, SIZE_TO_CONTENT]
      rendObj = ROBJ_SOLID
      color = sf & S_HOVER ? activeBgColor : defBgColor

      behavior = Behaviors.Button
      onClick = @() goToSquadAndClose(squad)
      onElemState = @(nsf) stateFlags(nsf)

      flow = FLOW_HORIZONTAL
      valign = ALIGN_CENTER
      padding = bigPadding
      gap = bigPadding
      children = [
        mkSquadIcon(squad.icon, { size = squadIconSize })
        {
          flow = FLOW_VERTICAL
          children = allMsgs
        }
      ]
    }
  }
}

let mkSquadsList = @(notReadyList) {
  flow = FLOW_VERTICAL
  gap = bigPadding
  children = notReadyList.map(mkSquadRow)
}

let mkButtons = @(onContinue) {
  flow = FLOW_HORIZONTAL
  children = onContinue == null
    ? textButton(loc("Ok"), close)
    : [
        textButton(loc("continueToBattle"),
          function() {
            close()
            onContinue()
          },
          { hotkeys = [["^Enter | Space"]] })
        textButton(loc("Cancel"), close)
      ]
}

let function notReadySquadMsg() {
  let { notReady = [], onContinue = null } = showNotReadySquads.value
  let canBattle = notReady.findvalue(@(s) !s.canBattle) == null
  return {
    watch = showNotReadySquads
    size = SIZE_TO_CONTENT
    vplace = ALIGN_CENTER
    hplace = ALIGN_CENTER
    halign = ALIGN_CENTER
    flow = FLOW_VERTICAL
    gap = hdpx(20)

    children = [
      header
      mkSquadsList(notReady)
      mkHint(canBattle)
      mkButtons(canBattle ? onContinue : null)
    ]
  }
}

let open = @() addModalWindow({
  key = WND_UID
  size = [sw(100), sh(100)]
  padding = safeAreaBorders.value
  rendObj = ROBJ_WORLD_BLUR_PANEL
  color = blurBgColor
  children = notReadySquadMsg
  onClick = close
  hotkeys = [[$"^Esc | {JB.B}", { description = loc("Close") }]]
})

needShow.subscribe(@(v) v ? open() : removeModalWindow(WND_UID))