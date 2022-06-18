from "%enlSqGlob/ui_library.nut" import *

let { hoverBgColor } = require("%enlSqGlob/ui/viewConst.nut")

let widgetHoverAnim    = [{ prop = AnimProp.translate, duration = 0.2}]
let widgetStateCommon = @(width) { translate = [width, 0] }
let widgetStateHovered = { translate = [0, 0] }

let widgetButtonBgNormal = 0xfa015ea2
let widgetButtonBgActive = 0xfa0182b5

let moovingBlockSize = hdpx(20)

let moovingBlock = @(sf, width){
  rendObj = ROBJ_SOLID
  size = flex()
  color = sf & S_ACTIVE ? widgetButtonBgActive : widgetButtonBgNormal
  transitions = widgetHoverAnim
  transform = sf != 0 ? widgetStateHovered : widgetStateCommon(width - moovingBlockSize)
}

let mkPanelButton = @(addChild, size, onClick, parentSf = null) watchElemState(@(sf){
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
    {
      size = flex()
      children = [
        {
          rendObj = ROBJ_WORLD_BLUR_PANEL
          size = flex()
          color = hoverBgColor
        }
        moovingBlock(parentSf ?? sf, size[0])
      ]
    }
    addChild(parentSf ?? sf).__update({padding = [0, moovingBlockSize, 0, 0]})
  ]
})

return mkPanelButton