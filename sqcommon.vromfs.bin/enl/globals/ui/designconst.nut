from "%enlSqGlob/ui_library.nut" import *

let { safeAreaHorPadding } = require("%enlSqGlob/safeArea.nut")
let { mkColoredGradientY, mkDiagonalColoredGradient, mkColoredGradientX
} = require("%enlSqGlob/ui/gradients.nut")

let maxColumnWidth = hdpx(62).tointeger()
const DEF_COLLS_COUNT = 24

local sidePadding = max(sw(100) * 0.017, safeAreaHorPadding.value).tointeger()
let contentWidth = (sw(100) - sidePadding * 2).tointeger()
let columnWidth = min(contentWidth * 0.0335, maxColumnWidth).tointeger()
let columnGap = (columnWidth * 0.259).tointeger()
let oneColWithGap = columnWidth + columnGap

local columnsCount = max((contentWidth + columnGap) / oneColWithGap, DEF_COLLS_COUNT).tointeger()
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

let colFullMin = @(cols) colFull(max(cols, cols + columnsCount - DEF_COLLS_COUNT))

let accentColor = 0xFFF8BD41
let footerContentHeight = colPart(1.14)

let lightDefBgColor = 0xFF42516C
let darkDefBgColor = 0xFF2B2D44
let lightHoverBgColor = 0xFF5979B4
let darkHoverBgColor = darkDefBgColor

let defSlotBgImg         = mkDiagonalColoredGradient(0xFF444555, 0xFF181F34)
let hoverSlotBgImg       = mkDiagonalColoredGradient(lightHoverBgColor, darkDefBgColor)
let defAvailSlotBgImg    = mkDiagonalColoredGradient(0xFF596756, 0xFF293924)
let hoverAvailSlotBgImg  = mkDiagonalColoredGradient(0xFF7EA367, 0xFF3A4B2D)
let defLockedSlotBgImg   = mkDiagonalColoredGradient(0xFF582727, 0xFF582727)
let hoverLockedSlotBgImg = mkDiagonalColoredGradient(0xFF8D3434, 0xFF8D3434)
let levelNestGradient    = mkColoredGradientX(0x22FFFFFF, 0x00FFFFFF, 6, false)


let defVertGradientImg = mkColoredGradientY(lightDefBgColor, darkDefBgColor)
let hoverVertGradientImg = mkColoredGradientY(lightHoverBgColor, darkHoverBgColor)
let defHorGradientImg = mkColoredGradientX(lightDefBgColor, darkDefBgColor)
let hoverHorGradientImg = mkColoredGradientX(lightHoverBgColor, darkHoverBgColor)

return {
  colFull
  columnWidth
  colPart
  colFullMin


  //Gradients
  defVertGradientImg
  hoverVertGradientImg
  defHorGradientImg
  hoverHorGradientImg

  // Gaps
  columnGap
  sidePadding
  bigPadding = colPart(0.194) // 12px
  midPadding = colPart(0.13) // 8px
  smallPadding = colPart(0.065) //4px
  miniPadding = colPart(0.04) //2px


  //Size
  commonBtnHeight = colPart(0.775)
  smallBtnHeight = colPart(0.485)
  maxContentWidth = hdpx(1920)
  commonBorderRadius = hdpx(2)
  startBtnWidth = colFull(5)
  navHeight = colPart(1.2)
  fastAccessIconHeight = colPart(0.52)
  footerContentHeight
  commonWndPadding = [0, sidePadding, footerContentHeight, sidePadding]


  panelBgColor  = 0xFF132438
  transpPanelBgColor = 0x990A131A
  hoverBgColor  = 0xFF19304b
  disabledBgColor = 0xFF292E33
  blockedBgColor = 0xFFD6603C
  activeBgColor = accentColor
  accentColor
  topWndBgColor = 0xDD090929
  bottomWndBgColor = 0xDD220202
  discountBgColor = 0xFFF8BD41
  enabledIndicatorColor = 0xFF65FE7A
  disabledIndicatorColor = 0xFFD9281D
  selectedBgColor = 0xFFF8BD41
  lightDefBgColor
  darkDefBgColor

  //BdColor
  defBdColor    = 0xFF45545C
  hoverBdColor  = 0xFF132438
  activeBdColor = 0xFF132438
  blinkBdColor  = 0xFFABB3BA

  // TxtColor
  disabledTxtColor = 0xFF545A5D
  defTxtColor   = 0xFFB4B4B4
  hoverTxtColor = 0xFFD4D4D4
  titleTxtColor = 0xFFFAFAFA
  darkTxtColor = 0xFF010101
  attentionTxtColor = 0xFFFFBE30
  negativeTxtColor = 0xFFEE5656

  // ItemSlots
  lockedItemIdleBgColor  = 0xFF312424
  lockedItemHoverBgColor = 0xFF3A2828
  debugItemBgColor       = 0xFF282939

  // soldier and squad slot color
  defSlotBgImg
  hoverSlotBgImg
  defAvailSlotBgImg
  hoverAvailSlotBgImg
  defLockedSlotBgImg
  hoverLockedSlotBgImg
  levelNestGradient
  haveLevelColor = 0xFFF8BD41
  gainLevelColor = 0xFFFFCE68
  lockLevelColor = 0xFFAAAAAA
}
