from "%enlSqGlob/ui_library.nut" import *

let { fontFontawesome, fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")
let { colPart, defBdColor, panelBgColor, defTxtColor, defItemBlur, commonBtnHeight, colFull,
  midPadding, smallPadding, titleTxtColor, hoverSlotBgColor, darkTxtColor, bigPadding
} = require("%enlSqGlob/ui/designConst.nut")
let JB = require("%ui/control/gui_buttons.nut")
let { premiumBtnSize } = require("%enlist/currency/premiumComp.nut")
let { mkImageCompByDargKey } = require("%ui/components/gamepadImgByKey.nut")
let fa = require("%ui/components/fontawesome.map.nut")


let defSize = premiumBtnSize
const WND_UID = "main_menu_header_buttons"
let fillBgColor = @(sf) sf & S_ACTIVE ? 0xFF3B516A
  : sf & S_HOVER ? hoverSlotBgColor
  : panelBgColor

let function close(cb = null) {
  cb?()
  modalPopupWnd.remove(WND_UID)
}

let btnSound = freeze({
  hover = "ui/enlist/button_highlight"
  click = "ui/enlist/button_click"
  active = "ui/enlist/button_action"
})

let hotkeyOnHover = freeze({
  size = [fontLarge.fontSize, SIZE_TO_CONTENT]
  children = mkImageCompByDargKey(JB.A, { height = fontLarge.fontSize })
})

let widthHotkeyOnHover = freeze({size = [calc_comp_size(hotkeyOnHover)[0], 0]})

let mkMenuButton = @(btn, needMoveCursor) (btn?.len() ?? 0) > 0
  ? watchElemState(function(sf) {
      return {
        watch = isGamepad
        rendObj = ROBJ_SOLID
        color = fillBgColor(sf)
        size = [flex(), commonBtnHeight]
        minWidth = SIZE_TO_CONTENT
        behavior = Behaviors.Button
        sound = btnSound
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        onClick = @() close(btn.cb)
        valign = ALIGN_CENTER
        padding = midPadding
        children = [
          isGamepad.value && (sf & S_HOVER) ? hotkeyOnHover : null
          {
            rendObj = ROBJ_TEXT
            text = btn?.name ?? ""
            color =  (sf & S_ACTIVE) != 0 || (sf & S_HOVER) != 0 ? titleTxtColor : defTxtColor
          }.__update(fontLarge)
          isGamepad.value && ((sf & S_HOVER) == 0) ? widthHotkeyOnHover : null
        ]
      }.__update(!needMoveCursor ? {} : {
        key = "selected_menu_elem"
        function onAttach() {
          move_mouse_cursor("selected_menu_elem", false)
        }
      })
    })
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
    rendObj = ROBJ_WORLD_BLUR_PANEL
    color = defItemBlur
  }
  hotkeys = [[
    $"^J:Start | {JB.B} | Esc",
    { action = @() close(), description = loc("Cancel") }
  ]]
  children = content
})


let mkbars = @(sf) {
  rendObj = ROBJ_TEXT
  text = fa["bars"]
  color = sf & S_HOVER ? darkTxtColor : defTxtColor
}.__update(fontFontawesome)

local function mkDropMenuBtn(buttons, watch) {
  let watchTo = type(watch) != "array" ? [watch] : watch
  let menuButtonsUi = mkMenuButtons(buttons, watchTo)
  let onClick = @(event) openMenu(event, menuButtonsUi)
  let gamepadBtn = mkImageCompByDargKey("J:Start", { height = defSize/1.5})
  return watchElemState(function(sf) {
    return {
      watch = isGamepad
      behavior = Behaviors.Button
      onClick
      sound = btnSound
      size = [defSize, defSize+bigPadding]
      padding = [bigPadding, 0, 0, 0]
      valign = ALIGN_BOTTOM
      hotkeys = [[ "^J:Start | Esc", { description = { skip = true } } ]]
      children = {
        rendObj = ROBJ_WORLD_BLUR_PANEL
        fillColor = sf & S_HOVER ? hoverSlotBgColor : 0
        size = [defSize, defSize]
        halign = ALIGN_CENTER
        valign = ALIGN_CENTER
        children = isGamepad.value ? gamepadBtn : mkbars(sf)
      }
    }
  })
}


return mkDropMenuBtn