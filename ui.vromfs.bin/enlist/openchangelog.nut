from "%enlSqGlob/ui_library.nut" import *

let navState = require("%enlist/navState.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { currentPatchnote, patchnoteSelector } = require("changelog.ui.nut")

let fontIconButton = require("%ui/components/fontIconButton.nut")

let textButton = require("%ui/components/textButton.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")

let isOpened = mkWatched(persist, "isOpened", false)
let {chosenPatchnote, curPatchnoteIdx, nextPatchNote, prevPatchNote, updateVersion,
  markLastSeen
} = require("changeLogState.nut")
let { transpPanelBgColor } = require("%enlSqGlob/ui/designConst.nut")

let close = function() {
  markLastSeen()
  isOpened(false)
}
let open = @() isOpened(true)

let gap = hdpx(10)
let btnNext  = textButton(loc("shop/nextItem"), nextPatchNote, {hotkeys=[[$"^J:Y | Enter"]], margin=0})
let btnClose = textButton(loc("mainmenu/btnClose"), close, {hotkeys=[[$"^{JB.B} | Esc"]], margin=0})
let closeBtn = fontIconButton("close", {
  skipDirPadNav = true
  onClick = close
  hplace = ALIGN_RIGHT
  hotkeys=[[$"^{JB.B} | Esc", {description=loc("Close")}]]
})

let nextButton = @() {
  size = SIZE_TO_CONTENT
  children = curPatchnoteIdx.value != 0 ? btnNext : btnClose
  watch = curPatchnoteIdx
  hplace = ALIGN_RIGHT
  function onAttach(elem) {
    if (isGamepad.value) {
      move_mouse_cursor(elem, false)
    }
  }
}

let attractorForCursorDirPad = {
  behavior = Behaviors.Button
  size = [hdpx(50), ph(66)]
  hplace = ALIGN_CENTER
  vplace = ALIGN_CENTER
  eventPassThrough = true
}

let hkLB = ["^J:LB | Left", prevPatchNote, loc("shop/previousItem")]
let hkRB = ["^J:RB | Right", nextPatchNote, loc("shop/nextItem")]

let clicksHandler = {
  size = flex()
  eventPassThrough = true
  behavior = Behaviors.Button
  hotkeys = [hkLB, hkRB]
  onClick = nextPatchNote
}

let changelogRoot = {
  size = flex()
  children = [
    clicksHandler
    {
      rendObj = ROBJ_WORLD_BLUR_PANEL
      fillColor = transpPanelBgColor
      size = SIZE_TO_CONTENT
      flow = FLOW_VERTICAL
      padding = gap
      gap = gap
      children = [
        closeBtn
        currentPatchnote
        @() {
          size = [flex(), SIZE_TO_CONTENT]
          flow = FLOW_HORIZONTAL
          gap = gap
          valign = ALIGN_CENTER
          watch = isGamepad
          children = [
            patchnoteSelector
            isGamepad.value ? null : nextButton
          ]
        }
      ]
    }
    attractorForCursorDirPad
  ]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  hotkeys = [
    ["Esc | Space", {action=close, description = loc("mainmenu/btnClose")}]
  ]
}

let addLogScene = @() navState.addScene(changelogRoot)
if (isOpened.value)
  addLogScene()
isOpened.subscribe(function(opened) {
  if (opened) {
    addLogScene()
    return
  }
  updateVersion()
  chosenPatchnote(null)
  navState.removeScene(changelogRoot)
})

return {
  openChangelog = open
}
