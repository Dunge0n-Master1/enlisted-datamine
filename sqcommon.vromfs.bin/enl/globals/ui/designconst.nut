from "%enlSqGlob/ui_library.nut" import *

let { safeAreaVerPadding } = require("%enlSqGlob/safeArea.nut")
let { mkColoredGradientY, mkColoredGradientX } = require("%enlSqGlob/ui/gradients.nut")

let panelBgColor  = 0xFF313C45
let footerContentHeight = hdpx(36) + safeAreaVerPadding.value


let levelNestGradient    = mkColoredGradientX({colorLeft=0x00FFFFFF, colorRight=0x22FFFFFF, width=6, isAlphaPremultiplied=false})
let hoverLevelNestGradient = mkColoredGradientX({colorLeft=0x00000000, colorRight=0x33555555, width=6, isAlphaPremultiplied=false})


let lineGradient = mkColoredGradientX({colorLeft=0x5AFFFFFF, colorRight=0x00FFFFFF, width=12, isAlphaPremultiplied=false})
let highlightLineHgt = hdpx(4)
let mkHighlightLine = @(isTop = true) freeze({
  rendObj = ROBJ_IMAGE
  size = [flex(), highlightLineHgt]
  image = lineGradient
  vplace = isTop ? ALIGN_TOP : ALIGN_BOTTOM
})

let highlightLineTop = mkHighlightLine()
let highlightLineBottom = mkHighlightLine(false)

let lineVertGradient = mkColoredGradientY({colorTop=0x5AFFFFFF, colorBottom=0x00FFFFFF, height=12, isAlphaPremultiplied=false})

let mkHighlightVertLine = @(isLeft = true) freeze({
  rendObj = ROBJ_IMAGE
  size = [highlightLineHgt, flex()]
  image = lineVertGradient
  hplace = isLeft ? ALIGN_LEFT : ALIGN_RIGHT
})
let highlightVertLineLeft = mkHighlightVertLine()
let highlightVertLineRight = mkHighlightVertLine(false)

let mkAnimationList = @(delay, toLeft = true, trigger = null) [
  { prop = AnimProp.opacity, from = 0, to = 0, duration = delay, trigger,
    play = (trigger == null) }
  { prop = AnimProp.opacity, from = 0, to = 1, delay, duration = 0.2, trigger,
    play = (trigger == null) }
  toLeft
    ? { prop = AnimProp.translate, from = [sw(20),0], to = [0,0], delay, trigger,
        duration = 0.2, easing = OutQuart, play = (trigger == null) }
    : { prop = AnimProp.translate, from = [-sw(20),0], to = [0,0], delay, trigger,
        duration = 0.2, easing = OutQuart, play = (trigger == null) }
  { prop = AnimProp.opacity, from = 1, to = 0, duration = 0.2, playFadeOut = true }
]

const DEF_APPEARANCE_TIME = 0.4
let appearanceAnim = @(delay, toLeft = true, trigger = null) {
  transform = {}
  animations = mkAnimationList(delay, toLeft)
    .extend(trigger != null ? mkAnimationList(delay, toLeft, trigger) : [])
}

let defTxtColor = 0xFFB3BDC1

let mkTimerIcon = @(size = hdpxi(22), override = {}) {
  rendObj = ROBJ_IMAGE
  size = [size, size]
  image = Picture("ui/skin#/battlepass/boost_time.svg:{0}:{0}:K".subst(size))
  color =  defTxtColor
}.__update(override)

return {
  //Gradients
  highlightLineTop
  highlightLineBottom
  highlightLineHgt
  highlightVertLineLeft
  highlightVertLineRight


  // Gaps
  largePadding = hdpxi(16)
  sidePadding = hdpxi(32)
  bigPadding = hdpxi(12)
  midPadding = hdpxi(8)
  smallPadding = hdpxi(4)
  miniPadding = hdpxi(2)
  contentGap = hdpxi(68)


  //Size
  commonBtnHeight = hdpx(48)
  smallBtnHeight = hdpx(30)
  maxContentWidth = hdpx(1920)
  commonBorderRadius = hdpx(2)
  startBtnWidth = fsh(34.6)
  navHeight = hdpx(74)
  contentOffset = hdpx(20)
  mainContentOffset = hdpx(96)
  selectionLineHeight = hdpx(4)
  selectionLineOffset = hdpx(6)
  fastAccessIconHeight = hdpx(32)
  footerContentHeight
  hotkeysBarHeight = hdpx(22)
  navigationBtnHeight = hdpx(62)
  inventoryItemDetailsWidth = hdpx(378)

  //BgColor
  defItemBlur = 0xFFA0A2A3
  defSlotBgColor = 0x99303841
  hoverSlotBgColor = 0xFFA0A2A3
  reseveSlotBgColor = 0xFF424C37
  defLockedSlotBgColor = 0xFF402729
  hoverLockedSlotBgColor = 0xFF624A4D
  enableItemIdleBgColor  = 0x99596756
  panelBgColor
  selectedPanelBgColor = mul_color(panelBgColor, 1.5)
  transpPanelBgColor = 0xAA313C45
  hoverPanelBgColor = 0xFF59676E
  darkPanelBgColor = 0xFF13181F
  transpDarkPanelBgColor = 0x5513181F
  transpBgColor = 0x88111111
  fullTransparentBgColor = 0x00000000
  disabledBgColor = 0xFF292E33
  accentColor = 0xFFFAFAFA
  brightAccentColor = 0xFFFCB11D
  discountBgColor = 0xFFF8BD41
  modsBgColor = 0xFF13181F
  totalBlack = 0xFF000000

  squadSlotBgIdleColor = 0x99303841
  squadSlotBgHoverColor = 0xFFA0A2A3
  squadSlotBgActiveColor = 0xFF4A5A68
  squadSlotBgAlertColor = 0x77330000

  //BdColor
  defBdColor    = 0xFFB3BDC1
  disabledBdColor = 0xFF4B575D
  hoverBdColor  = 0xFF132438

  // TxtColor
  disabledTxtColor = 0xFF4B575D
  weakTxtColor  = 0xFFA4A4A4
  defTxtColor
  hoverTxtColor = 0xFFD4D4D4
  titleTxtColor = 0xFFFAFAFA
  hoverSlotTxtColor = 0xFF404040
  darkTxtColor = 0xFF313841
  attentionTxtColor = 0xFFFFBE30
  negativeTxtColor = 0xFFEE5656
  positiveTxtColor = 0xFF8FEE56
  completedTxtColor = 0xFF2968E9
  deadTxtColor = 0xAA101010

  // soldier and squad slot color
  levelNestGradient
  hoverLevelNestGradient
  haveLevelColor = 0xFFF8BD41
  gainLevelColor = 0xFFFFCE68
  lockLevelColor = 0xFFAAAAAA

  unseenColor = 0xFF00FF6C

  //Animations
  rightAppearanceAnim = @(delay = DEF_APPEARANCE_TIME, trigger = null)
    appearanceAnim(delay, false, trigger)
  leftAppearanceAnim = @(delay = DEF_APPEARANCE_TIME, trigger = null)
    appearanceAnim(delay, true, trigger)
  DEF_APPEARANCE_TIME

  mkTimerIcon
}
