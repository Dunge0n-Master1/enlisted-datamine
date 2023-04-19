from "%enlSqGlob/ui_library.nut" import *
let { fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { midPadding, titleTxtColor, defTxtColor, commonBorderRadius, accentColor, colPart
} = require("%enlSqGlob/ui/designConst.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { blinkUnseen } = require("%ui/components/unseenComponents.nut")
let { soundActive } = require("%ui/components/textButton.nut")
let { mkHotkey } = require("%ui/components/uiHotkeysHint.nut")


let markerTarget = MoveToAreaTarget()

let function requestMoveToElem(elem) {
  let x = elem.getScreenPosX()
  let y = elem.getScreenPosY()
  let w = elem.getWidth()
  let h = elem.getHeight()
  markerTarget.set(x, y, x + w, y + h)
}


let tabTxtStyle = @(sf, isSelected) {
  color = (sf & S_ACTIVE) || isSelected ? titleTxtColor
    : (sf & S_HOVER) ? accentColor
    : defTxtColor
}.__update(fontXLarge)


let tabBottomPadding = midPadding * 2


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
          padding = [0, midPadding, tabBottomPadding, midPadding]
          valign = ALIGN_BOTTOM
          key = id
          behavior = [Behaviors.Button, Behaviors.RecalcHandler]
          sound = soundActive
          function onClick() { action() }
          function onRecalcLayout(initial, elem) {
            if ((initial || !wasSelected) && isSelected.value){
              wasSelected = true
              requestMoveToElem(elem)
            }
          }
        }.__update(tabTxtStyle(sf, isSelected.value))
      }
      isUnseenWatch.value ? blinkUnseen : null
    ]
  })
}

let backgroundMarker = {
  behavior = Behaviors.MoveToArea
  subPixel = true
  target = markerTarget
  viscosity = 0.1
  valign = ALIGN_BOTTOM
  children = {
    rendObj = ROBJ_BOX
    size = [flex(), colPart(0.06)]
    borderWidth = 0
    borderRadius = commonBorderRadius
    fillColor = accentColor
  }
}


let mkGamepadNav = @(key, action) mkHotkey(key, action, {
  size = [SIZE_TO_CONTENT, flex()]
  valign = ALIGN_TOP
  pos = [0, tabBottomPadding]
})


return {
  mkTab
  backgroundMarker
  requestMoveToElem
  mkGamepadNav
}
