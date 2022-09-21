from "%enlSqGlob/ui_library.nut" import *
let { fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { midPadding, titleTxtColor, defTxtColor, hoverTxtColor,
  smallPadding, tabBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let unseenSignal = require("%ui/components/unseenSignal.nut")
let { premiumBtnSize } = require("%enlist/currency/premiumComp.nut")

let markerTarget = MoveToAreaTarget()

let function requestMoveToElem(elem) {
  let x = elem.getScreenPosX()
  let y = elem.getScreenPosY()
  let w = elem.getWidth()
  let h = elem.getHeight()
  markerTarget.set(x, y, x + w, y + h)
}

let tabUnseenSignal = unseenSignal(0.8).__update({
  hplace = ALIGN_RIGHT
})

let tabTxtStyle = @(sf, isSelected) {
  color = (sf & S_ACTIVE) || isSelected ? titleTxtColor
    : (sf & S_HOVER) ? hoverTxtColor
    : defTxtColor
}.__update(fontXLarge)

let function mkTab(tab, curSection) {
  let { action, id, locId, isUnseenWatch = Watched(false) } = tab
  let isSelected = Computed(@() curSection.value == id)
  local wasSelected = isSelected.value
  return watchElemState(@(sf) {
    watch = isUnseenWatch
    size = [SIZE_TO_CONTENT, flex()]
    behavior = Behaviors.Button
    children = [
      function() {
        if (!isSelected.value)
          wasSelected = false
        return {
          watch = isSelected
          rendObj = ROBJ_TEXT
          text = utf8ToUpper(loc(locId))
          size = [SIZE_TO_CONTENT, flex()]
          padding = [0, midPadding , midPadding * 2, midPadding]
          valign = ALIGN_BOTTOM
          key = id
          behavior = [Behaviors.Button, Behaviors.RecalcHandler]
          sound = {
            click  = "ui/enlist/button_click"
            hover = "ui/enlist/button_highlight"
            active = "ui/enlist/button_action"
          }
          function onClick() { action() }
          function onRecalcLayout(initial, elem) {
            if ((initial || !wasSelected) && isSelected.value){
              wasSelected = true
              requestMoveToElem(elem)
            }
          }
        }.__update(tabTxtStyle(sf, isSelected.value))
      }
      isUnseenWatch.value ? tabUnseenSignal : null
    ]
  })
}

let backgroundMarker = {
  flow = FLOW_VERTICAL
  gap = smallPadding
  behavior = Behaviors.MoveToArea
  target = markerTarget
  viscosity = 0.1
  children = [
    {
      size = [flex(), premiumBtnSize]
      rendObj = ROBJ_SOLID
      color = tabBgColor
    }
    {
      size = flex()
      rendObj = ROBJ_SOLID
      color = tabBgColor /* TODO: Gradient with opacity in center enstead of 2 solid blocks */
    }
  ]
}


return {
  mkTab
  backgroundMarker
  requestMoveToElem
}
