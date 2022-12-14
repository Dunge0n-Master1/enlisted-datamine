from "%enlSqGlob/ui_library.nut" import *

let faComp = require("%ui/components/faComp.nut")

let { fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { getObjectName } = require("%enlSqGlob/ui/itemsInfo.nut")
let {
  mkClassIcon, mkKindIcon, levelBlock, mkSoldierBadgePhoto,
  mkSoldierTier, mkClassName, mkSoldierAnim
} = require("soldiersComps.nut")
let {
  colFull, colPart, columnGap, smallPadding, commonBorderRadius,
  accentColor, panelBgColor, hoverTxtColor, titleTxtColor, miniPadding,
  defSlotBgImg, hoverSlotBgImg, defAvailSlotBgImg, hoverAvailSlotBgImg,
  defLockedSlotBgImg, hoverLockedSlotBgImg, levelNestGradient, midPadding
} = require("%enlSqGlob/ui/designConst.nut")


const SQUAD_COLOR_SCHEME_ID = "squad"
const RESERVE_COLOR_SCHEME_ID = "reserve"
const LOCKED_COLOR_SCHEME_ID = "locked"


let selectionLineHeight = colPart(0.06)
let soldierCardSize = [colFull(2), colPart(1.02)]
let premClassSize = colPart(0.4)

let slotIconColor = 0xFF45545C
let slotIconHoverColor = 0xFF6A7B84


let soldierBgSchemes = {
  [SQUAD_COLOR_SCHEME_ID] = @(flags, isSelected) isSelected ? hoverSlotBgImg
    : flags & S_HOVER ? hoverSlotBgImg
    : defSlotBgImg,
  [RESERVE_COLOR_SCHEME_ID] = @(flags, isSelected) isSelected ? hoverAvailSlotBgImg
    : flags & S_HOVER ? hoverAvailSlotBgImg
    : defAvailSlotBgImg,
  [LOCKED_COLOR_SCHEME_ID] = @(flags, isSelected) isSelected ? hoverLockedSlotBgImg
    : flags & S_HOVER ? hoverLockedSlotBgImg
    : defLockedSlotBgImg
}


let nameTxtStyle = { color = titleTxtColor }.__update(fontXLarge)


let selectionLine = {
  size = [flex(), selectionLineHeight]
  vplace = ALIGN_BOTTOM
  pos = [0, selectionLineHeight * 2]
  rendObj = ROBJ_BOX
  borderWidth = 0
  borderRadius = commonBorderRadius
  fillColor = accentColor
}


let buyIconSize = colPart(0.6)
let mkEmptyArrow = @(sf, isSelected, hasBlink)
  faComp("angle-double-down", {
    fontSize = buyIconSize
    color = isSelected || hasBlink ? hoverTxtColor
      : (sf & S_HOVER) != 0 ? slotIconHoverColor
      : slotIconColor
  }).__update(!hasBlink || isSelected ? {}
    : {
        animations = [{
          prop = AnimProp.opacity, from = 1, to = 0.5, duration = 1,
          play = true, loop = true, easing = CosineFull
        }]
      })

let mkEmptySoldierBadge = @(sf = 0, isSelected = false, hasBlink = false, isBuyStyle = false) {
  size = soldierCardSize
  flow = FLOW_VERTICAL
  halign = ALIGN_CENTER
  valign = ALIGN_CENTER
  rendObj = ROBJ_BOX
  borderRadius = commonBorderRadius
  borderWidth = hdpx(1)
  borderColor = sf & S_HOVER ? slotIconHoverColor : slotIconColor
  fillColor = isSelected ? panelBgColor : null
  children = isBuyStyle
    ? {
        rendObj = ROBJ_IMAGE
        size = [buyIconSize, buyIconSize]
        image = Picture("!ui/squads/plus.svg:{0}:{0}:K".subst(buyIconSize))
      }
    : mkEmptyArrow(sf, isSelected, hasBlink)
}


let function mkSoldierBadge(
  idx, soldier, isSelected, sf = 0, onClick = null, colorScemeId = SQUAD_COLOR_SCHEME_ID
) {
  let {
    guid, armyId, tier, sKind, sClass, photo, perksCount, perksLevel, maxLevel,
    thresholdColor = null, sClassRare = null, isPremium = false
  } = soldier
  return {
    key = $"soldier_badge_{guid}_{idx}"
    size = soldierCardSize
    rendObj = ROBJ_MASK
    image = Picture("ui/uiskin/soldier_slot_mask.png")
    behavior = onClick == null ? null : Behaviors.Button
    onClick
    children = [
      {
        size = flex()
        rendObj = ROBJ_IMAGE
        image = soldierBgSchemes[colorScemeId](sf, isSelected)
      }
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        children = [
          {
            children = [
              mkSoldierBadgePhoto(photo)
              isPremium ? mkClassIcon(armyId, sClass, {}, premClassSize) : null
            ]
          }
          {
            size = flex()
            children = [
              {
                size = [flex(), SIZE_TO_CONTENT]
                flow = FLOW_HORIZONTAL
                gap = { size = flex() }
                padding = [miniPadding, midPadding]
                children = [
                  mkKindIcon(sKind, sClassRare)
                  isPremium ? null : mkClassIcon(armyId, sClass)
                ]
              }
              {
                size = [pw(75), SIZE_TO_CONTENT]
                padding = miniPadding
                hplace = ALIGN_RIGHT
                halign = ALIGN_RIGHT
                vplace = ALIGN_BOTTOM
                rendObj = ROBJ_IMAGE
                image = levelNestGradient
                children = levelBlock({
                  guid
                  tier
                  thresholdColor
                  curLevel = perksCount
                  leftLevel = max(perksLevel - perksCount, 0)
                  lockedLevel = max(maxLevel - perksLevel, 0)
                  hasLeftLevelBlink = true
                  isFreemiumMode = thresholdColor != null
                })
              }
            ]
          }
        ]
      }
      isSelected ? selectionLine : null
    ]
  }
}


let function mkSoldierPresentation(soldier) {
  let {
    armyId, guid, tier, sKind, sClass, sClassRare,
    perksCount, perksLevel, maxLevel, thresholdColor
  } = soldier
  return {
    flow = FLOW_VERTICAL
    gap = smallPadding
    halign = ALIGN_CENTER
    children = [
      {
        key = $"soldier_{guid}_icons"
        flow = FLOW_HORIZONTAL
        gap = smallPadding
        children = [
          mkKindIcon(sKind, sClassRare)
          mkClassIcon(armyId, sClass, { hplace = ALIGN_RIGHT })
        ]
      }.__update(mkSoldierAnim(0.3))
      {
        key = $"soldier_{guid}_class"
        flow = FLOW_HORIZONTAL
        gap = columnGap
        children = [
          mkClassName(sClass, sKind, sClassRare)
          mkSoldierTier(tier)
        ]
      }.__update(mkSoldierAnim(0.4))
      {
        key = $"soldier_{guid}_name"
        rendObj = ROBJ_TEXT
        text = getObjectName(soldier)
      }.__update(nameTxtStyle, mkSoldierAnim(0.5))
      levelBlock({
        guid
        tier
        thresholdColor
        curLevel = perksCount
        leftLevel = max(perksLevel - perksCount, 0)
        lockedLevel = max(maxLevel - perksLevel, 0)
        hasLeftLevelBlink = true
        isFreemiumMode = thresholdColor != null
        fontSize = hdpx(24)
      }).__update({ key = $"soldier_{guid}_level" }, mkSoldierAnim(0.6))
    ]
  }
}


return {
  SQUAD_COLOR_SCHEME_ID
  RESERVE_COLOR_SCHEME_ID
  LOCKED_COLOR_SCHEME_ID
  mkSoldierBadge
  mkEmptySoldierBadge
  mkSoldierPresentation
  soldierCardSize
}
