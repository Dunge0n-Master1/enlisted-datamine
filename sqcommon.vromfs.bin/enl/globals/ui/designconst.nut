from "%enlSqGlob/ui_library.nut" import *

let columnWidth = hdpx(62).tointeger()
local columnGap = hdpx(16)
let columnCount = ((sw(100).tofloat() + columnGap) / (columnWidth + columnGap)).tointeger()
columnGap = ((sw(100) - columnWidth * columnCount).tofloat() / columnCount).tointeger()
let hdc = @(collumsCount) collumsCount <= 0 ? 0
  : ( columnWidth * collumsCount + columnGap * (collumsCount - 1) ).tointeger()

// BGColors
let panelBgColor = Color(36, 45, 49)

return {
  hdc
  panelBgColor
}