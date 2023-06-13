from "%enlSqGlob/ui_library.nut" import *
let { fontLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { bigPadding, midPadding, titleTxtColor, defTxtColor, commonBorderRadius,
  colPart, hoverSlotBgColor, darkTxtColor
} = require("%enlSqGlob/ui/designConst.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { blinkUnseen } = require("%ui/components/unseenComponents.nut")
let { soundActive } = require("%ui/components/textButton.nut")


let markerTarget = MoveToAreaTarget()

let function requestMoveToElem(elem) {
  let x = elem.getScreenPosX()
  let y = elem.getScreenPosY()
  let w = elem.getWidth()
  let h = elem.getHeight()
  markerTarget.set(x, y, x + w, y + h)
}


let tabTxtStyle = @(sf, isSelected) {
  color = (sf & S_HOVER)
    ? darkTxtColor
    : (sf & S_ACTIVE) || isSelected
      ? titleTxtColor
      : defTxtColor
  fontFx = (sf & S_HOVER) ? null : FFT_GLOW
  fontFxFactor = min(24, hdpx(24))
  fontFxColor = 0xDD000000
}.__update(fontLarge)


let tabBottomPadding = midPadding * 2


let function mkTab(section, action, curSection) {
  let { id, locId, isUnseenWatch = Watched(false), addChild = null } = section
  let isSelected = Computed(@() curSection.value == id)
  local wasSelected = isSelected.value
  return watchElemState(@(sf) {
    watch = isUnseenWatch
    size = [SIZE_TO_CONTENT, flex()]
    halign = ALIGN_CENTER
    behavior = Behaviors.Button
    sound = soundActive
    minWidth = colPart(1.5)
    onClick = action
    children = [
      {
        size = flex()
        margin = [bigPadding, 0, 0, 0]
        rendObj = ROBJ_SOLID
        color = sf & S_HOVER ? hoverSlotBgColor : 0
      }
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
          behavior = [Behaviors.RecalcHandler]
          function onRecalcLayout(initial, elem) {
            if ((initial || !wasSelected) && isSelected.value){
              wasSelected = true
              requestMoveToElem(elem)
            }
          }
        }.__update(tabTxtStyle(sf, isSelected.value))
      }
      isUnseenWatch.value ? blinkUnseen : null
      {size = [flex(),SIZE_TO_CONTENT] children = addChild}
    ]
  })
}

let backgroundMarker = freeze({
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
    fillColor = Color(255,255,255)
  }
})



return {
  mkTab
  backgroundMarker
  requestMoveToElem
}
