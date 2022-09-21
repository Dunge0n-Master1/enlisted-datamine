from "%enlSqGlob/ui_library.nut" import *

let { activeBgColor, panelBgColor, tabBgColor } = require("%enlSqGlob/ui/designConst.nut")

let widgetHoverAnim    = [{ prop = AnimProp.translate, duration = 0.2}]
let widgetStateCommon = @(width) { translate = [width, 0] }
let widgetStateHovered = { translate = [0, 0] }

let movingBlockSize = hdpx(22)
let leftPadding = [0, movingBlockSize, 0, 0]
let rightPadding = [0, 0, 0, movingBlockSize]


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
      color = sf & S_ACTIVE ? activeBgColor : tabBgColor
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
  sound = {
    click  = "ui/enlist/button_click"
    hover  = "ui/enlist/button_highlight"
  }
  children = [
    movingBlock(sf, size[0] - movingBlockSize)
    addChild(sf).__update({ padding = leftPadding })
  ]
})


let mkRightPanelButton = @(addChild, size, onClick) watchElemState(@(sf){
  size
  clipChildren = true
  valign = ALIGN_CENTER
  behavior = Behaviors.Button
  padding = rightPadding
  onClick
  sound = {
    click  = "ui/enlist/button_click"
    hover  = "ui/enlist/button_highlight"
  }
  children = [
    movingBlock(sf, movingBlockSize)
    addChild(sf).__update({ padding = rightPadding })
  ]
})


return {
  mkLeftPanelButton
  mkRightPanelButton
}