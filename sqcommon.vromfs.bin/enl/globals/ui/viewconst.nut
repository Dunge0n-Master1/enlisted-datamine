from "%enlSqGlob/ui_library.nut" import *

let isWide = sw(100).tofloat() / sh(100) > 1.7

let selectedTxtColor = Color(0,0,0)
let deadTxtColor = Color(0,0,0)
let defTxtColor = Color(180,180,180)
let titleTxtColor = Color(255,255,255)
let weaponTxtColor = Color(170, 170, 170)
let disabledTxtColor = Color(100,100,100)
let hoverBgColor = Color(205,205,220)
let activeBgColor = Color(180,180,180,255)
let defBgColor = Color(0,0,0,120)
let airHoverBgColor = Color(205,205,220,200)
let airBgColor = Color(0,0,0,120)
let airSelectedBgColor = Color(150,150,150,150)
let defPanelBgColorVer_1 = Color(50,50,50,200)
let smallPadding = hdpx(4)
let bigPadding = hdpx(8)
let tinyOffset = hdpx(12)
let smallOffset = hdpx(24)
let bigOffset = hdpx(48)
let unitSize = hdpx(45) //unit, 1920x1080 - 45x24)
let researchListTabBorder = hdpx(4)

let multySquadPanelSize = [(unitSize * 2.4).tointeger(), (unitSize * 2.4).tointeger()]
let squadSlotHorSize = [hdpxi(660), hdpxi(72)]

let soldierWndWidth = unitSize * 11
let squadPanelWidth = unitSize * 6
let fadedTxtColor = Color(130,130,130,150)

let commonBtnHeight = hdpx(48)

let strokeStyle = {
  fontFx = FFT_GLOW
  fontFxColor = 0xCC000000
  fontFxFactor = min(16, hdpx(16))
}

let shadowStyle = {
  fontFx = FFT_GLOW
  fontFxColor = 0xFF000000
  fontFxFactor = min(hdpx(16), 16)
  fontFxOffsX = hdpx(1)
  fontFxOffsY = hdpx(1)
}

let maxContentWidth = min(hdpx(1920), sw(100))

return {
  isWide
  maxContentWidth
  bigGap = hdpx(10)
  gap = hdpx(5)
  //********************** Enlisted constants **************************/
  selectedBgColor = Color(220,220,220)
  unitSize
  defBgColor
  darkBgColor = Color(0,0,0,180)
  defInsideBgColor = Color(25,25,25,120)
  blurBgColor = Color(150,150,150,255)
  blurBgColorVer_1 = Color(100,150,200,255)
  blurBgFillColor = Color(25, 25, 25, 25)
  textBgBlurColor = Color(180,180,180,255)
  idleBgColor = Color(70,70,70)
  hoverBgColor
  activeBgColor
  opaqueBgColor = Color(20,20,20)
  blockedBgColor = Color(100, 10, 10)
  accentColor = Color(230, 130, 0)
  accentTitleTxtColor = Color(251, 189, 64)

  insideBorderColor = Color(50,50,40,5)

  airBgColor
  airHoverBgColor
  airSelectedBgColor

  defTxtColor
  fadedTxtColor
  disabledTxtColor = disabledTxtColor
  activeTxtColor = Color(220, 220, 220, 255)
  hoverTxtColor = Color(0,0,0)
  noteTxtColor = fadedTxtColor
  selectedTxtColor
  deadTxtColor
  defPanelBgColorVer_1 = defPanelBgColorVer_1
  msgHighlightedTxtColor = Color(210, 170, 20)
  blockedTxtColor = Color(200, 15, 10)
  hasPremiumColor = Color(210, 210, 100)

  titleTxtColor
  activeTitleTxtColor = Color(180, 180, 200)
  hoverTitleTxtColor = Color(220, 220, 230)

  detailsHeaderColor = Color(200,200,220)

  debriefingTabsBarColor = Color(0,0,0,100)
  debriefingDarkColor = Color(0,0,0,180)

  blinkingSignalsGreenNormal = Color(61, 182, 19)
  blinkingSignalsGreenDark = Color(32, 125, 0)

  translucentBgColor = Color(0,0,0,75)
  soldierExpBgColor = Color(0, 0, 0, 100)
  soldierExpColor = Color(239, 219, 100)
  soldierLvlColor = Color(200, 180, 0, 150)
  soldierGainLvlColor = Color(255, 255, 150)
  soldierLockedLvlColor = Color(90, 90, 90)

  spawnReadyColor = Color(50, 150, 50)
  spawnNotReadyColor = Color(180, 70, 70)
  spawnPreparationColor = Color(150, 150, 50)

  smallPadding
  bigPadding
  tinyOffset
  smallOffset
  bigOffset

  windowsInterval = bigPadding

  /* army squad */
  multySquadPanelSize
  squadSlotHorSize
  squadElemsBgColor = Color(60, 60, 60, 150)
  squadElemsBgHoverColor = Color(150, 150, 150, 150)
  squadPromoSlotSize = [flex(), hdpx(420)]
  lockedSquadBgColor = Color(99, 97, 98)
  unlockedSquadBgColor = Color(80, 117, 59)
  progressBorderColor = Color(48,62,66)
  progressExpColor = Color(185, 129, 49)
  progressAddExpColor = Color(205, 155, 60)

  soldierWndWidth
  squadPanelWidth
  perkIconSize = (unitSize * 1.5 - 2 * smallPadding).tointeger()
  perkBigIconSize = [hdpxi(315), hdpxi(430)]
  awardIconSize = (unitSize * 2).tointeger()
  awardIconSpacing = 2 * bigPadding

  rarityColors = [defTxtColor, Color(220, 220, 100)]
  bonusColor = Color(120, 250, 120)
  warningColor = Color(230, 100, 100)

  taskProgressColor = Color(251, 189, 64)
  taskDefColor = Color(125, 125, 125)

  // Premium

  bgPremiumColor = Color(11, 11, 19)
  basePremiumColor = Color(112, 112, 112)

  discountBgColor = Color(0, 120, 0)

  slotBaseSize = [(6 * unitSize).tointeger(), (1.5 * unitSize).tointeger()]
  slotMediumSize = [(4 * unitSize).tointeger(), (1.5 * unitSize).tointeger()]

  commonBtnHeight

  strokeStyle
  shadowStyle

  listCtors = {
    nameColor = @(flags, selected = false)
      selected || (flags & S_HOVER) ? selectedTxtColor : titleTxtColor

    weaponColor = @(flags, selected = false)
      selected || (flags & S_HOVER) ? selectedTxtColor : weaponTxtColor

    txtColor = @(flags, selected = false)
      selected || (flags & S_HOVER) || (flags & S_ACTIVE) ? selectedTxtColor : defTxtColor

    txtDisabledColor = @(flags, selected = false)
      selected || (flags & S_HOVER) ? selectedTxtColor : disabledTxtColor

    bgColor = @(flags, selected = false, idx = 0) selected ? activeBgColor
      : flags & S_HOVER ? hoverBgColor
      : (idx%2==0) ? defBgColor
      : mul_color(defBgColor, 0.65)
  }

  rowBg = @(sf, idx, isSelected = false) isSelected ? Color(70, 70, 70, 25)
    : (sf & S_HOVER) ? Color(10,10,10,25)
    : (idx % 2) ? Color(35, 35, 35, 25)
    : Color(25, 25, 25, 25)

  listBtnAirStyle = function(isSelected, _idx) {
    let res = {
      margin = 0
      textMargin = bigPadding
      borderWidth = 0
      borderRadius = 0
      rendObj = ROBJ_BOX
      style = {
        BgNormal  = airBgColor
        BgHover   = airHoverBgColor
        BgActive  = airHoverBgColor
        BgFocused = airHoverBgColor
      }
    }
    if (isSelected)
      return res.__update({
        fillColor = airSelectedBgColor
        textParams = { color = selectedTxtColor }
      })
    return res
  }

  scrollbarParams = {
    size = [SIZE_TO_CONTENT, flex()]
    skipDirPadNav = true
    barStyle = @(_has_scroll) class {
      _width = fsh(1)
      _height = fsh(1)
      skipDirPadNav = true
    }
    knobStyle = class {
      skipDirPadNav = true
      hoverChild = @(sf) {
        rendObj = ROBJ_BOX
        size = [hdpx(8), flex()]
        borderWidth = [0, hdpx(1), 0, hdpx(1)]
        borderColor = Color(0, 0, 0, 0)
        fillColor = (sf & S_ACTIVE) ? Color(255,255,255)
          : (sf & S_HOVER) ? Color(110, 120, 140, 80)
          : Color(110, 120, 140, 160)
      }
    }
  }

  armyIconHeight = hdpx(50)
  researchItemSize = isWide ? [hdpx(110), hdpx(130)] : [hdpx(83), hdpx(100)]
  researchListTabWidth = hdpx(440)
  researchListTabBorder
  researchListTabPadding = researchListTabBorder + (isWide ? bigPadding * 2 : bigPadding)
  researchHeaderIconHeight = isWide ? hdpx(120) : hdpx(80)
  tablePadding = hdpx(120)
  scrollHeight = hdpx(36)
  vehicleListCardSize = [unitSize * 5, unitSize * 3]
  debriefingArmyIconHeight = hdpx(80)
  inventoryItemDetailsWidth = hdpx(400)
}
