from "%enlSqGlob/ui_library.nut" import *

let { debounce } = require("%sqstd/timers.nut")
let colors = require("%ui/style/colors.nut")
let gamepadImgByKey = require("%ui/components/gamepadImgByKey.nut")
let active_controls = require("%ui/control/active_controls.nut")
let modalPopupWnd = require("%ui/components/modalPopupWnd.nut")
let JB = require("%ui/control/gui_buttons.nut")
let locByPlatform = require("%enlSqGlob/locByPlatform.nut")

const CONTEXT_UID = "contextMenu"

let function listItem(text, action) {
  let group = ElemGroup()
  let stateFlags = Watched(0)
  let height = calc_str_box("A")[1]
  let activeBtn = gamepadImgByKey.mkImageCompByDargKey(JB.A,
    { height = height, hplace = ALIGN_RIGHT, vplace = ALIGN_CENTER})
  return function() {
    let sf = stateFlags.value
    let hover = sf & S_HOVER
    return {
      behavior = [Behaviors.Button]
      clipChildren=true
      rendObj = ROBJ_SOLID
      color = hover ? colors.BtnBgHover : colors.BtnBgNormal
      size = [flex(), SIZE_TO_CONTENT]
      group = group
      watch = [stateFlags, active_controls.isGamepad]
      padding = fsh(0.5)
      onClick = action
      onElemState = @(nsf) stateFlags.update(nsf)

      sound = {
        click  = "ui/button_click"
        hover  = "ui/menu_highlight"
        active = "ui/button_action"
      }

      children = [
        {
          rendObj = ROBJ_TEXT
          behavior = [Behaviors.Marquee]
          scrollOnHover=true
          size=[flex(),SIZE_TO_CONTENT]
          speed = hdpx(100)
          text = text
          group = group
          color = (stateFlags.value & S_HOVER) ? colors.BtnTextHover : colors.BtnTextNormal
        }
        active_controls.isGamepad.value && hover ? activeBtn : null
      ]
    }
  }
}

let function mkMenu(width, actions, uid) {
  let visibleActions = actions.filter(@(a) a?.isVisible.value ?? true)
  let autoHide = debounce(@() modalPopupWnd.remove(uid), 0.01)
  return function() {
    if (visibleActions.len() == 0)
      autoHide() //this will work on hide item, but not work on load menu

    return {
      watch = actions.map(@(a) a?.isVisible).filter(@(w) w != null)
      size = [width, SIZE_TO_CONTENT]
      flow = FLOW_VERTICAL
      children = visibleActions.map(@(item) listItem(
        item?.text ?? locByPlatform(item?.locId),
        function() {
          item.action()
          modalPopupWnd.remove(uid)
        }))
    }
  }
}

let function addContextMenu(x, y, width, actions) {
  if (actions.findvalue(@(a) a?.isVisible.value ?? true) == null)
    return null //no need to open empty menu

  modalPopupWnd.add([x, y], {
    uid = CONTEXT_UID
    popupHalign = ALIGN_LEFT
    popupValign = y > sh(75) ? ALIGN_BOTTOM : ALIGN_TOP
    popupFlow = FLOW_VERTICAL
    moveDuraton = min(0.12 + 0.03 * actions.len(), 0.3) //0.3 sec opening is too slow for small menus
    children = mkMenu(width, actions, CONTEXT_UID)
  })
}

let closeLatestContextMenu = @() modalPopupWnd.remove(CONTEXT_UID)

return {
  addContextMenu
  closeLatestContextMenu
}