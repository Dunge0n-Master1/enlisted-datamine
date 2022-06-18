from "%enlSqGlob/ui_library.nut" import *

let fontIconButton = require("%ui/components/fontIconButton.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let {isGamepad} = require("%ui/control/active_controls.nut")
let textButton = require("%ui/components/textButton.nut")
let {ModalBgTint} = require("%ui/style/colors.nut")
let JB = require("%ui/control/gui_buttons.nut")

let defSize = [hdpx(45)*0.75, hdpx(45)]
let function fabtn(icon, onClick=null, hotkeys=null, size = defSize, skipDirPadNav=true){
  let group = ElemGroup()
  let btn = type(icon)=="string"
          ? fontIconButton(icon, {
              size = size
              onClick = onClick
              hotkeys = hotkeys
              halign = ALIGN_CENTER
              valign = ALIGN_CENTER
              skipDirPadNav = skipDirPadNav
              group
            })
          : icon
  return {
    size = SIZE_TO_CONTENT
    behavior = Behaviors.Button
    group = group
    onClick = onClick
    skipDirPadNav
    children = btn
    padding = [0, fsh(1)]
  }
}

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
        behavior = [Behaviors.Button, Behaviors.RecalcHandler]
        key = "selected_menu_elem"
        function onRecalcLayout(initial) {
          if (initial)
            move_mouse_cursor("selected_menu_elem", false)
        }
      } : {}))
  : {
      rendObj = ROBJ_SOLID
      size = [flex(), hdpx(1)]
      color = Color(50,50,50)
    }


let mkMenuButtons = @(buttons, watch=null) function(){
  local children = type(buttons)=="function" ? buttons() : buttons
  children = children.map(@(btn, idx) mkButton(btn, isGamepad.value && idx == 0))
  return {
    watch = [isGamepad].extend(watch)
    rendObj = ROBJ_BOX
    fillColor = Color(0,0,0)
    borderRadius = hdpx(4)
    borderWidth = 0
    flow = FLOW_VERTICAL
    children
  }
}

local mkDropMenuBtn = kwarg(function (buttons, watch = null, size = defSize, makeMenuBtn = null, hotkeyOpen = "^J:Start | Esc", skipDirPadNav = true) {
  watch = watch ?? []
  if (type(watch)!="array")
    watch = [watch]
  let menuButtonsUi = mkMenuButtons(buttons, watch)
  makeMenuBtn = makeMenuBtn ?? @(openMenu) fabtn("list-ul", openMenu, [[hotkeyOpen, {description = {skip = true}} ]], size, skipDirPadNav)
  let function openMenu(event) {
    let {targetRect} = event
    modalPopupWnd.add([targetRect.r, targetRect.b], {
      uid = WND_UID
      padding = 0
      children = menuButtonsUi
      popupOffset = hdpx(5)
      popupHalign = ALIGN_RIGHT
      popupBg = popupBg
      hotkeys = [["^J:Start | {0} | Esc".subst(JB.B), { action = close, description = loc("Cancel") }]]
    })
  }
  return makeMenuBtn(openMenu)
})

return {
  mkDropMenuBtn
}