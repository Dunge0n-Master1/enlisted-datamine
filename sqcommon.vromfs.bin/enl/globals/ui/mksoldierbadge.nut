from "%enlSqGlob/ui_library.nut" import *

let { colFull, colPart, columnGap, smallPadding, commonBorderRadius, deadTxtColor,
  reseveSlotBgColor, accentColor, panelBgColor, hoverTxtColor, titleTxtColor, miniPadding,
  defSlotBgColor, defItemBlur, hoverSlotBgColor, levelNestGradient, midPadding,
  rightAppearanceAnim, defLockedSlotBgColor, hoverLockedSlotBgColor, hoverLevelNestGradient
} = require("%enlSqGlob/ui/designConst.nut")
let faComp = require("%ui/components/faComp.nut")

let { fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { getObjectName } = require("%enlSqGlob/ui/itemsInfo.nut")
let {
  mkClassIcon, mkKindIcon, levelBlock, mkSoldierBadgePhoto, mkSoldierTier, mkClassName
} = require("soldiersComps.nut")


const SQUAD_COLOR_SCHEME_ID = "squad"
const RESERVE_COLOR_SCHEME_ID = "reserve"
const LOCKED_COLOR_SCHEME_ID = "locked"


let selectionLineHeight = colPart(0.06)
let levelInfoHeight = colPart(0.38)
let soldierCardSize = [colFull(2), colPart(1.21)]
let premClassSize = colPart(0.4)

let slotIconColor = 0xFF45545C
let slotIconHoverColor = 0xFF6A7B84


let soldierBgSchemes = {
  [SQUAD_COLOR_SCHEME_ID] = @(flags, isSelected) isSelected ? hoverSlotBgColor
    : flags & S_HOVER ? hoverSlotBgColor
    : defSlotBgColor,
  [RESERVE_COLOR_SCHEME_ID] = @(flags, isSelected) isSelected ? hoverSlotBgColor
    : flags & S_HOVER ? hoverSlotBgColor
    : reseveSlotBgColor,
  [LOCKED_COLOR_SCHEME_ID] = @(flags, isSelected)
    isSelected ? defLockedSlotBgColor
      : flags & S_HOVER ? hoverLockedSlotBgColor
      : defLockedSlotBgColor
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


let function mkSoldierInfo(soldier, sf, isSelected, isAlive = true, hasLockedSheme = false) {
  let { guid, armyId, tier, sKind, sClass, perksLevel, maxLevel,
    perksCount = 0, thresholdColor = null, sClassRare = null, isPremium = false,
    displayedKind = null
  } = soldier
  let needDarkTxt = !hasLockedSheme && (isSelected || (sf & S_HOVER) != 0)
  return {
    size = flex()
    flow = FLOW_VERTICAL
    children = [
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        gap = { size = flex() }
        padding = [miniPadding, midPadding]
        valign = ALIGN_CENTER
        children = [
          mkKindIcon(displayedKind ?? sKind, sClassRare, colPart(0.5), needDarkTxt || !isAlive
            ? deadTxtColor
            : null)
          isPremium ? null : mkClassIcon(armyId, sClass, {}, colPart(0.5))
        ]
      }
      {
        size = [flex(), levelInfoHeight]
        padding = miniPadding
        hplace = ALIGN_RIGHT
        halign = ALIGN_RIGHT
        valign = ALIGN_CENTER
        vplace = ALIGN_BOTTOM
        rendObj = ROBJ_IMAGE
        image = isSelected || (sf & S_HOVER) != 0 ? hoverLevelNestGradient : levelNestGradient
        children = levelBlock({
          guid
          tier
          thresholdColor
          isStarBlack = !isAlive
          curLevel = perksCount
          leftLevel = max(perksLevel - perksCount, 0)
          lockedLevel = max(maxLevel - perksLevel, 0)
          hasLeftLevelBlink = true
          isFreemiumMode = thresholdColor != null
        })
      }
    ]
  }
}


let function mkSoldierBadge(
  idx, soldier, isSelected, sf = 0, onClick = null, colorSchemeId = SQUAD_COLOR_SCHEME_ID
) {
  let { guid, armyId, sClass, photo, isPremium = false } = soldier
  let hasLockedSheme = colorSchemeId == LOCKED_COLOR_SCHEME_ID
  return {
    key = $"soldier_badge_{guid}_{idx}"
    size = soldierCardSize
    rendObj = ROBJ_MASK
    image = Picture("ui/uiskin/soldier_slot_mask.avif")
    behavior = onClick == null ? null : Behaviors.Button
    onClick
    children = [
      {
        size = flex()
        rendObj = ROBJ_WORLD_BLUR
        fillColor = soldierBgSchemes[colorSchemeId](sf, isSelected)
        color = defItemBlur
      }
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        children = [
          {
            size = [SIZE_TO_CONTENT, flex()]
            children = [
              mkSoldierBadgePhoto(photo)
              isPremium ? mkClassIcon(armyId, sClass, {}, premClassSize) : null
            ]
          }
          mkSoldierInfo(soldier, sf, isSelected, true, hasLockedSheme)
        ]
      }
      isSelected ? selectionLine : null
    ]
  }
}


let skullIcon = {
  rendObj = ROBJ_IMAGE
  image = Picture("ui/skin#skull_white.svg:{0}:{0}:K".subst(colPart(0.8)))
  color = deadTxtColor
  vplace = ALIGN_CENTER
  size = [colPart(0.8), colPart(0.8)]
}


let function mkSoldierRespawnBadge(idx, soldier, isSelected, sf = 0
){
  let { guid, armyId, sClass, photo, isPremium = false, isAlive = true } = soldier
  let colorSchemeId = isAlive ? SQUAD_COLOR_SCHEME_ID : LOCKED_COLOR_SCHEME_ID
  return {
    key = $"soldier_badge_{guid}_{idx}"
    size = soldierCardSize
    rendObj = ROBJ_MASK
    image = Picture("ui/uiskin/soldier_slot_mask.avif")
    children = [
      {
        size = flex()
        rendObj = ROBJ_WORLD_BLUR
        fillColor = soldierBgSchemes[colorSchemeId](sf, isSelected)
        color = defItemBlur
      }
      {
        size = flex()
        flow = FLOW_HORIZONTAL
        children = [
          {
            size = [SIZE_TO_CONTENT, flex()]
            children = [
              isAlive ? mkSoldierBadgePhoto(photo) : skullIcon
              isPremium ? mkClassIcon(armyId, sClass, {}, premClassSize) : null
            ]
          }
          mkSoldierInfo(soldier, sf, isSelected, isAlive)
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
      }.__update(rightAppearanceAnim(0.3))
      {
        key = $"soldier_{guid}_class"
        flow = FLOW_HORIZONTAL
        gap = columnGap
        children = [
          mkClassName(sClass, sKind, sClassRare)
          mkSoldierTier(tier)
        ]
      }.__update(rightAppearanceAnim(0.4))
      {
        key = $"soldier_{guid}_name"
        rendObj = ROBJ_TEXT
        text = getObjectName(soldier)
      }.__update(nameTxtStyle, rightAppearanceAnim(0.5))
      levelBlock({
        guid
        tier
        thresholdColor
        curLevel = perksCount
        leftLevel = max(perksLevel - perksCount, 0)
        lockedLevel = max(maxLevel - perksLevel, 0)
        hasLeftLevelBlink = true
        isFreemiumMode = thresholdColor != null
        fontSize = hdpx(0.38)
      }).__update({ key = $"soldier_{guid}_level" }, rightAppearanceAnim(0.6))
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
  selectionLine
  selectionLineHeight
  mkSoldierRespawnBadge
  levelInfoHeight
  soldierBgSchemes
}
