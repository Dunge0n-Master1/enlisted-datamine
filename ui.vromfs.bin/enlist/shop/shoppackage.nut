from "%enlSqGlob/ui_library.nut" import *

let serverTime = require("%enlSqGlob/userstats/serverTime.nut")
let faComp = require("%ui/components/faComp.nut")
let mkCountdownTimer = require("%enlSqGlob/ui/mkCountdownTimer.nut")
let mkGlare = require("%enlist/components/mkGlareAnim.nut")
let { utf8ToUpper } = require("%sqstd/string.nut")
let { fontXSmall, fontSmall, fontMedium, fontXLarge } = require("%enlSqGlob/ui/fontsStyle.nut")
let { defTxtColor, titleTxtColor, panelBgColor, midPadding, brightAccentColor, darkTxtColor,
  colFull, colPart, columnGap, leftAppearanceAnim, defItemBlur, defSlotBgColor, hoverSlotBgColor,
  attentionTxtColor, accentColor, smallPadding, highlightLineBottom
} = require("%enlSqGlob/ui/designConst.nut")
let { mkShopItemPrice } = require("shopPricePackage.nut")
let { trimUpgradeSuffix } = require("%enlSqGlob/ui/itemsInfo.nut")
let { itemTypeIcon } = require("%enlist/soldiers/components/itemTypesData.nut")
let { getClassCfg } = require("%enlSqGlob/ui/soldierClasses.nut")
let { kindIcon } = require("%enlSqGlob/ui/soldiersUiComps.nut")
let { mkFireParticles, mkAshes, mkSparks } = require("%enlist/components/mkFireParticles.nut")
let { mkPremiumSquadXpImage } = require("%enlist/debriefing/components/mkXpImage.nut")


let itemIconSize = colPart(0.5)
let lowerSlotSize = [colFull(5), colFull(4.2)]
let baseSlotSize = [colFull(5), colFull(5)]
let promoSlotSize = [colFull(10), colFull(5)]
let btnSound = freeze({
  hover = "ui/enlist/button_highlight"
  click = "ui/enlist/button_click"
  active = "ui/enlist/button_action"
})


let defTxtStyle = { color = defTxtColor }.__update(fontMedium)
let activeTxtStyle = { color = darkTxtColor }.__update(fontMedium)
let titleTxtStyle = { color = titleTxtColor }.__update(fontMedium)
let discountInfoStyle = { color = darkTxtColor }.__update(fontXLarge)
let discountDescStyle = { color = darkTxtColor }.__update(fontXSmall)
let alertTxtStyle = { color = titleTxtColor }.__update(fontSmall)

let lockIcon = faComp("lock", { fontSize = hdpx(20), color = titleTxtColor })
let warnIcon = faComp("exclamation-triangle", { fontSize = hdpx(16), color = attentionTxtColor })

let infoBtnSize = hdpxi(30)
let hoveredInfoBtnSize = hdpxi(33)


let bgColor = @(sf, isSelected) isSelected ? accentColor
  : sf & S_HOVER ? hoverSlotBgColor
  : defSlotBgColor


let mkBgParticles = @(effectSize) {
  children = [
    mkFireParticles(8, effectSize, mkAshes)
    mkFireParticles(2, effectSize, mkSparks)
  ]
}


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


let mkDiscountRightTail = @(color) {
  size = [midPadding, flex()]
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = color
  commands = [
    [VECTOR_COLOR, color],
    [VECTOR_POLY, 0, 0, 100, 100, 0, 100]
  ]
}

let mkDiscountLeftTail = @(color) {
  size = [midPadding, flex()]
  rendObj = ROBJ_VECTOR_CANVAS
  fillColor = color
  commands = [
    [VECTOR_COLOR, color],
    [VECTOR_POLY, 100, 0, 100, 100, 0, 100]
  ]
}


let mkDiscountPolyCmds = @(color) [
  [VECTOR_COLOR, color],
  [VECTOR_POLY, 0,0, 100,0, 100, 100, 0, 100]
]

let mkDiscountBar = @(children, isTailOnLeft = true, color = brightAccentColor) {
  flow = FLOW_HORIZONTAL
  children = [
    isTailOnLeft ? mkDiscountLeftTail(color) : null
    {
      flow = FLOW_HORIZONTAL
      gap = midPadding
      padding = [0, midPadding]
      valign = ALIGN_CENTER
      rendObj = ROBJ_VECTOR_CANVAS
      fillColor = color
      commands = mkDiscountPolyCmds(color)
      children
    }
    isTailOnLeft ? null : mkDiscountRightTail(color)
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
      text = utf8ToUpper(loc(nameLocId))
    }.__update(sf & S_HOVER ? activeTxtStyle : defTxtStyle)
    mkTimeAvailable(showIntervalTs)
  ]
}


let function mkShopPremIcon(sItem) {
  let { squads = [] } = sItem
  let squad = squads?[0]
  if (squad == null)
    return null

  let { armyId } = squad
  return mkPremiumSquadXpImage(colPart(0.7), armyId)
}

let function mkShopItemInfo(sItem, offer, sf, icon, lockObject) {
  let { nameLocId = "", showIntervalTs = [], isPriceHidden = false, offerContainer = "" } = sItem
  let isContainer = offerContainer != ""
  return {
    size = [flex(), SIZE_TO_CONTENT]
    flow = FLOW_VERTICAL
    gap = midPadding
    vplace = ALIGN_BOTTOM
    children = [
      offer == null
        ? mkDiscount(sItem)
        : mkSpecOfferInfo(offer.discountInPercent, offer.endTime)
      isPriceHidden || isContainer ? null : {
        children = [
          mkShopItemPrice(sItem, lockObject)
          mkGlare({
            nestWidth = colPart(4)
            glareWidth = colPart(2)
            glareDuration = 0.7
            hasMask = true
          })
        ]
      }
      {
        size = [flex(), SIZE_TO_CONTENT]
        children = [
          mkShopItemName(nameLocId, sf, icon, showIntervalTs)
          highlightLineBottom
        ]
      }
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
    }.__update(sf & S_HOVER ? titleTxtStyle : defTxtStyle)
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
      {
        children = [
          mkShopItemPrice(sItem, lockObject)
          mkGlare({
            nestWidth = colPart(4)
            glareWidth = colPart(2)
            glareDuration = 0.7
            hasMask = true
          })
        ]
      }
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
  size = [flex(), SIZE_TO_CONTENT]
  flow = FLOW_HORIZONTAL
  margin = smallPadding
  gap = smallPadding
  children = [
    warnIcon
    {
      rendObj = ROBJ_TEXTAREA
      size = [flex(), SIZE_TO_CONTENT]
      text = alertText
      behavior = Behaviors.TextArea
      valign = ALIGN_BOTTOM
    }.__update(alertTxtStyle)
  ]
}

let infoIcon = {
  rendObj = ROBJ_IMAGE
  size = array(2, infoBtnSize)
  image = Picture($"ui/skin#info/info_icon.svg:{infoBtnSize}:{infoBtnSize}:K")
}

let infoIconHover = {
  rendObj = ROBJ_IMAGE
  size = array(2, hoveredInfoBtnSize)
  image = Picture($"ui/skin#info/info_icon.svg:{hoveredInfoBtnSize}:{hoveredInfoBtnSize}:K")
}

let mkInfoBtn = @(onClick) onClick == null ? null : watchElemState(function(sf) {
  return {
    size = [hoveredInfoBtnSize, hoveredInfoBtnSize]
    valign = ALIGN_CENTER
    halign = ALIGN_CENTER
    hplace = ALIGN_RIGHT
    margin = fsh(1)
    behavior = Behaviors.Button
    sound = btnSound
    onClick
    children = sf & S_HOVER ? infoIconHover : infoIcon
  }
})

let mkShopItem = @(slotSize) function(idx, armyId, sItem, offer, content, templates,
    lockTxt, onClick, onHover, alertText, infoCb) {
  let picSaturate = lockTxt == "" ? 1 : 0.1
  let icon = mkShopIcon(armyId, content, templates)
  let alertObject = alertText == null ? null : mkAlertObject(alertText)
  let xmbNode = onClick == null ? null : XmbNode()
  let behavior = onClick == null ? null : Behaviors.Button
  let sound = onClick == null ? null : btnSound
  return watchElemState(@(sf) {
    key = sItem.guid
    size = slotSize
    rendObj = ROBJ_SOLID
    color = panelBgColor
    clipChildren = true
    behavior
    xmbNode
    onClick
    sound
    hotkeys = (sf & S_HOVER) != 0 && infoCb != null
      ? [["^J:Y", { description = loc("info"), action = infoCb }]]
      : null
    onHover
    children = {
      size = flex()
      children = [
        {
          size = flex()
          margin = [0,0,colPart(1.4),0]
          children = [
            mkShopItemImg(sItem?.image, sf, { picSaturate })
            mkBgParticles([slotSize[0], slotSize[1] - colPart(1.4)])
          ]
        }
        mkShopItemInfo(sItem, offer, sf, icon, mkLockInfo(lockTxt))
        mkShopPremIcon(sItem)
        alertObject
        mkInfoBtn(infoCb)
      ]
    }
  }.__update(leftAppearanceAnim(idx * 0.05 + 0.1)))
}

let mkBaseShopItem = mkShopItem(baseSlotSize)
let mkLowerShopItem = mkShopItem(lowerSlotSize)

let function mkShopFeatured(armyId, sItem, offer, content, templates,
    lockTxt, onClick, onHover, infoCb) {
  let picSaturate = lockTxt == "" ? 1 : 0.1
  let icon = mkShopIcon(armyId, content, templates)
  let xmbNode = onClick == null ? null : XmbNode()
  let behavior = onClick == null ? null : Behaviors.Button
  let sound = onClick == null ? null : btnSound
  return watchElemState(@(sf) {
    key = $"featured_{sItem.guid}"
    size = promoSlotSize
    rendObj = ROBJ_SOLID
    color = panelBgColor
    clipChildren = true
    behavior
    xmbNode
    onClick
    sound
    onHover
    hotkeys = (sf & S_HOVER) != 0 && infoCb != null
      ? [["^J:Y", { description = loc("info"), action = infoCb }]]
      : null
    children = {
      size = flex()
      children = [
        mkShopItemImg(sItem?.image, sf, { picSaturate })
        mkBgParticles(promoSlotSize)
        mkShopFeaturedInfo(sItem, offer, sf, icon, mkLockInfo(lockTxt))
        infoCb ? mkInfoBtn(infoCb) : null
      ]
    }
  }.__update(leftAppearanceAnim(0)))
}


return {
  mkBaseShopItem
  mkLowerShopItem
  mkDiscountBar
  mkShopFeatured
  lowerSlotSize
  mkAlertObject
}
