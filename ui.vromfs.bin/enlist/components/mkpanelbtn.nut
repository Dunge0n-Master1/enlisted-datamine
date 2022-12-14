from "%enlSqGlob/ui_library.nut" import *

let { colPart, hoverHorGradientImg, midPadding,  lightDefBgColor, darkDefBgColor
} = require("%enlSqGlob/ui/designConst.nut")
let { soundDefault } = require("%ui/components/textButton.nut")
let { mkColoredGradientX } = require("%enlSqGlob/ui/gradients.nut")


let widgetHoverAnim = [{ prop = AnimProp.translate, duration = 0.2, easing = InOutCubic}]
let widgetStateCommon = @(width) { translate = [width, 0] }
let widgetStateHovered = { translate = [0, 0] }

let movingBlockSize = colPart(0.74)
let iconSize = movingBlockSize - midPadding * 2
let rightPadding = [0, movingBlockSize, 0, 0]
let leftPadding = [0, 0, 0, movingBlockSize]
let invertedHorGradient = mkColoredGradientX(darkDefBgColor, lightDefBgColor)


let movingBlock = @(sf, amimDirection, icon, isLeft = true) {
  size = flex()
  children = [
    {
      rendObj = ROBJ_SOLID
      size = flex()
      color = 0xFFFFFFFF
      opacity = 0.1
    }
    {
      rendObj = ROBJ_IMAGE
      size = flex()
      image = isLeft ?invertedHorGradient : hoverHorGradientImg
      transitions = widgetHoverAnim
      transform = sf != 0 ? widgetStateHovered : widgetStateCommon(amimDirection)
    }
    icon == null ? null : {
      size = [iconSize, iconSize]
      rendObj = ROBJ_IMAGE
      image = Picture($"{icon}:{iconSize}:{iconSize}:K")
      vplace = ALIGN_CENTER
      hplace = isLeft ? ALIGN_RIGHT : ALIGN_LEFT
      margin = [0, midPadding]
    }
  ]
}


let mkLeftPanelButton = @(addChild, size, onClick, icon = null) watchElemState(@(sf){
  size
  clipChildren = true
  valign = ALIGN_CENTER
  behavior = Behaviors.Button
  onClick
  sound = soundDefault
  children = [
    movingBlock(sf, size[0] - movingBlockSize, icon)
    addChild(sf).__update({ padding = rightPadding })
  ]
})


let mkRightPanelButton = @(addChild, size, onClick, icon = null) watchElemState(@(sf){
  size
  clipChildren = true
  valign = ALIGN_CENTER
  behavior = Behaviors.Button
  onClick
  sound = soundDefault
  children = [
    movingBlock(sf, -size[0] + movingBlockSize, icon, false)
    addChild(sf).__update({ padding = leftPadding } )
  ]
})


return {
  mkLeftPanelButton
  mkRightPanelButton
}