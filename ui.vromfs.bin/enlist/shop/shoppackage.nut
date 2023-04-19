from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let faComp = require("%ui/components/faComp.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontXSmall, fontMedium, fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, titleTxtColor, panelBgColor, midPadding, discountBgColor, darkTxtColor,
  colFull, colPart, columnGap, leftAppearanceAnim, defItemBlur, defSlotBgColor, hoverSlotBgColor,
  attentionTxtColor, accentColor, smallPadding
} = require("%enlSqGlob/ui/designConst.nut")
let { mkShopItemPrice } = require("shopPricePackage.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let { getClassCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")


let itemIconSize = colPart(0.5)
let groupSlotSize = [flex(), colPart(2)]
let lowerSlotSize = [colFull(5), colFull(3.6)]
let baseSlotSize = [colFull(5), colFull(5)]
let promoSlotSize = [colFull(10), colFull(5)]


let pageTxtIdleStyle = { color = defTxtColor }.__update(fontXLarge)
let pageTxtHoverStyle = { color = titleTxtColor}.__update(fontXLarge)
let pageTxtActiveStyle = { color = darkTxtColor }.__update(fontXLarge)

let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let activeTxtStyle = { color = darkTxtColor }.__update(fontMedium)
let titleTxtStyle = { color = titleTxtColor }.__update(fontMedium)
let discountInfoStyle = { color = darkTxtColor }.__update(fontXLarge)
let discountDescStyle = { color = darkTxtColor }.__update(fontXSmall)
let alertTxtStyle = { color = titleTxtColor }.__update(fontXSmall)

let lockIcon = faComp("lock", { fontSize = hdpx(20), color = titleTxtColor })
let warnIcon = faComp("exclamation-triangle", { fontSize = hdpx(16), color = attentionTxtColor })


let bgColor = @(sf, isSelected) isSelected ? accentColor
  : sf & S_HOVER ? hoverSlotBgColor
  : defSlotBgColor


let selectedPageSlotLine = {
  rendObj = ROBJ_SOLID
  color = accentColor
}

let mkShopGroupPrefix = @(isSelected) {
  size = [smallPadding, flex()]
}.__update(isSelected ? selectedPageSlotLine : {})


let mkShopGroup = @(groupId, isSelected, onClick)
  watchElemState(@(sf) {
    rendObj = ROBJ_WORLD_BLUR
    color = defItemBlur
    fillColor = isSelected ? accentColor
      : sf & S_HOVER ? hoverSlotBgColor
      : panelBgColor
    size = groupSlotSize
    flow = FLOW_HORIZONTAL
    gap = columnGap
    valign = ALIGN_CENTER
    behavior = Behaviors.Button
    onClick
    children = [
      mkShopGroupPrefix(isSelected)
      {
        size = [flex(), SIZE_TO_CONTENT]
        rendObj = ROBJ_TEXTAREA
        behavior = Behaviors.TextArea
        text = utf8ToUpper(loc($"shopGroup/{groupId}"))
      }.__update(isSelected ? pageTxtActiveStyle
        : sf & S_HOVER ? pageTxtHoverStyle
        : pageTxtIdleStyle)
    ]
  })


let mkShopItemImg = @(img, sf, override = {}) (img ?? "") == "" ? null
  : {
      size = flex()
      rendObj = ROBJ_IMAGE
      image = Picture(img)
      imageHalign = ALIGN_CENTER
      imageValign = ALIGN_TOP
      keepAspect = KEEP_ASPECT_FILL
      transform = { scale = sf & S_HOVER ? [1.1, 1.1] : [1, 1] }
      transitions = [{ prop = AnimProp.scale, duration = 0.3, easing = InOutCubic }]
    }.__update(override)


let discountRightTail = {
  size = [midPadding, flex()]
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = discountBgColor
  commands = [
    [VECTOR_COLOR, discountBgColor],
    [VECTOR_POLY, 0, 0, 100, 100, 0, 100]
  ]
}

let discountLeftTail = {
  size = [midPadding, flex()]
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = discountBgColor
  commands = [
    [VECTOR_COLOR, discountBgColor],
    [VECTOR_POLY, 100, 0, 100, 100, 0, 100]
  ]
}


let mkDiscountBar = @(children, isTailOnLeft = false) {
  flow = FLOW_HORIZONTAL
  children = [
    isTailOnLeft ? discountLeftTail : null
    {
      flow = FLOW_HORIZONTAL
      gap = midPadding
      padding = [0, midPadding]
      valign = ALIGN_CENTER
      rendObj = ROBJ_VECTOR_CANVAS
      fillColor = discountBgColor
      commands = [
        [VECTOR_COLOR, discountBgColor],
        [VECTOR_POLY, 0,0, 100,0, 100, 100, 0, 100]
      ]
      children
    }
    isTailOnLeft ? null : discountRightTail
  ]
}


let function mkDiscount(sItem) {
  let discount = sItem?.discountInPercent ?? 0
  if (discount <= 0)
    return null

  let { hideDiscount = false, showSpecialOfferText = false } = sItem
  return mkDiscountBar([
      hideDiscount ? null : {
        rendObj = ROBJ_TEXT
        text = $"-{discount}%"
      }.__update(discountInfoStyle)
      {
        rendObj = ROBJ_TEXT
        text = loc(showSpecialOfferText ? "specialOfferShort" : "shop/discountTxt")
      }.__update(discountDescStyle)
    ])
}

let mkSpecOfferInfo = @(discount, endTime) mkDiscountBar([
  {
    rendObj = ROBJ_TEXT
    text = $"-{discount}%"
  }.__update(discountInfoStyle)
  {
    rendObj = ROBJ_TEXT
    text = loc("shop/discountTxt")
  }.__update(discountDescStyle)
  mkCountdownTimer({ timestamp = endTime, color = darkTxtColor })
])

let function mkTimeAvailable(showIntervalTs) {
  let endTime = showIntervalTs?[1] ?? 0
  return endTime < serverTime.value ? null
    : mkCountdownTimer({ timestamp = endTime, color = attentionTxtColor })
}


let mkShopItemName = @(nameLocId, sf, icon, showIntervalTs) {
  size = [flex(), colPart(1.4)]
  rendObj = ROBJ_WORLD_BLUR
  fillColor = bgColor(sf, false)
  color = defItemBlur
  flow = FLOW_HORIZONTAL
  gap = columnGap
  padding = columnGap
  valign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    icon
    {
      size = [flex(), SIZE_TO_CONTENT]
      maxWidth = pw(75)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = utf8ToUpper(loc(nameLocId).split("\r\n")[0])
    }.__update(sf & S_HOVER ? activeTxtStyle : defTxtStyle)
    mkTimeAvailable(showIntervalTs)
  ]
}


let function mkShopItemInfo(sItem, offer, sf, icon, lockObject) {
  let { nameLocId = "", showIntervalTs = [] } = sItem
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    vplace = ALIGN_BOTTOM
    children = [
      offer == null
        ? mkDiscount(sItem)
        : mkSpecOfferInfo(offer.discountInPercent, offer.endTime)
      mkShopItemPrice(sItem, lockObject)
      mkShopItemName(nameLocId, sf, icon, showIntervalTs)
    ]
  }
}


let mkFeaturedName = @(nameLocId, sf, icon) {
  size = [pw(50), colPart(1.4)]
  flow = FLOW_HORIZONTAL
  gap = columnGap
  padding = columnGap
  valign = ALIGN_CENTER
  vplace = ALIGN_CENTER
  children = [
    icon
    {
      size = [flex(), SIZE_TO_CONTENT]
      maxWidth = pw(75)
      rendObj = ROBJ_TEXTAREA
      behavior = Behaviors.TextArea
      text = utf8ToUpper(loc(nameLocId).split("\r\n")[0])
    }.__update(sf & S_HOVER ? activeTxtStyle : defTxtStyle)
  ]
}


let function mkShopFeaturedInfo(sItem, offer, sf, icon, lockObject) {
  let { nameLocId = "", showIntervalTs = [] } = sItem
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    vplace = ALIGN_BOTTOM
    children = [
      offer == null
        ? mkDiscount(sItem)
        : mkSpecOfferInfo(offer.discountInPercent, offer.endTime)
      mkShopItemPrice(sItem, lockObject)
      {
        size = [flex(), SIZE_TO_CONTENT]
        valign = ALIGN_CENTER
        children = [
          mkFeaturedName(nameLocId, sf, icon)
          {
            margin = [0, columnGap]
            hplace = ALIGN_RIGHT
            children = mkTimeAvailable(showIntervalTs)
          }
        ]
      }
    ]
  }
}


let mkLockInfo = @(lockTxt) lockTxt == "" ? null
  : {
      flow = FLOW_HORIZONTAL
      gap = columnGap
      valign = ALIGN_CENTER
      children = [
        lockIcon
        {
          rendObj = ROBJ_TEXT
          text = utf8ToUpper(lockTxt)
        }.__update(titleTxtStyle)
      ]
    }.__update(titleTxtStyle)


let function extractItems(content) {
  let res = {}
  foreach (tmpl, _ in content?.items ?? {})
    res[trimUpgradeSuffix(tmpl)] <- true
  return res.keys()
}

let function extractClasses(content) {
  let res = {}
  foreach (sClass in content?.soldierClasses ?? {})
    res[getClassCfg(sClass).kind] <- true
  return res.keys()
}

let function mkShopIcon(armyId, content, templates) {
  let itemsList = extractItems(content) ?? []
  if (itemsList.len() == 1) {
    let { itemtype = null, itemsubtype = null } = templates?[armyId][itemsList[0]]
    return itemTypeIcon(itemtype, itemsubtype, {
      size = array(2, itemIconSize)
      color = titleTxtColor
    })
  }

  let sClasses = extractClasses(content) ?? []
  if (sClasses.len() == 1)
    return kindIcon(sClasses[0], itemIconSize, null, titleTxtColor)

  return null
}


let mkAlertObject = @(alertText) {
  flow = FLOW_HORIZONTAL
  margin = smallPadding
  gap = smallPadding
  children = [
    warnIcon
    {
      rendObj = ROBJ_TEXT
      text = alertText
    }.__update(alertTxtStyle)
  ]
}

let function mkShopItem(
  idx, armyId, sItem, offer, content, templates, lockTxt, onClick, onHover, slotSize, alertText
) {
  let picSaturate = lockTxt == "" ? 1 : 0.1
  let icon = mkShopIcon(armyId, content, templates)
  let alertObject = alertText == null ? null : mkAlertObject(alertText)
  return watchElemState(@(sf) {
    key = $"shopitem_{sItem.guid}"
    size = slotSize
    rendObj = ROBJ_SOLID
    color = panelBgColor
    clipChildren = true
    behavior = onClick == null ? null : Behaviors.Button
    onClick
    onHover
    children = {
      size = flex()
      children = [
        {
          size = flex()
          margin = [0,0,colPart(1.4),0]
          children = mkShopItemImg(sItem?.image, sf, { picSaturate })
        }
        mkShopItemInfo(sItem, offer, sf, icon, mkLockInfo(lockTxt))
        alertObject
      ]
    }
  }.__update(leftAppearanceAnim(idx * 0.05 + 0.1)))
}

let mkBaseShopItem = @(idx, armyId, sItem, offer, content, templates, lockTxt,
                       onClick, onHover, alertText = null)
  mkShopItem(idx, armyId, sItem, offer, content, templates, lockTxt,
    onClick, onHover, baseSlotSize, alertText)

let mkLowerShopItem = @(idx, armyId, sItem, offer, content, templates, lockTxt,
                        onClick, onHover, alertText = null)
  mkShopItem(idx, armyId, sItem, offer, content, templates, lockTxt,
    onClick, onHover, lowerSlotSize, alertText)


let function mkShopFeatured(armyId, sItem, offer, content, templates, lockTxt, onClick, onHover) {
  let picSaturate = lockTxt == "" ? 1 : 0.1
  let icon = mkShopIcon(armyId, content, templates)
  return watchElemState(@(sf) {
    key = $"featured_{sItem.guid}"
    size = promoSlotSize
    rendObj = ROBJ_SOLID
    color = panelBgColor
    clipChildren = true
    behavior = onClick == null ? null : Behaviors.Button
    onClick
    onHover
    children = {
      size = flex()
      children = [
        mkShopItemImg(sItem?.image, sf, { picSaturate })
        mkShopFeaturedInfo(sItem, offer, sf, icon, mkLockInfo(lockTxt))
      ]
    }
  }.__update(leftAppearanceAnim(0)))
}


return {
  mkShopGroup
  mkBaseShopItem
  mkLowerShopItem
  mkDiscountBar
  mkShopFeatured
  lowerSlotSize
}
