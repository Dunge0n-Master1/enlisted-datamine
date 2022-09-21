from "%enlSqGlob/ui_library.nut" import *

let { h2_txt } = require("%enlSqGlob/ui/fonts_style.nut")
let fontIconButton = require("%ui/components/fontIconButton.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let textButton = require("%ui/components/textButton.nut")
let { ModalBgTint } = require("%ui/style/colors.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { columnWidth } = require("%enlSqGlob/ui/designConst.nut")
let { premiumBtnSize } = require("%enlist/currency/premiumComp.nut")

let defSize = [columnWidth * 0.8, premiumBtnSize]
const WND_UID = "main_menu_header_buttons"

let fabtn = @(icon, onClick) fontIconButton(icon, {
  size = defSize
  onClick
  iconParams = { fontSize = h2_txt.fontSize }
  hotkeys = [[ "^J:Start | Esc", { description = { skip = true } } ]]
  halign = ALIGN_RIGHT
  valign = ALIGN_CENTER
})

let popupBg = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = ModalBgTint
}

let function close(cb = null) {
  cb?()
  modalPopupWnd.remove(WND_UID)
}

let mkButton = @(btn, needMoveCursor) (btn?.len() ?? 0) > 0
  ? textButton.Flat(btn.name, @() close(btn.cb), {
      size = [flex(), SIZE_TO_CONTENT]
      minWidth = SIZE_TO_CONTENT
      margin = 0
    }.__update(!needMoveCursor ? {} : {
      behavior = Behaviors.Button
      key = "selected_menu_elem"
      function onAttach() {
        move_mouse_cursor("selected_menu_elem", false)
      }
    }))
  : {
      rendObj = ROBJ_SOLID
      size = [flex(), hdpx(1)]
      color = Color(50,50,50) /* FIX ME: waiting for menu's redisign */
    }


let mkMenuButtons = @(buttons, watch) function(){
  local children = (type(buttons) == "function" ? buttons() : buttons)
    .map(@(btn, idx) mkButton(btn, isGamepad.value && idx == 0))
  return {
    watch = [isGamepad].extend(watch)
    rendObj = ROBJ_BOX
    fillColor = Color(0,0,0)
    borderRadius = hdpx(4)
    flow = FLOW_VERTICAL
    children
  }
}

let function openMenu(event, content) {
  let { targetRect } = event
  modalPopupWnd.add([targetRect.r, targetRect.b], {
    uid = WND_UID
    children = content
    popupOffset = hdpx(5)
    popupHalign = ALIGN_RIGHT
    popupBg
    hotkeys = [[
      "^J:Start | {0} | Esc".subst(JB.B),
      { action = @() close(), description = loc("Cancel") }
    ]]
  })
}

local function mkDropMenuBtn(buttons, watch) {
  let watchTo = type(watch) != "array" ? [watch] : watch
  let menuButtonsUi = mkMenuButtons(buttons, watchTo)
  let onClick = @(event) openMenu(event, menuButtonsUi)
  return fabtn("bars", onClick)
}

return mkDropMenuBtn