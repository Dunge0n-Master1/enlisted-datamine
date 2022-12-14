from "%enlSqGlob/ui_library.nut" import *

let { activeBgColor, panelBgColor, accentColor, colPart
} = require("%enlSqGlob/ui/designConst.nut")
let { isNewDesign } = require("%enlSqGlob/designState.nut")
let { soundDefault } = require("%ui/components/textButton.nut")


let widgetHoverAnim = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutCubic}]
let widgetStateCommon = @(width) { translate = [width, 0] }
let widgetStateHovered = { translate = [0, 0] }

let movingBlockSize = isNewDesign.value ? colPart(0.36) : hdpx(22)
let rightPadding = [0, movingBlockSize, 0, 0]
let leftPadding = [0, 0, 0, movingBlockSize]


let movingBlock = @(sf, amimDirection) {
  size = flex()
  children = [
    {
      rendObj = ROBJ_SOLID
      size = flex()
      color = panelBgColor
    }
    {
      rendObj = ROBJ_SOLID
      size = flex()
      color = sf & S_ACTIVE ? activeBgColor : accentColor
      transitions = widgetHoverAnim
      transform = sf != 0 ? widgetStateHovered : widgetStateCommon(amimDirection)
    }
  ]
}


let mkLeftPanelButton = @(addChild, size, onClick) watchElemState(@(sf){
  size
  clipChildren = true
  valign = ALIGN_CENTER
  behavior = Behaviors.Button
  onClick
  sound = soundDefault
  children = [
    movingBlock(sf, size[0] - movingBlockSize)
    addChild(sf).__update({ padding = rightPadding })
  ]
})


let mkRightPanelButton = @(addChild, size, onClick) watchElemState(@(sf){
  size
  clipChildren = true
  valign = ALIGN_CENTER
  behavior = Behaviors.Button
  onClick
  sound = soundDefault
  children = [
    movingBlock(sf, -size[0] + movingBlockSize)
    addChild(sf).__update({ padding = leftPadding })
  ]
})


return {
  mkLeftPanelButton
  mkRightPanelButton
}