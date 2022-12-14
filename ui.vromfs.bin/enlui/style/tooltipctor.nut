from "%enlSqGlob/ui_library.nut" import *

let { panelBgColor, midPadding, defBdColor, commonBorderRadius
} = require("%enlSqGlob/ui/designConst.nut")

return @(content, size = SIZE_TO_CONTENT) {
  rendObj = ROBJ_BOX
  fillColor = panelBgColor
  borderColor = defBdColor
  borderWidth = hdpx(1)
  borderRadius = commonBorderRadius
  size
  padding = midPadding
  children = content
}