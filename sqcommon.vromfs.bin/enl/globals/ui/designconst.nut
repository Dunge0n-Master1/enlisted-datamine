from "%enlSqGlob/ui_library.nut" import *

let { safeAreaHorPadding } = require("%enlSqGlob/safeArea.nut")

let maxColumnWidth = hdpx(62).tointeger()

local sidePadding = max(sw(100) * 0.017, safeAreaHorPadding.value).tointeger()
let contentWidth = (sw(100) - sidePadding * 2).tointeger()
let columnWidth = min(contentWidth * 0.0335, maxColumnWidth).tointeger()
let columnGap = (columnWidth * 0.259).tointeger()
let oneColWithGap = columnWidth + columnGap

local columnsCount = max((contentWidth + columnGap) / oneColWithGap, 24).tointeger()
local emptySpace = (contentWidth - ((columnsCount * columnWidth)
  + (columnsCount - 1) * columnGap)).tointeger()
while (emptySpace > oneColWithGap) {
  columnsCount++
  emptySpace-= oneColWithGap
}

if (emptySpace / 2 > sidePadding)
  sidePadding = emptySpace / 2


let colFull = @(colCount) colCount <= 0 ? 0
  : columnWidth * colCount + columnGap * (colCount - 1)

let function colPart(delta) {
  local res = (delta * columnWidth + 0.5).tointeger()
  return res + (res % 2)
}


let activeBgColor = 0xFF1868E8

return {
  colFull
  columnWidth
  colPart


  // Gaps
  columnGap
  sidePadding
  bigPadding = colPart(0.194) // 12px
  midPadding = colPart(0.13) // 8px
  smallPadding = colPart(0.065) //4px


  //Size
  commonBtnHeight = colPart(0.775)
  smallBtnHeight = colPart(0.485)
  maxContentWidth = hdpx(1920)
  commonBorderRadius = hdpx(2)

  // BGColors
  panelBgColor  = 0xFF1B262F
  hoverBgColor  = 0xFF45545C
  accentColor   = 0xFFF8BD41
  disabledBgColor = 0xFF292E33
  blockedBgColor = 0xFFD6603C
  tabBgColor    = activeBgColor
  activeBgColor

  //BdColor
  defBdColor    = 0xFF45545C
  hoverBdColor  = 0xFF1B262F
  activeBdColor = 0xFF1B262F

  // TxtColor
  disabledTxtColor = 0xFF545A5D
  defTxtColor   = 0xFFB4B4B4
  hoverTxtColor = 0xFFD4D4D4
  titleTxtColor = 0xFFFAFAFA
  darkTxtColor = 0xFF010101
}