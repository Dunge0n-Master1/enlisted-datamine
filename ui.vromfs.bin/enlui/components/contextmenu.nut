from "%enlSqGlob/ui_library.nut" import *

let { fontSub } = require("%enlSqGlob/ui/fontsStyle.nut")
let { debounce } = require("%sqstd/timers.nut")
let { panelBgColor, hoverPanelBgColor, defBdColor, titleTxtColor, hoverTxtColor, midPadding,
  smallPadding
} = require("%enlSqGlob/ui/designConst.nut")
let gamepadImgByKey = require("%ui/components/gamepadImgByKey.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let JB = require("%ui/control/gui_buttons.nut")
let locByPlatform = require("%enlSqGlob/locByPlatform.nut")
let { isGamepad } = require("%ui/control/active_controls.nut")

let defTxtStyle = freeze({ color = titleTxtColor }.__update(fontSub))
let hoverTxtStyle = freeze({ color = hoverTxtColor }.__update(fontSub))
const CONTEXT_UID = "contextMenu"

let activeBtn = gamepadImgByKey.mkImageCompByDargKey(JB.A, {
  height = defTxtStyle.fontSize*1.6
  halign = ALIGN_CENTER
})

let sound = freeze({
  click  = "ui/button_click"
  hover  = "ui/menu_highlight"
  active = "ui/button_action"
})

let listItem = @(text, action) watchElemState(@(sf) {
  watch = isGamepad
  behavior = Behaviors.Button
  clipChildren = true
  rendObj = ROBJ_SOLID
  color = sf & S_HOVER ? hoverPanelBgColor : panelBgColor
  size = [flex(), SIZE_TO_CONTENT]
  padding = midPadding
  onClick = action
  sound
  valign = ALIGN_CENTER
  children = [
    {
      rendObj = ROBJ_TEXT
      behavior = Behaviors.Marquee
      size = [flex(), SIZE_TO_CONTENT]
      scrollOnHover = true
      speed = hdpx(93)
      text
    }.__update(sf & S_HOVER ? hoverTxtStyle : defTxtStyle)
    isGamepad.value && (sf & S_HOVER)
      ? {size = [SIZE_TO_CONTENT, 0], vplace = ALIGN_CENTER, valign = ALIGN_CENTER, hplace = ALIGN_RIGHT, children = activeBtn}
      : null
  ]
})

let function mkMenu(width, actions) {
  let visibleActions = actions.filter(@(a) a?.isVisible.value ?? true)
  let autoHide = debounce(@() modalPopupWnd.remove(CONTEXT_UID), 0.01)
  return function() {
    if (visibleActions.len() == 0)
      autoHide() //this will work on hide item, but not work on load menu

    return {
      watch = actions.map(@(a) a?.isVisible).filter(@(w) w != null)
      size = [width, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      gap = {
        rendObj = ROBJ_SOLID
        size = [flex(), hdpx(1)]
        color = defBdColor
      }
      children = visibleActions.map(@(item) listItem(
        item?.text ?? locByPlatform(item?.locId),
        function() {
          item.action()
          modalPopupWnd.remove(CONTEXT_UID)
        }))
    }
  }
}

let function addContextMenu(x, y, width, actions) {
  if (actions.findvalue(@(a) a?.isVisible.value ?? true) == null)
    return null //no need to open empty menu

  modalPopupWnd.add([x, y], {
    uid = CONTEXT_UID
    rendObj = ROBJ_SOLID
    padding = smallPadding
    color = defBdColor
    popupHalign = ALIGN_LEFT
    popupValign = y > sh(75) ? ALIGN_BOTTOM : ALIGN_TOP
    popupFlow = FLOW_VERTICAL
    moveDuraton = min(0.12 + 0.03 * actions.len(), 0.3) //0.3 sec opening is too slow for small menus
    children = mkMenu(width, actions)
  })
}

let closeLatestContextMenu = @() modalPopupWnd.remove(CONTEXT_UID)

return {
  addContextMenu
  closeLatestContextMenu
}