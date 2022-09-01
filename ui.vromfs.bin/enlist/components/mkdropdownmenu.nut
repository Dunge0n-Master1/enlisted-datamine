from "%enlSqGlob/ui_library.nut" import *

let fontIconButton = require("%ui/components/fontIconButton.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let textButton = require("%ui/components/textButton.nut")
let { ModalBgTint } = require("%ui/style/colors.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { navHeight } = require("%enlist/mainMenu/mainmenu.style.nut")

let defSize = [navHeight * 0.75, navHeight]
let fabtn = @(icon, onClick) fontIconButton(icon, {
  size = defSize
  onClick
  hotkeys = [["^J:Start | Esc", {description = {skip = true}} ]]
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  skipDirPadNav = true
  margin = [0, 0, 0, fsh(1)]
})

let popupBg = {
  rendObj = ROBJ_WORLD_BLUR_PANEL
  fillColor = ModalBgTint
}

const WND_UID = "main_menu_header_buttons"
let close = @() modalPopupWnd.remove(WND_UID)

let function closeWithCb(cb) {
  cb()
  modalPopupWnd.remove("main_menu_header_buttons")
}

let mkButton = @(btn, needMoveCursor) (btn?.len() ?? 0) > 0
  ? textButton.Flat(btn.name, @() closeWithCb(btn.cb), {
      size = [flex(), SIZE_TO_CONTENT]
      minWidth = SIZE_TO_CONTENT
      margin = 0
    }.__update(needMoveCursor ? {
        behavior = Behaviors.Button
        key = "selected_menu_elem"
        function onAttach() {
          move_mouse_cursor("selected_menu_elem", false)
        }
      } : {}))
  : {
      rendObj = ROBJ_SOLID
      size = [flex(), hdpx(1)]
      color = Color(50,50,50)
    }


let mkMenuButtons = @(buttons, watch) function(){
  local children = type(buttons)=="function" ? buttons() : buttons
  children = children.map(@(btn, idx) mkButton(btn, isGamepad.value && idx == 0))
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
    hotkeys = [["^J:Start | {0} | Esc".subst(JB.B), { action = close, description = loc("Cancel") }]]
  })
}

local function mkDropMenuBtn(buttons, watch) {
  let watchTo = type(watch) != "array" ? [watch] : watch
  let menuButtonsUi = mkMenuButtons(buttons, watchTo)
  let onClick = @(event) openMenu(event, menuButtonsUi)
  return fabtn("list-ul", onClick)
}

return mkDropMenuBtn