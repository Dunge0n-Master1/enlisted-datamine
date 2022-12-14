from "%enlSqGlob/ui_library.nut" import *

let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { FAButton } = require("%ui/components/txtButton.nut")
let { colPart, defBdColor, topWndBgColor, bottomWndBgColor, panelBgColor, defTxtColor,
  titleTxtColor, commonBtnHeight, colFull, midPadding
} = require("%enlSqGlob/ui/designConst.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { premiumBtnSize } = require("%enlist/currency/premiumComp.nut")
let { mkColoredGradientY } = require("%enlSqGlob/ui/gradients.nut")


let defSize = premiumBtnSize
const WND_UID = "main_menu_header_buttons"
let wndGradient = mkColoredGradientY(topWndBgColor, bottomWndBgColor)
let fillBgColor = @(sf) sf & S_ACTIVE ? 0xFF3B516A
  : sf & S_HOVER ? 0xFF495567
  : panelBgColor
let defTxtStyle = { color = defTxtColor }.__update(fontLarge)
let titleTxtStyle = { color = titleTxtColor }.__update(fontLarge)


let function close(cb = null) {
  cb?()
  modalPopupWnd.remove(WND_UID)
}


let mkMenuButton = @(btn, needMoveCursor) (btn?.len() ?? 0) > 0
  ? watchElemState(@(sf) {
      rendObj = ROBJ_SOLID
      color = fillBgColor(sf)
      size = [flex(), commonBtnHeight]
      minWidth = SIZE_TO_CONTENT
      behavior = Behaviors.Button
      onClick = @() close(btn.cb)
      valign = ALIGN_CENTER
      padding = [0, midPadding]
      children = {
        rendObj = ROBJ_TEXT
        text = btn?.name ?? ""
      }.__update(sf != 0 ? titleTxtStyle : defTxtStyle)
    }.__update(!needMoveCursor ? {} : {
      key = "selected_menu_elem"
      function onAttach() {
        move_mouse_cursor("selected_menu_elem", false)
      }
    }))
  : {
      rendObj = ROBJ_SOLID
      size = [flex(), hdpx(1)]
      color = defBdColor
    }


let mkMenuButtons = @(buttons, watch) function(){
  local children = (type(buttons) == "function" ? buttons() : buttons)
    .map(@(btn, idx) mkMenuButton(btn, isGamepad.value && idx == 0))
  return {
    watch = [isGamepad].extend(watch)
    minWidth = colFull(4)
    flow = FLOW_VERTICAL
    children
  }
}

let openMenu = @(event, content) modalPopupWnd.add(event.targetRect, {
  uid = WND_UID
  padding = 0
  margin = [colPart(0.09), 0]
  popupHalign = ALIGN_RIGHT
  popupBg = {
    rendObj = ROBJ_IMAGE
    image = wndGradient
  }
  hotkeys = [[
    "^J:Start | {0} | Esc".subst(JB.B),
    { action = @() close(), description = loc("Cancel") }
  ]]
  children = content
})


local function mkDropMenuBtn(buttons, watch) {
  let watchTo = type(watch) != "array" ? [watch] : watch
  let menuButtonsUi = mkMenuButtons(buttons, watchTo)
  let onClick = @(event) openMenu(event, menuButtonsUi)
  return FAButton("bars", onClick, {
    rendObj = null
    btnWidth = defSize
    btnHeight = defSize
    hideTxtWithGamepad = true
    hotkeys = [[ "^J:Start | Esc", { description = { skip = true } } ]]
  })
}


return mkDropMenuBtn